// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// This class contains all of Ecosia official primitive color tokens referenced in the link below.
// https://www.figma.com/design/8T2rTBVwynJKSdY6MQo5PQ/%E2%9A%9B%EF%B8%8F--Foundations?node-id=1239-9385&t=UKHtrxcc9UtOihsm-4
// You should never call those colors directly, they should only be called from a theme within the theme manager.
// This is the equivalent to Firefox's `FXColors`.
public struct EcosiaColor {
    // MARK: - Black & White
    public static let Black = UIColor(rgb: 0x000000)
    public static let White = UIColor(rgb: 0xFFFFFF)

    // MARK: - Neutral
    public static let Gray10 = UIColor(rgb: 0xF8F8F6)
    public static let Gray20 = UIColor(rgb: 0xF0F0EB)
    public static let Gray30 = UIColor(rgb: 0xDEDED9)
    public static let Gray40 = UIColor(rgb: 0xBEBEB9)
    public static let Gray50 = UIColor(rgb: 0x6C6C6C)
    public static let Gray60 = UIColor(rgb: 0x4C4C4C)
    public static let Gray70 = UIColor(rgb: 0x333333)
    public static let Gray80 = UIColor(rgb: 0x252525)
    public static let Gray90 = UIColor(rgb: 0x1A1A1A)

    // MARK: - Grellow
    public static let Grellow50  = UIColor(rgb: 0xE9F8A2)
    public static let Grellow100 = UIColor(rgb: 0xD7EB80)
    public static let Grellow200 = UIColor(rgb: 0xBBCF65)
    public static let Grellow300 = UIColor(rgb: 0xA1B353)
    public static let Grellow400 = UIColor(rgb: 0x889745)
    public static let Grellow500 = UIColor(rgb: 0x6F7D38)
    public static let Grellow600 = UIColor(rgb: 0x58632B)
    public static let Grellow700 = UIColor(rgb: 0x424A1E)
    public static let Grellow800 = UIColor(rgb: 0x2D3315)
    public static let Grellow900 = UIColor(rgb: 0x1B1D0F)

    // MARK: - Green
    public static let Green10 = UIColor(rgb: 0xCFF2D0)
    public static let Green20 = UIColor(rgb: 0xAFE9B0)
    public static let Green30 = UIColor(rgb: 0x5DD25E)
    public static let Green50 = UIColor(rgb: 0x008009)
    public static let Green60 = UIColor(rgb: 0x007508)
    public static let Green70 = UIColor(rgb: 0x006600)
    public static let Green80 = UIColor(rgb: 0x003C03)

    // MARK: - Dark Green
    public static let DarkGreen30  = UIColor(rgb: 0x668A7A)
    public static let DarkGreen50  = UIColor(rgb: 0x275243)
    public static let DarkGreen70  = UIColor(rgb: 0x09281D)
    public static let DarkGreen800 = UIColor(rgb: 0x18362B) // Used as Background/Accent/dark-green; not a standard palette step

    // MARK: - Light Green
    public static let LightGreen50  = UIColor(rgb: 0xE1F9B0)
    public static let LightGreen100 = UIColor(rgb: 0xC3F16E)
    public static let LightGreen200 = UIColor(rgb: 0xA4D24F)
    public static let LightGreen300 = UIColor(rgb: 0x8EB842)
    public static let LightGreen400 = UIColor(rgb: 0x789C36)
    public static let LightGreen500 = UIColor(rgb: 0x62802B)
    public static let LightGreen600 = UIColor(rgb: 0x4D6620)
    public static let LightGreen700 = UIColor(rgb: 0x3A4D16)
    public static let LightGreen800 = UIColor(rgb: 0x283410)
    public static let LightGreen900 = UIColor(rgb: 0x181D0C)

    // MARK: - Red
    public static let Red50  = UIColor(rgb: 0xFBEDEC)
    public static let Red100 = UIColor(rgb: 0xFBDBD9)
    public static let Red200 = UIColor(rgb: 0xFCB3AF)
    public static let Red300 = UIColor(rgb: 0xFD8786)
    public static let Red400 = UIColor(rgb: 0xFD4256)
    public static let Red500 = UIColor(rgb: 0xE71140)
    public static let Red600 = UIColor(rgb: 0xB90A32)
    public static let Red700 = UIColor(rgb: 0x8E0624)
    public static let Red800 = UIColor(rgb: 0x630717)
    public static let Red900 = UIColor(rgb: 0x3B0708)

    // MARK: - Claret
    public static let Claret50  = UIColor(rgb: 0xF6EFF0)
    public static let Claret100 = UIColor(rgb: 0xEFDEE1)
    public static let Claret200 = UIColor(rgb: 0xE3BCC3)
    public static let Claret300 = UIColor(rgb: 0xD89AA6)
    public static let Claret400 = UIColor(rgb: 0xCC768A)
    public static let Claret500 = UIColor(rgb: 0xB35A70)
    public static let Claret600 = UIColor(rgb: 0x8F4759)
    public static let Claret700 = UIColor(rgb: 0x632F3C)
    public static let Claret800 = UIColor(rgb: 0x4C232D)
    public static let Claret900 = UIColor(rgb: 0x2C141A)

    // MARK: - Peach
    public static let Peach50  = UIColor(rgb: 0xFCEEE7)
    public static let Peach100 = UIColor(rgb: 0xFCDBCC)
    public static let Peach200 = UIColor(rgb: 0xFFAF87)
    public static let Peach300 = UIColor(rgb: 0xF98D56)
    public static let Peach400 = UIColor(rgb: 0xE36C2F)
    public static let Peach500 = UIColor(rgb: 0xC25419)
    public static let Peach600 = UIColor(rgb: 0x9E400D)
    public static let Peach700 = UIColor(rgb: 0x77300A)
    public static let Peach800 = UIColor(rgb: 0x541F01)
    public static let Peach900 = UIColor(rgb: 0x2D1504)

    // MARK: - Yellow
    public static let Yellow50  = UIColor(rgb: 0xFAEFDC)
    public static let Yellow100 = UIColor(rgb: 0xF8DEB0)
    public static let Yellow200 = UIColor(rgb: 0xF8C856)
    public static let Yellow300 = UIColor(rgb: 0xD0A435)
    public static let Yellow400 = UIColor(rgb: 0xB08A2B)
    public static let Yellow500 = UIColor(rgb: 0x917222)
    public static let Yellow600 = UIColor(rgb: 0x745A19)
    public static let Yellow700 = UIColor(rgb: 0x574310)
    public static let Yellow800 = UIColor(rgb: 0x3C2E0D)
    public static let Yellow900 = UIColor(rgb: 0x211A0A)

    // MARK: - Blue
    public static let Blue50  = UIColor(rgb: 0xE6F3FC)
    public static let Blue100 = UIColor(rgb: 0xC9E7FB)
    public static let Blue200 = UIColor(rgb: 0x83D1FD)
    public static let Blue300 = UIColor(rgb: 0x49B8ED)
    public static let Blue400 = UIColor(rgb: 0x0094C7)
    public static let Blue500 = UIColor(rgb: 0x0081AF)
    public static let Blue600 = UIColor(rgb: 0x00678B)
    public static let Blue700 = UIColor(rgb: 0x004D64)
    public static let Blue800 = UIColor(rgb: 0x03354A)
    public static let Blue900 = UIColor(rgb: 0x051E2B)
}
