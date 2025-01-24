// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// This file contains all of Ecosia official semantic color tokens referenced in the link below.
// https://www.figma.com/design/8T2rTBVwynJKSdY6MQo5PQ/%E2%9A%9B%EF%B8%8F--Foundations?node-id=2237-3418&t=UKHtrxcc9UtOihsm-0
// They should use `EcosiaColorPrimitives` and should be called from a theme within the theme manager.
extension UIColor {
    struct Light {
        struct Background {
            static let primary = EcosiaColorPrimitive.White
            static let secondary = EcosiaColorPrimitive.Gray10
            static let tertiary = EcosiaColorPrimitive.Gray20
            static let quarternary = EcosiaColorPrimitive.DarkGreen50
            static let highlighted = EcosiaColorPrimitive.Green10 // ⚠️ No match
        }

        struct Brand {
            static let primary = EcosiaColorPrimitive.Green50
        }

        struct Border {
            static let decorative = EcosiaColorPrimitive.Gray30
        }

        struct Button {
            static let backgroundPrimary = EcosiaColorPrimitive.Green50
            static let backgroundPrimaryActive = EcosiaColorPrimitive.Green70 // ⚠️ Mismatch
            static let backgroundSecondary = EcosiaColorPrimitive.White
            static let backgroundSecondaryHover = EcosiaColorPrimitive.Gray10 // ⚠️ Mismatch
            static let contentSecondary = EcosiaColorPrimitive.Gray70
            static let secondaryBackground = EcosiaColorPrimitive.Gray10 // ⚠️ Mismatch & duplicate
            static let backgroundTransparentActive = EcosiaColorPrimitive.Green70.withAlphaComponent(0.24)
        }

        struct Icon {
            static let primary = EcosiaColorPrimitive.Black // ⚠️ Mobile snowflake & mismatch
            static let secondary = EcosiaColorPrimitive.Green60 // ⚠️ Mobile snowflake & mismatch
            static let decorative = EcosiaColorPrimitive.Gray50 // ⚠️ Mobile snowflake
        }

        struct State {
            static let error = EcosiaColorPrimitive.Red40 // ⚠️ Mobile snowflake
            static let information = EcosiaColorPrimitive.Blue50 // ⚠️ No match
            static let disabled = EcosiaColorPrimitive.Gray30
        }

        struct Text {
            static let primary = EcosiaColorPrimitive.Black // ⚠️ Mismatch
            static let secondary = EcosiaColorPrimitive.Gray50
            static let tertiary = EcosiaColorPrimitive.White
        }
    }

    struct Dark {
        struct Background {
            static let primary = EcosiaColorPrimitive.Gray90
            static let secondary = EcosiaColorPrimitive.Gray80
            static let tertiary = EcosiaColorPrimitive.Gray70
            static let quarternary = EcosiaColorPrimitive.Green20
            static let highlighted = EcosiaColorPrimitive.DarkGreen30 // ⚠️ No match
        }

        struct Brand {
            static let primary = EcosiaColorPrimitive.Green30
        }

        struct Border {
            static let decorative = EcosiaColorPrimitive.Gray60
        }

        struct Button {
            static let backgroundPrimary = EcosiaColorPrimitive.Green30
            static let backgroundPrimaryActive = EcosiaColorPrimitive.Green50 // ⚠️ Mismatch
            static let backgroundSecondary = EcosiaColorPrimitive.Gray70 // ⚠️ Mismatch
            static let backgroundSecondaryHover = EcosiaColorPrimitive.Gray70
            static let contentSecondary = EcosiaColorPrimitive.White
            static let secondaryBackground = EcosiaColorPrimitive.Gray80 // ⚠️ Mismatch & duplicate
            static let backgroundTransparentActive = EcosiaColorPrimitive.Gray30.withAlphaComponent(0.32)
        }

        struct Icon {
            static let primary = EcosiaColorPrimitive.White // ⚠️ Mobile snowflake
            static let secondary = EcosiaColorPrimitive.Green30 // ⚠️ Mobile snowflake
            static let decorative = EcosiaColorPrimitive.Gray40 // ⚠️ Mobile snowflake & mismatch
        }

        struct State {
            static let error = EcosiaColorPrimitive.Red30 // ⚠️ Mobile snowflake
            static let information = EcosiaColorPrimitive.Blue30 // ⚠️ No match
            static let disabled = EcosiaColorPrimitive.Gray50
        }

        struct Text {
            static let primary = EcosiaColorPrimitive.White
            static let secondary = EcosiaColorPrimitive.Gray30
            static let tertiary = EcosiaColorPrimitive.Gray70 // ⚠️ Mismatch
        }
    }

    struct Grey {
        static let fifty = EcosiaColorPrimitive.Gray50
    }
}
