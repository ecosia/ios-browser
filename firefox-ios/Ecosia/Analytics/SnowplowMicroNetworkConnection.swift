// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

internal import SnowplowTracker

// MARK: Internal constants from TrackerConstants
// https://github.com/snowplow/snowplow-ios-tracker/blob/e7aa3448ddbf7e6629ffbfb684b737bb19899992/Sources/Core/TrackerConstants.swift
private let kSPEndpointPost = "/com.snowplowanalytics.snowplow/tp2"
private let kSPAcceptContentHeader = "text/html, application/x-www-form-urlencoded, text/plain, image/gif"
private let kSPContentTypeHeader = "application/json; charset=utf-8"

// MARK: Custom connection
class SnowplowMicroNetworkConnection: NSObject, NetworkConnection {
    internal var urlEndpoint: URL? {
        guard let microUrl = Environment.current.urlProvider.snowplowMicro,
                let url = URL(string: microUrl) else {
            return nil
        }
        return url.appendingPathComponent(kSPEndpointPost)
    }
    private var dataOperationQueue = OperationQueue()
    private lazy var urlSession: URLSession = {
        let sessionConfig: URLSessionConfiguration = .default
        sessionConfig.timeoutIntervalForRequest = TimeInterval(EmitterDefaults.emitTimeout)
        sessionConfig.timeoutIntervalForResource = TimeInterval(EmitterDefaults.emitTimeout)

        let urlSession = URLSession(configuration: sessionConfig)
        return urlSession
    }()
    var httpMethod: HttpMethodOptions { .post }

    func sendRequests(_ requests: [Request]) -> [RequestResult] {
        guard let urlEndpoint = urlEndpoint else {
            return []
        }
        let urlRequests = requests.map { request in
            var request = Internals.buildPost(request, url: urlEndpoint)
            // Cloudflare Access headers
            if let auth = Environment.current.auth {
                request.setValue(auth.id, forHTTPHeaderField: CloudflareKeyProvider.clientId)
                request.setValue(auth.secret, forHTTPHeaderField: CloudflareKeyProvider.clientSecret)
            }
            return request
        }

        var results: [RequestResult] = []
        if requests.count == 1 {
            if let request = requests.first, let urlRequest = urlRequests.first {
                let result = Internals.makeRequest(
                    request: request,
                    urlRequest: urlRequest,
                    urlSession: urlSession
                )

                results.append(result)
            }
        }
        // if there are more than 1 request, use the operation queue
        else if requests.count > 1 {
            for (request, urlRequest) in zip(requests, urlRequests) {
                dataOperationQueue.addOperation({
                    let result = Internals.makeRequest(
                        request: request,
                        urlRequest: urlRequest,
                        urlSession: self.urlSession
                    )

                    objc_sync_enter(self)
                    results.append(result)
                    objc_sync_exit(self)
                })
            }
            dataOperationQueue.waitUntilAllOperationsAreFinished()
        }

        return results
    }
}

/// Based on SnowplowTracker's DefaultNetworkConnection
/// https://github.com/snowplow/snowplow-ios-tracker/blob/e7aa3448ddbf7e6629ffbfb684b737bb19899992/Sources/Snowplow/Network/DefaultNetworkConnection.swift
private class Internals {
    static func buildPost(_ request: Request, url: URL) -> URLRequest {
        var requestData: Data?
        do {
            requestData = try JSONSerialization.data(withJSONObject: request.payload?.dictionary ?? [:], options: [])
        } catch {
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("\(NSNumber(value: requestData?.count ?? 0).stringValue)", forHTTPHeaderField: "Content-Length")
        urlRequest.setValue(kSPAcceptContentHeader, forHTTPHeaderField: "Accept")
        urlRequest.setValue(kSPContentTypeHeader, forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        return urlRequest
    }

    static func urlEncode(_ dictionary: [String: Any]) -> String {
        return dictionary.map { (key: String, value: Any) in
            "\(self.urlEncode(key))=\(self.urlEncode(String(describing: value)))"
        }.joined(separator: "&")
    }

    static func urlEncode(_ string: String) -> String {
        var allowedCharSet = CharacterSet.urlQueryAllowed
        allowedCharSet.remove(charactersIn: "!*'\"();:@&=+$,/?%#[]% ")
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharSet) ?? string
    }

    static func makeRequest(request: Request, urlRequest: URLRequest, urlSession: URLSession?) -> RequestResult {
        var httpResponse: HTTPURLResponse?
        var connectionError: Error?
        let sem = DispatchSemaphore(value: 0)

        urlSession?.dataTask(with: urlRequest) { data, urlResponse, error in
            connectionError = error
            httpResponse = urlResponse as? HTTPURLResponse
            sem.signal()
        }.resume()

        _ = sem.wait(timeout: .distantFuture)
        var statusCode: NSNumber?
        if let httpResponse = httpResponse { statusCode = NSNumber(value: httpResponse.statusCode) }

        let result = RequestResult(statusCode: statusCode, oversize: request.oversize, storeIds: request.emitterEventIds)
        if !result.isSuccessful {
            logError(message: "Connection error: " + (connectionError?.localizedDescription ?? "-"))
        }

        return result
    }

    static func logError(message: String,
                         file: String = #file,
                         line: Int = #line,
                         function: String = #function) {
        print("[TEST] \(file):\(line) : \(function)", message)
    }
}
