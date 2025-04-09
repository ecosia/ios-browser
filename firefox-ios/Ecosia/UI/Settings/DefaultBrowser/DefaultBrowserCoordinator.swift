// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Lottie
import Common

public struct DefaultBrowserCoordinator {
    let navigationController: UINavigationController
    let style: InstructionStepsViewStyle
    let customTopContentViewBackground: Color

    public init(navigationController: UINavigationController,
                style: InstructionStepsViewStyle,
                customTopContentViewBackground: Color) {
        self.navigationController = navigationController
        self.style = style
        self.customTopContentViewBackground = customTopContentViewBackground
    }

    public func showDetailView() {
        let steps = [
            InstructionStep(text: LocalizedStringKey(String.Key.defaultBrowserCardDetailInstructionStep1.rawValue)),
            InstructionStep(text: LocalizedStringKey(String.Key.defaultBrowserCardDetailInstructionStep2.rawValue)),
            InstructionStep(text: LocalizedStringKey(String.Key.defaultBrowserCardDetailInstructionStep3.rawValue))
        ]

        let view = NavigationView {
            InstructionStepsView(
                title: LocalizedStringKey(String.Key.defaultBrowserCardDetailTitle.rawValue),
                steps: steps,
                buttonTitle: LocalizedStringKey(String.Key.defaultBrowserCardDetailButton.rawValue),
                onButtonTap: {
                    Analytics.shared.defaultBrowserSettingsViaNudgeCard()
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
                },
                style: style
            ) {
                LottieView {
                    try await DotLottieFile.named("default_browser_setup_animation", bundle: .ecosia)
                }
                .configuration(LottieConfiguration(renderingEngine: .mainThread))
                .playing()
                .offset(y: 16)
                .aspectRatio(contentMode: .fit)
                .background(customTopContentViewBackground)
                .accessibilityHidden(true)
            }
            .onDisappear {
                Analytics.shared.defaultBrowserSettingsViaNudgeCardDetailDismiss()
            }
        }
            .navigationTitle(String.Key.defaultBrowserSettingTitle.rawValue)

        let hostingController = UIHostingController(rootView: view)
        hostingController.navigationItem.largeTitleDisplayMode = .never
        let doneHandler = DetailViewDoneHandler {
            self.navigationController.popViewController(animated: true)
        }
        objc_setAssociatedObject(hostingController, "detailViewDoneHandler", doneHandler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        hostingController.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: doneHandler,
            action: #selector(DetailViewDoneHandler.handleDone)
        )
        navigationController.pushViewController(hostingController, animated: true)
    }
}

extension DefaultBrowserCoordinator {
    
    public static func makeDefaultCoordinatorAndShowDetailViewFrom(_ navigationController: UINavigationController?,
                                                            topViewContentBackground: Color,
                                                            with theme: Theme) {
        
        guard let navigationController = navigationController else { return }
        
        let style = InstructionStepsViewStyle(
            backgroundPrimaryColor: Color(theme.colors.ecosia.backgroundSecondary),
            stepsBackgroundColor: Color(theme.colors.ecosia.backgroundPrimary),
            textPrimaryColor: Color(theme.colors.ecosia.textPrimary),
            textSecondaryColor: Color(theme.colors.ecosia.textSecondary),
            buttonBackgroundColor: Color(theme.colors.ecosia.buttonBackgroundPrimaryActive),
            buttonTextColor: Color(theme.colors.ecosia.textInversePrimary),
            stepRowStyle: StepRowStyle(
                stepNumberColor: Color(theme.colors.ecosia.textPrimary),
                stepNumberBackgroundColor: Color(theme.colors.ecosia.backgroundSecondary),
                stepTextColor: Color(theme.colors.ecosia.textPrimary)
            )
        )

        let coordinator = DefaultBrowserCoordinator(navigationController: navigationController,
                                                    style: style,
                                                    customTopContentViewBackground: topViewContentBackground)
        coordinator.showDetailView()
    }
}

final class DetailViewDoneHandler: NSObject {
    let onDone: () -> Void
    init(onDone: @escaping () -> Void) {
        self.onDone = onDone
    }

    @objc func handleDone() {
        onDone()
    }
}
