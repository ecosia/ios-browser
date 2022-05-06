/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol WelcomeDelegate: AnyObject {
    func welcomeDidFinish(_ welcome: Welcome)
}

final class Welcome: UIViewController {
    private weak var logo: UIImageView!
    private weak var background: UIImageView!
    private weak var overlay: UIView!
    private weak var overlayLogo: UIImageView!
    private var mask: UIImageView!
    private weak var stack: UIStackView!

    private var logoCenterConstraint: NSLayoutConstraint!
    private var logoTopConstraint: NSLayoutConstraint!
    private var logoHeightConstraint: NSLayoutConstraint!
    private var stackBottonConstraint: NSLayoutConstraint!
    private var stackTopConstraint: NSLayoutConstraint!

    private var zoomedOut = false
    private weak var delegate: WelcomeDelegate?

    required init?(coder: NSCoder) { nil }
    init(delegate: WelcomeDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
        definesPresentationContext = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return zoomedOut ? .lightContent : .darkContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    // MARK: Views
    override func viewDidLoad() {
        super.viewDidLoad()

        addOverlay()
        addBackground()
        addStack()
    }

    private var didAppear = false
    override func viewDidAppear(_ animated: Bool) {
        guard !didAppear else { return }
        addMask()
        fadeIn()
        didAppear = true
    }

    private func addOverlay() {
        let overlay = UIView()
        overlay.backgroundColor = .init(named: "splash")
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        self.overlay = overlay

        overlay.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        overlay.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        overlay.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let overlayLogo = UIImageView(image: .init(named: "ecosiaLogoLaunch")?.withRenderingMode(.alwaysTemplate))
        overlayLogo.translatesAutoresizingMaskIntoConstraints = false
        overlayLogo.contentMode = .scaleAspectFit
        overlayLogo.tintColor = .init(named: "splashLogoTint")
        overlay.addSubview(overlayLogo)
        self.overlayLogo = overlayLogo

        overlayLogo.centerXAnchor.constraint(equalTo: overlay.centerXAnchor).isActive = true
        overlayLogo.centerYAnchor.constraint(equalTo: overlay.centerYAnchor).isActive = true
        overlayLogo.heightAnchor.constraint(equalToConstant: 72).isActive = true
    }

    private func addBackground() {
        let background = UIImageView(image: .init(named: "forest"))
        background.translatesAutoresizingMaskIntoConstraints = false
        background.contentMode = .scaleAspectFill
        view.addSubview(background)
        background.alpha = 0
        self.background = background

        background.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        background.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        background.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        background.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let logo = UIImageView(image: .init(named: "ecosiaLogoLaunch")?.withRenderingMode(.alwaysTemplate))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.contentMode = .scaleAspectFit
        logo.tintColor = .white
        background.addSubview(logo)
        self.logo = logo

        logoCenterConstraint = logo.centerYAnchor.constraint(equalTo: background.centerYAnchor)
        logoCenterConstraint.priority = .defaultHigh
        logoCenterConstraint.isActive = true
        logoTopConstraint = logo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        logoTopConstraint.priority = .defaultHigh
        logoTopConstraint.isActive = false
        logo.centerXAnchor.constraint(equalTo: background.centerXAnchor).isActive = true

        logoHeightConstraint = logo.heightAnchor.constraint(equalToConstant: 72)
        logoHeightConstraint.priority = .defaultHigh
        logoHeightConstraint.isActive = true
    }

    private func addStack() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 10
        view.addSubview(stack)
        self.stack = stack

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = introText
        label.font = .preferredFont(forTextStyle: .largeTitle).bold()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        stack.addArrangedSubview(label)

        let cta = UIButton(type: .system)
        cta.backgroundColor = .Light.Button.primary
        cta.setTitle("Get started", for: .normal)
        cta.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        cta.titleLabel?.adjustsFontForContentSizeCategory = true
        cta.setTitleColor(.Dark.Text.primary, for: .normal)
        cta.layer.cornerRadius = 25
        cta.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cta.addTarget(self, action: #selector(getStarted), for: .primaryActionTriggered)

        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(cta)

        let skip = UIButton(type: .system)
        skip.backgroundColor = .clear
        skip.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        skip.titleLabel?.adjustsFontForContentSizeCategory = true
        skip.setTitleColor(.Dark.Text.secondary, for: .normal)
        skip.setTitle("Skip welcome tour", for: .normal)
        skip.heightAnchor.constraint(equalToConstant: 50).isActive = true
        skip.addTarget(self, action: #selector(skipTour), for: .primaryActionTriggered)

        stack.addArrangedSubview(skip)

        stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        stackTopConstraint = stack.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        stackTopConstraint.priority = .defaultHigh
        stackTopConstraint.isActive = true
        stackBottonConstraint = stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        stackBottonConstraint.priority = .defaultHigh
    }

    func addMask() {
        let mask = UIImageView(image: .init(named: "splashMask"))
        mask.translatesAutoresizingMaskIntoConstraints = false
        // These values were determined by trial and error
        mask.frame.size.height = 32
        mask.frame.size.width = view.bounds.width
        mask.center = logo.center
        mask.center.x -= 10
        mask.center.y += 3
        mask.contentMode = .scaleAspectFit
        mask.alpha = 0
        background.mask = mask
        self.mask = mask
    }



    // MARK: Animations
    private func fadeIn() {
        UIView.animate(withDuration: 0.2) {
            self.background.alpha = 1
            self.mask.alpha = 1
        } completion: { _ in
            self.zoomOut()
        }
    }

    private func zoomOut() {
        self.zoomedOut = true

        let targetFrame = self.view.bounds.inset(by: .init(equalInset: -2.0 * self.view.bounds.height))
        UIView.animate(withDuration: 1.4, delay: 0.8, options: []) {
            self.background.mask?.frame = targetFrame
            self.setNeedsStatusBarAppearanceUpdate()
        } completion: { _ in
            self.showText()
        }
    }

    private func showText() {
        UIView.animate(withDuration: 0.3, delay: 0, options: []) {
            self.logoTopConstraint.isActive = true
            self.logoCenterConstraint.isActive = false
            self.logoHeightConstraint.constant = 48
            self.stack.isHidden = false
            self.stackTopConstraint.isActive = false
            self.stackBottonConstraint.isActive = true
            self.view.layoutIfNeeded()
        } completion: { _ in

        }

    }

    // MARK: Helper
    private var introText: NSAttributedString {
        let first = NSMutableAttributedString(string: "The simplest way to be ")
        let middle = NSMutableAttributedString(string: " climate-active every day while ")
        let end = NSMutableAttributedString(string: " browsing the web")

        let image1Attachment = NSTextAttachment()
        image1Attachment.image = UIImage(named: "splashTree1")
        let image1String = NSAttributedString(attachment: image1Attachment)

        let image2Attachment = NSTextAttachment()
        image2Attachment.image = UIImage(named: "splashTree2")
        let image2String = NSAttributedString(attachment: image2Attachment)

        first.append(image1String)
        first.append(middle)
        first.append(image2String)
        first.append(end)
        return first
    }

    // MARK: Actions
    @objc func getStarted() {
        let tour = WelcomeTour(delegate: self)
        tour.modalTransitionStyle = .crossDissolve
        tour.modalPresentationStyle = .overCurrentContext
        present(tour, animated: true, completion: nil)
    }

    @objc func skipTour() {
        delegate?.welcomeDidFinish(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        ThemeManager.instance.themeChanged(from: previousTraitCollection, to: traitCollection)
    }

}

extension Welcome: WelcomeTourDelegate {
    func welcomeTourDidFinish(_ tour: WelcomeTour) {
        skipTour()
    }
}
