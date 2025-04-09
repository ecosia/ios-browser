// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Lottie

private struct InstructionStepsViewLayout {
    static let screenPadding: CGFloat = 24
    static let spacingBetweenSections: CGFloat = 24
    static let spacingBetweenTextStepss: CGFloat = 12
    static let stepNumberSpacing: CGFloat = 12
    static let stepNumberWidthHeight: CGFloat = 24
    static let buttonCornerRadius: CGFloat = 22
    static let stepsContainerCornerRadius: CGFloat = 10
    static let stepsContainerPadding: CGFloat = 16
    static let wavesHeight: CGFloat = 11
}

public struct InstructionStepsViewStyle {
    let backgroundPrimaryColor: Color
    let stepsBackgroundColor: Color
    let textPrimaryColor: Color
    let textSecondaryColor: Color
    let buttonBackgroundColor: Color
    let buttonTextColor: Color
    let stepRowStyle: StepRowStyle

    public init(backgroundPrimaryColor: Color,
                stepsBackgroundColor: Color,
                textPrimaryColor: Color,
                textSecondaryColor: Color,
                buttonBackgroundColor: Color,
                buttonTextColor: Color,
                stepRowStyle: StepRowStyle) {
        self.backgroundPrimaryColor = backgroundPrimaryColor
        self.stepsBackgroundColor = stepsBackgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.textSecondaryColor = textSecondaryColor
        self.buttonBackgroundColor = buttonBackgroundColor
        self.buttonTextColor = buttonTextColor
        self.stepRowStyle = stepRowStyle
    }
}

/// A reusable instruction screen with a title, steps, and a CTA button.
struct InstructionStepsView<TopContentView: View>: View {
    let title: LocalizedStringKey
    let topContentView: TopContentView
    let steps: [InstructionStep]
    let buttonTitle: LocalizedStringKey
    let onButtonTap: () -> Void
    let style: InstructionStepsViewStyle

    init(title: LocalizedStringKey,
         steps: [InstructionStep],
         buttonTitle: LocalizedStringKey,
         onButtonTap: @escaping () -> Void,
         style: InstructionStepsViewStyle,
         @ViewBuilder topContentView: () -> TopContentView) {
        self.title = title
        self.steps = steps
        self.buttonTitle = buttonTitle
        self.onButtonTap = onButtonTap
        self.style = style
        self.topContentView = topContentView()
    }

    var body: some View {
        ZStack {
            style.backgroundPrimaryColor
                .ignoresSafeArea()
            VStack(spacing: InstructionStepsViewLayout.spacingBetweenSections) {
                ZStack(alignment: .bottom) {
                    topContentView
                    Image("wave-forms-horizontal-1", bundle: .ecosia)
                        .resizable()
                        .renderingMode(.template)
                        .frame(height: InstructionStepsViewLayout.wavesHeight)
                        .foregroundStyle(style.backgroundPrimaryColor)
                        .accessibilityHidden(true)
                }

                VStack(spacing: InstructionStepsViewLayout.spacingBetweenSections) {
                    VStack(alignment: .leading,
                           spacing: InstructionStepsViewLayout.spacingBetweenTextStepss) {
                        Text(title)
                            .font(.title2.bold())
                            .foregroundColor(style.textPrimaryColor)
                            .accessibilityIdentifier("instruction_title")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading,
                               spacing: InstructionStepsViewLayout.spacingBetweenTextStepss) {
                            renderedSteps
                        }
                    }
                           .frame(maxWidth: .infinity)
                           .padding(InstructionStepsViewLayout.stepsContainerPadding)
                           .background(style.stepsBackgroundColor)
                           .cornerRadius(InstructionStepsViewLayout.stepsContainerCornerRadius)

                    Button(action: onButtonTap) {
                        Text(buttonTitle)
                            .font(.body)
                            .foregroundColor(style.buttonTextColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(style.buttonBackgroundColor)
                    }
                    .cornerRadius(InstructionStepsViewLayout.buttonCornerRadius)
                    .accessibilityIdentifier("instruction_cta_button")
                    .accessibilityLabel(Text(buttonTitle))
                }
                .padding([.bottom, .leading, .trailing], InstructionStepsViewLayout.screenPadding)
            }
        }
    }

    private var renderedSteps: some View {
        ForEach(Array(steps.enumerated()), id: \.offset) { pair in
            let index = pair.offset
            let step = pair.element
            StepRow(index: index, step: step, style: style.stepRowStyle)
        }
    }
}

public struct StepRowStyle {
    let stepNumberColor: Color
    let stepNumberBackgroundColor: Color
    let stepTextColor: Color

    public init(stepNumberColor: Color,
                stepNumberBackgroundColor: Color = .clear,
                stepTextColor: Color) {
        self.stepNumberColor = stepNumberColor
        self.stepNumberBackgroundColor = stepNumberBackgroundColor
        self.stepTextColor = stepTextColor
    }
}

private struct StepRow: View {
    let index: Int
    let step: InstructionStep
    let style: StepRowStyle

    var body: some View {
        HStack(alignment: .center,
               spacing: InstructionStepsViewLayout.stepNumberSpacing) {
            Text("\(index + 1)")
                .font(.subheadline.bold())
                .foregroundColor(style.stepNumberColor)
                .frame(width: InstructionStepsViewLayout.stepNumberWidthHeight,
                       height: InstructionStepsViewLayout.stepNumberWidthHeight)
                .background(style.stepNumberBackgroundColor)
                .clipShape(Circle())
                .accessibilityIdentifier("instruction_step_number")

            Text(step.text)
                .font(.subheadline)
                .foregroundColor(style.stepTextColor)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier("instruction_step_\(index + 1)_text")
        }
    }
}

/// A single instruction step with its text.
struct InstructionStep {
    let text: LocalizedStringKey
}

// MARK: - Preview

#Preview {
    InstructionStepsView(
        title: "Set Ecosia as default",
        steps: [
            InstructionStep(text: "Open **Settings**"),
            InstructionStep(text: "Select **Default Browser App**"),
            InstructionStep(text: "Choose **Ecosia**")
        ],
        buttonTitle: "Make default in settings",
        onButtonTap: {},
        style: InstructionStepsViewStyle(
            backgroundPrimaryColor: .tertiaryBackground,
            stepsBackgroundColor: .primaryBackground,
            textPrimaryColor: .primaryText,
            textSecondaryColor: .primaryText,
            buttonBackgroundColor: .primaryBrand,
            buttonTextColor: .primaryBackground,
            stepRowStyle: StepRowStyle(stepNumberColor: .primary,
                                       stepNumberBackgroundColor: .secondary,
                                       stepTextColor: .primaryText)
        )
    ) {
        LottieView { try await DotLottieFile.named("default_browser_setup_animation", bundle: .ecosia)
        }
        .configuration(LottieConfiguration(renderingEngine: .mainThread))
        .playing()
        .offset(y: 16)
        .aspectRatio(contentMode: .fit)
        .background(Color(UIColor(rgb: 0x275243)))
    }
}
