/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class WelcomeTour: UIViewController,  Themeable {

    final class Step {
        let title: String
        let text: String
        let image: String
        let content: UIViewController?

        init(title: String, text: String, image: String, content: UIViewController?) {
            self.title = title
            self.text = text
            self.image = image
            self.content = content
        }

        static var planet: Step {
            return .init(title: "A better planet with every search", text: "Search the web and plant trees with the fast, free, and full-featured Ecosia browser", image: "tour1", content: WelcomeTourPlanet())
        }

        static var profit: Step {
            return .init(title: "100% of profits for the planet", text: "All our profits go to climate action, including planting trees and generating solar energy.", image: "tour2", content: WelcomeTourPlanet())
        }

        static var action: Step {
            return .init(title: "100% of profits for the planet", text: "All our profits go to climate action, including planting trees and generating solar energy.", image: "tour3", content: WelcomeTourPlanet())
        }

        static var trees: Step {
            return .init(title: "100% of profits for the planet", text: "All our profits go to climate action, including planting trees and generating solar energy.", image: "tour4", content: WelcomeTourPlanet())
        }

        static var all: [Step] {
            return [planet, profit, action, trees]
        }
    }

    private weak var navStack: UIStackView!
    private weak var labelStack: UIStackView!
    private weak var titleLabel: UILabel!
    private weak var textLabel: UILabel!
    private weak var backButton: UIButton!
    private weak var skipButton: UIButton!
    private weak var pageControl: UIPageControl!
    private weak var ctaButton: UIButton!
    private weak var waves: UIImageView!
    private weak var container: UIView!
    private weak var imageView: UIImageView!

    // references to animated constraints
    private weak var labelLeft: NSLayoutConstraint!
    private weak var labelRight: NSLayoutConstraint!

    // model
    private var steps: [Step]!
    private var current: Step?

    override func viewDidLoad() {
        super.viewDidLoad()

        steps = Step.all

        addStaticViews()
        addDynamicViews()
        applyTheme()
    }

    private func addStaticViews() {
        let navStack = UIStackView()
        navStack.translatesAutoresizingMaskIntoConstraints = false
        navStack.axis = .horizontal
        navStack.distribution = .fillProportionally
        navStack.alignment = .center
        view.addSubview(navStack)
        self.navStack = navStack

        navStack.heightAnchor.constraint(equalToConstant: 44).isActive = true
        navStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        navStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        navStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true

        let backButton = UIButton.systemButton(with: .init(named: "backChevron")!, target: self, action: #selector(back))
        navStack.addArrangedSubview(backButton)
        backButton.widthAnchor.constraint(equalToConstant: 74).isActive = true
        navStack.addArrangedSubview(backButton)
        self.backButton = backButton

        let pageControl = UIPageControl()
        pageControl.numberOfPages = 4
        pageControl.currentPage = 0
        navStack.addArrangedSubview(pageControl)
        self.pageControl = pageControl

        let skipButton = UIButton(type: .system)
        skipButton.widthAnchor.constraint(equalToConstant: 74).isActive = true
        skipButton.addTarget(self, action: #selector(forward), for: .primaryActionTriggered)
        navStack.addArrangedSubview(skipButton)
        skipButton.setTitle("Skip", for: .normal)

        self.skipButton = skipButton

        let waves = UIImageView(image: .init(named: "onboardingWaves"))
        waves.translatesAutoresizingMaskIntoConstraints = false
        waves.setContentHuggingPriority(.required, for: .vertical)
        view.addSubview(waves)
        self.waves = waves

        waves.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        waves.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        let wavesBottom = waves.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 251)
        wavesBottom.priority = .defaultHigh
        wavesBottom.isActive = true
    }

    private func addDynamicViews() {
        let labelStack = UIStackView()
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        labelStack.axis = .vertical
        labelStack.distribution = .fill
        labelStack.alignment = .leading
        labelStack.spacing = 8
        labelStack.alpha = 0
        view.addSubview(labelStack)
        self.labelStack = labelStack

        let labelLeft = labelStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 64)
        labelLeft.priority = .init(rawValue: 999)
        labelLeft.isActive = true
        self.labelLeft = labelLeft

        let labelRight = labelStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 32)
        labelRight.priority = .init(rawValue: 999)
        labelRight.isActive = true
        self.labelRight = labelRight

        labelStack.topAnchor.constraint(equalTo: navStack.bottomAnchor, constant: 24).isActive = true
        labelStack.bottomAnchor.constraint(equalTo: waves.topAnchor).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = steps.first?.title
        titleLabel.numberOfLines = 0
        titleLabel.font = .preferredFont(forTextStyle: .title2).bold()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        labelStack.addArrangedSubview(titleLabel)
        self.titleLabel = titleLabel

        let textLabel = UILabel()
        textLabel.text = steps.first?.text
        textLabel.numberOfLines = 0
        textLabel.font = .preferredFont(forTextStyle: .body)
        textLabel.adjustsFontForContentSizeCategory = true
        labelStack.addArrangedSubview(textLabel)
        self.textLabel = textLabel

        let ctaButton = UIButton(type: .system)
        cta.setTitle("Continue", for: .normal)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.addTarget(self, action: #selector(forward), for: .primaryActionTriggered)
        ctaButton.alpha = 0
        view.addSubview(ctaButton)
        self.ctaButton = ctaButton

        ctaButton.layer.cornerRadius = 25
        ctaButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        ctaButton.leadingAnchor.constraint(equalTo: labelStack.leadingAnchor).isActive = true
        ctaButton.trailingAnchor.constraint(equalTo: labelStack.trailingAnchor).isActive = true
        ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true

        let imageView = UIImageView(image: .init(named: "tour1"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        view.insertSubview(imageView, belowSubview: waves)
        self.imageView = imageView
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: waves.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .systemRed.withAlphaComponent(0.3)
        view.insertSubview(container, belowSubview: waves)
        self.container = container

        container.leadingAnchor.constraint(equalTo: labelStack.leadingAnchor).isActive = true
        container.trailingAnchor.constraint(equalTo: labelStack.trailingAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        container.topAnchor.constraint(equalTo: waves.topAnchor).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if current == nil {
            startTour()
        }
    }

    private func startTour() {
        let first = steps.first!
        display(step: first)
    }

    private func display(step: Step) {
        current = step
        pageControl.currentPage = steps.firstIndex(where: { $0 === step }) ?? 0

        let title = isLastStep() ? "Start planting" : "Continue"

        // Image transition
        UIView.transition(with: imageView,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { self.imageView.image = UIImage(named: step.image) },
                          completion: nil)

        // Move and Fade transition
        UIView.animate(withDuration: 0.3) {
            self.moveRight()
            self.labelStack.alpha = 0
            self.ctaButton.alpha = 0
            self.container.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.moveLeft()
                self.titleLabel.text = step.title
                self.textLabel.text = step.text
                self.ctaButton.setTitle(title, for: .normal)
                self.labelStack.alpha = 1
                self.ctaButton.alpha = 1
                self.container.alpha = 1
                self.view.layoutIfNeeded()
            }
        }
    }

    private func moveRight() {
        labelLeft.constant = 64
        labelRight.constant = 32
    }

    private func moveLeft() {
        labelLeft.constant = 16
        labelRight.constant = -16
    }

    @objc func back() {
        guard !isFirstStep() else {
            dismiss(animated: true, completion: nil)
            return
        }
        display(step: steps[currentIndex - 1])
    }

    @objc func forward() {
        guard !isLastStep() else {
            dismiss(animated: true, completion: nil)
            return
        }
        display(step: steps[currentIndex + 1])
    }

    private var currentIndex: Int {
        guard let current = current else { return 0 }
        let index = steps.firstIndex(where: { $0 === current }) ?? 0
        return index
    }

    private func isFirstStep() -> Bool {
        return currentIndex == 0
    }


    private func isLastStep() -> Bool {
        return currentIndex + 1 >= steps.count
    }


    // MARK: Theming
    func applyTheme() {
        view.backgroundColor = .theme.ecosia.welcomeBackground
        waves.tintColor = .theme.ecosia.welcomeBackground
        titleLabel.textColor = .theme.ecosia.primaryText
        textLabel.textColor = .theme.ecosia.secondaryText
        skipButton.tintColor = .theme.ecosia.primaryButton
        backButton.tintColor = .theme.ecosia.primaryButton
        pageControl.pageIndicatorTintColor = .theme.ecosia.secondaryText
        pageControl.currentPageIndicatorTintColor = .theme.ecosia.primaryButton
        ctaButton.backgroundColor = .theme.ecosia.secondaryButton
        ctaButton.setTitleColor(.theme.ecosia.primaryText, for: .normal)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }
}
