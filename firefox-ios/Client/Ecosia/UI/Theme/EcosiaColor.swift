// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// This class contains all of Ecosia official primitive color tokens referenced in the link below.
// https://www.figma.com/design/8T2rTBVwynJKSdY6MQo5PQ/%E2%9A%9B%EF%B8%8F--Foundations?node-id=1239-9385&t=UKHtrxcc9UtOihsm-4
// You should never call those colors directly, they should only be called from a theme within the theme manager.
// This is the equivalent to Firefox's `FXColors`.
struct EcosiaColor {
    // MARK: - Black & White
    static let Black = UIColor(rgb: 0x000000)
    static let White = UIColor(rgb: 0xFFFFFF)

    // MARK: - Neutral
    static let Gray10 = UIColor(rgb: 0xF8F8F6)
    static let Gray20 = UIColor(rgb: 0xF0F0EB)
    static let Gray30 = UIColor(rgb: 0xDEDED9)
    static let Gray40 = UIColor(rgb: 0xBEBEB9)
    static let Gray50 = UIColor(rgb: 0x6C6C6C)
    static let Gray60 = UIColor(rgb: 0x4C4C4C)
    static let Gray70 = UIColor(rgb: 0x333333)
    static let Gray80 = UIColor(rgb: 0x252525)
    static let Gray90 = UIColor(rgb: 0x1A1A1A)

    // MARK: - Grellow
    static let Grellow50  = UIColor(rgb: 0xE9F8A2)
    static let Grellow100 = UIColor(rgb: 0xD7EB80)
    static let Grellow200 = UIColor(rgb: 0xBBCF65)
    static let Grellow300 = UIColor(rgb: 0xA1B353)
    static let Grellow400 = UIColor(rgb: 0x889745)
    static let Grellow500 = UIColor(rgb: 0x6F7D38)
    static let Grellow600 = UIColor(rgb: 0x58632B)
    static let Grellow700 = UIColor(rgb: 0x424A1E)
    static let Grellow800 = UIColor(rgb: 0x2D3315)
    static let Grellow900 = UIColor(rgb: 0x1B1D0F)

    // MARK: - Green
    static let Green10 = UIColor(rgb: 0xCFF2D0)
    static let Green20 = UIColor(rgb: 0xAFE9B0)
    static let Green30 = UIColor(rgb: 0x5DD25E)
    static let Green50 = UIColor(rgb: 0x008009)
    static let Green60 = UIColor(rgb: 0x007508)
    static let Green70 = UIColor(rgb: 0x006600)
    static let Green80 = UIColor(rgb: 0x003C03)

    // MARK: - Dark Green
    static let DarkGreen30  = UIColor(rgb: 0x668A7A)
    static let DarkGreen50  = UIColor(rgb: 0x275243)
    static let DarkGreen70  = UIColor(rgb: 0x09281D)
    static let DarkGreen800 = UIColor(rgb: 0x18362B) // Used as Background/Accent/dark-green; not a standard palette step

    // MARK: - Light Green
    static let LightGreen50  = UIColor(rgb: 0xE1F9B0)
    static let LightGreen100 = UIColor(rgb: 0xC3F16E)
    static let LightGreen200 = UIColor(rgb: 0xA4D24F)
    static let LightGreen300 = UIColor(rgb: 0x8EB842)
    static let LightGreen400 = UIColor(rgb: 0x789C36)
    static let LightGreen500 = UIColor(rgb: 0x62802B)
    static let LightGreen600 = UIColor(rgb: 0x4D6620)
    static let LightGreen700 = UIColor(rgb: 0x3A4D16)
    static let LightGreen800 = UIColor(rgb: 0x283410)
    static let LightGreen900 = UIColor(rgb: 0x181D0C)

    // MARK: - Red
    static let Red50  = UIColor(rgb: 0xFBEDEC)
    static let Red100 = UIColor(rgb: 0xFBDBD9)
    static let Red200 = UIColor(rgb: 0xFCB3AF)
    static let Red300 = UIColor(rgb: 0xFD8786)
    static let Red400 = UIColor(rgb: 0xFD4256)
    static let Red500 = UIColor(rgb: 0xE71140)
    static let Red600 = UIColor(rgb: 0xB90A32)
    static let Red700 = UIColor(rgb: 0x8E0624)
    static let Red800 = UIColor(rgb: 0x630717)
    static let Red900 = UIColor(rgb: 0x3B0708)

    // MARK: - Claret
    static let Claret50  = UIColor(rgb: 0xF6EFF0)
    static let Claret100 = UIColor(rgb: 0xEFDEE1)
    static let Claret200 = UIColor(rgb: 0xE3BCC3)
    static let Claret300 = UIColor(rgb: 0xD89AA6)
    static let Claret400 = UIColor(rgb: 0xCC768A)
    static let Claret500 = UIColor(rgb: 0xB35A70)
    static let Claret600 = UIColor(rgb: 0x8F4759)
    static let Claret700 = UIColor(rgb: 0x632F3C)
    static let Claret800 = UIColor(rgb: 0x4C232D)
    static let Claret900 = UIColor(rgb: 0x2C141A)

    // MARK: - Peach
    static let Peach50  = UIColor(rgb: 0xFCEEE7)
    static let Peach100 = UIColor(rgb: 0xFCDBCC)
    static let Peach200 = UIColor(rgb: 0xFFAF87)
    static let Peach300 = UIColor(rgb: 0xF98D56)
    static let Peach400 = UIColor(rgb: 0xE36C2F)
    static let Peach500 = UIColor(rgb: 0xC25419)
    static let Peach600 = UIColor(rgb: 0x9E400D)
    static let Peach700 = UIColor(rgb: 0x77300A)
    static let Peach800 = UIColor(rgb: 0x541F01)
    static let Peach900 = UIColor(rgb: 0x2D1504)

    // MARK: - Yellow
    static let Yellow50  = UIColor(rgb: 0xFAEFDC)
    static let Yellow100 = UIColor(rgb: 0xF8DEB0)
    static let Yellow200 = UIColor(rgb: 0xF8C856)
    static let Yellow300 = UIColor(rgb: 0xD0A435)
    static let Yellow400 = UIColor(rgb: 0xB08A2B)
    static let Yellow500 = UIColor(rgb: 0x917222)
    static let Yellow600 = UIColor(rgb: 0x745A19)
    static let Yellow700 = UIColor(rgb: 0x574310)
    static let Yellow800 = UIColor(rgb: 0x3C2E0D)
    static let Yellow900 = UIColor(rgb: 0x211A0A)

    // MARK: - Blue
    static let Blue50  = UIColor(rgb: 0xE6F3FC)
    static let Blue100 = UIColor(rgb: 0xC9E7FB)
    static let Blue200 = UIColor(rgb: 0x83D1FD)
    static let Blue300 = UIColor(rgb: 0x49B8ED)
    static let Blue400 = UIColor(rgb: 0x0094C7)
    static let Blue500 = UIColor(rgb: 0x0081AF)
    static let Blue600 = UIColor(rgb: 0x00678B)
    static let Blue700 = UIColor(rgb: 0x004D64)
    static let Blue800 = UIColor(rgb: 0x03354A)
    static let Blue900 = UIColor(rgb: 0x051E2B)
}
