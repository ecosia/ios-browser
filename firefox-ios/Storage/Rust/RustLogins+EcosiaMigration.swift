// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Ecosia: one-time migration of login records from application-services v133 to v147.
//
// We jumped directly from v133 to v147, skipping the gradual useRustKeychain Nimbus rollout
// (FXIOS-11415) that Firefox upstream used to migrate users between encryption architectures.
// In v133, login credentials were stored in a `secFields` column as JWE compact tokens
// (alg:dir, enc:A256GCM) with a JWK oct key held by MZKeychainWrapper. In v147, the Rust
// component manages encryption directly via the KeyManager protocol and no longer understands
// the old secFields format.
//
// This file provides the migration that should have happened upstream:
// - reads and decrypts secFields directly from SQLite using the legacy MZKeychainWrapper key
// - re-adds the extracted logins via the new v147 API after opening a fresh database
//
// Reference: application-services schema.rs v133 (user_version=2), encryption.rs v147 (KeyManager).

import CryptoKit
import Foundation
import struct MozillaAppServices.LoginEntry

// Ecosia: base64url → base64 conversion helper required by the JWE decryption below
private extension Data {
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        self.init(base64Encoded: base64)
    }
}

extension RustLogins {

    // Ecosia: UserDefaults key that gates the migration to run exactly once
    static let v133MigrationKey = "ecosia_v133_login_migration_complete"

    // Ecosia: extracts and decrypts all pre-v147 login records from the SQLite database before
    // LoginsStorage opens it. The schema version check is skipped intentionally — previous runs
    // of LoginsStorage may have already migrated user_version from 2 to 5 while leaving the
    // encrypted secFields blobs intact.
    func extractV133Logins() -> [LoginEntry] {
        guard !UserDefaults.standard.bool(forKey: Self.v133MigrationKey) else { return [] }

        var db: OpaquePointer?
        guard sqlite3_open_v2(perFieldDatabasePath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            UserDefaults.standard.set(true, forKey: Self.v133MigrationKey)
            return []
        }
        defer { sqlite3_close(db) }

        guard let keyData = rustKeychain.legacyDataForKey(rustKeychain.loginsKeyIdentifier),
              let keyString = String(data: keyData, encoding: .utf8) else {
            UserDefaults.standard.set(true, forKey: Self.v133MigrationKey)
            return []
        }

        let query = """
            SELECT origin, httpRealm, formActionOrigin, usernameField, passwordField, secFields
            FROM loginsL WHERE secFields != '' AND is_deleted = 0
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            UserDefaults.standard.set(true, forKey: Self.v133MigrationKey)
            return []
        }
        defer { sqlite3_finalize(stmt) }

        var entries: [LoginEntry] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            func col(_ i: Int32) -> String? {
                guard let ptr = sqlite3_column_text(stmt, i) else { return nil }
                return String(cString: ptr)
            }
            guard let secFields = col(5),
                  let decrypted = decryptJWEDirect(jwe: secFields, jwkString: keyString),
                  let data = decrypted.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let username = json["u"],
                  let password = json["p"],
                  !password.isEmpty else { continue }

            entries.append(LoginEntry(
                origin: col(0) ?? "",
                httpRealm: col(1),
                formActionOrigin: col(2),
                usernameField: col(3) ?? "",
                passwordField: col(4) ?? "",
                password: password,
                username: username
            ))
        }
        UserDefaults.standard.set(true, forKey: Self.v133MigrationKey)
        return entries
    }

    // Ecosia: re-adds logins extracted from the v133 database using the new v147 API
    func readdMigratedLogins(_ logins: [LoginEntry]) {
        for login in logins {
            getStoredKey { [weak self] result in
                guard case .success = result, let self = self else { return }
                _ = try? self.storage?.add(login: login)
            }
        }
    }

    // Ecosia: decrypts a v133 secFields JWE compact token (alg:dir, enc:A256GCM) using CryptoKit.
    // jwkString is the JWK oct key stored by MZKeychainWrapper: {"kty":"oct","k":"<base64url>"}.
    // AAD is the ASCII-encoded JWE Protected Header per RFC 7516.
    private func decryptJWEDirect(jwe: String, jwkString: String) -> String? {
        let parts = jwe.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 5,
              let jwkData = jwkString.data(using: .utf8),
              let jwk = try? JSONDecoder().decode([String: String].self, from: jwkData),
              let kBase64 = jwk["k"],
              let keyBytes = Data(base64URLEncoded: kBase64),
              keyBytes.count == 32,
              let iv = Data(base64URLEncoded: parts[2]),
              let ciphertext = Data(base64URLEncoded: parts[3]),
              let tag = Data(base64URLEncoded: parts[4]) else { return nil }

        do {
            let symmetricKey = SymmetricKey(data: keyBytes)
            let nonce = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            let plaintext = try AES.GCM.open(sealedBox, using: symmetricKey, authenticating: Data(parts[0].utf8))
            return String(data: plaintext, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
