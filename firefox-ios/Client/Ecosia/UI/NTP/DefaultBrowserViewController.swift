// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

@available(iOS 14, *)
protocol DefaultBrowserDelegate: AnyObject {
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowserViewController)
}

@available(iOS 14, *)
final class DefaultBrowserViewController: UIViewController, Themeable {

    /// The minimum amount of searches required to show the Default Browser
    static var minPromoSearches = 50

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: DefaultBrowserExperiment.image)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }()
    private lazy var waves: UIImageView = {
        let view = UIImageView(image: .init(named: "waves"))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleToFill
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultBrowserExperiment.title
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title3).bold()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    private lazy var variationContentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()
    private lazy var actionButton: UIButton = {
        let button = EcosiaPrimaryButton(windowUUID: windowUUID)
        button.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(DefaultBrowserExperiment.buttonTitle, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(clickAction), for: .primaryActionTriggered)
        button.setContentHuggingPriority(.required, for: .vertical)
        return button
    }()
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle(.localized(.maybeLater), for: .normal)
        button.addTarget(self, action: #selector(skipAction), for: .primaryActionTriggered)
        return button
    }()

    // MARK: Description variation
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultBrowserExperiment.description
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    // MARK: Checks variation
    private lazy var firstCheckItemLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultBrowserExperiment.checkItems.0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    private lazy var secondCheckItemLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultBrowserExperiment.checkItems.1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    private lazy var firstCheckImageView: UIImageView = {
        let view = UIImageView(image: .init(systemName: "checkmark"))
        view.contentMode = .scaleAspectFit
        view.widthAnchor.constraint(equalToConstant: 16).isActive = true
        return view
    }()
    private lazy var secondCheckImageView: UIImageView = {
        let view = UIImageView(image: .init(systemName: "checkmark"))
        view.contentMode = .scaleAspectFit
        view.widthAnchor.constraint(equalToConstant: 16).isActive = true
        return view
    }()

    // MARK: Themeable Properties
    let windowUUID: WindowUUID
    var currentWindowUUID: WindowUUID? { windowUUID }
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    weak var delegate: DefaultBrowserDelegate?
    init(windowUUID: WindowUUID, delegate: DefaultBrowserDelegate) {
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        if traitCollection.userInterfaceIdiom == .pad {
            modalPresentationStyle = .formSheet
            preferredContentSize = .init(width: 544, height: 600)
        } else {
            modalPresentationCapturesStatusBarAppearance = true
        }
    }

    required init?(coder: NSCoder) { nil }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
       .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        applyTheme()

        listenForThemeChange(self.view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: Review Analytics
        Analytics.shared.defaultBrowser(.view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        modalTransitionStyle = .crossDissolve
        self.delegate?.defaultBrowserDidShow(self)
    }

    private func setupViews() {
        view.addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(waves)
        contentView.addSubview(titleLabel)
        contentView.addSubview(actionButton)
        contentView.addSubview(skipButton)
        view.addSubview(variationContentStack)

        let type = DefaultBrowserExperiment.contentType
        if case .checks = type {
            let line1 = UIStackView()
            line1.spacing = 10
            line1.axis = .horizontal
            variationContentStack.addArrangedSubview(line1)
            line1.addArrangedSubview(firstCheckImageView)
            line1.addArrangedSubview(firstCheckItemLabel)
            let line2 = UIStackView()
            line2.spacing = 10
            line2.axis = .horizontal
            variationContentStack.addArrangedSubview(line2)
            line2.addArrangedSubview(secondCheckImageView)
            line2.addArrangedSubview(secondCheckItemLabel)
        } else if case .description = type {
            variationContentStack.addArrangedSubview(descriptionLabel)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 300).priority(.defaultHigh),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            waves.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            waves.heightAnchor.constraint(equalToConstant: 34),
            waves.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            waves.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: waves.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).priority(.defaultLow),

            variationContentStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            variationContentStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            variationContentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),

            actionButton.topAnchor.constraint(equalTo: variationContentStack.bottomAnchor, constant: 24),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            actionButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            skipButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 8),
            skipButton.leadingAnchor.constraint(equalTo: actionButton.leadingAnchor),
            skipButton.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor),
            skipButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            skipButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    @objc func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = .clear
        titleLabel.textColor = theme.colors.ecosia.textPrimary
        contentView.backgroundColor = theme.colors.ecosia.ntpIntroBackground
        waves.tintColor = theme.colors.ecosia.ntpIntroBackground
        actionButton.setTitleColor(theme.colors.ecosia.textInversePrimary, for: .normal)
        skipButton.setTitleColor(theme.colors.ecosia.buttonBackgroundPrimary, for: .normal)
        actionButton.backgroundColor = theme.colors.ecosia.buttonBackgroundPrimary
        descriptionLabel.textColor = theme.colors.ecosia.textSecondary
        firstCheckItemLabel.textColor = theme.colors.ecosia.textSecondary
        secondCheckItemLabel.textColor = theme.colors.ecosia.textSecondary
        firstCheckImageView.tintColor = theme.colors.ecosia.buttonBackgroundPrimary
        secondCheckImageView.tintColor = theme.colors.ecosia.buttonBackgroundPrimary
    }

    @objc private func skipAction() {
        // TODO: Review Analytics
        Analytics.shared.defaultBrowser(.close)
        dismiss(animated: true)
    }

    @objc private func clickAction() {
        // TODO: Review Analytics
        Analytics.shared.defaultBrowser(.click)

        dismiss(animated: true) {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
        }
    }
}
