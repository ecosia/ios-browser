/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

protocol EcosiaHomeDelegate: AnyObject {
    func ecosiaHome(didSelectURL url: URL)
}

final class EcosiaHome: UICollectionViewController, UICollectionViewDelegateFlowLayout, Themeable, MyImpactStackViewModelResize {

    enum Section: Int, CaseIterable {
        case impact, multiply, news, explore

        var cell: AnyClass {
            switch self {
            case .impact: return MyImpactCell.self
            case .multiply: return MultiplyImpactCell.self
            case .explore: return EcosiaExploreCell.self
            case .news: return NewsCell.self
            }
        }

        var sectionTitle: String? {
            if self == .explore { return .localized(.exploreEcosia) }
            if self == .news { return .localized(.stories) }
            return nil
        }

        enum Explore: Int, CaseIterable {
            case info, finance, trees, faq, shop, privacy

            var title: String {
                switch self {
                case .info:
                    return .localized(.howEcosiaWorks)
                case .finance:
                    return .localized(.financialReports)
                case .trees:
                    return .localized(.trees)
                case .faq:
                    return .localized(.faq)
                case .shop:
                    return .localized(.shop)
                case .privacy:
                    return .localized(.privacy)
                }
            }

            var image: String {
                switch self {
                case .info:
                    return "networkTree"
                case .finance:
                    return "reports"
                case .trees:
                    return "treesIcon"
                case .faq:
                    return "faqIcon"
                case .shop:
                    return "shopIcon"
                case .privacy:
                    return "tigerIncognito"
                }
            }

            var url: URL {
                switch self {
                case .info:
                    return Environment.current.howEcosiaWorks
                case .finance:
                    return Environment.current.financialReports
                case .trees:
                    return Environment.current.trees
                case .faq:
                    return Environment.current.faq
                case .shop:
                    return Environment.current.shop
                case .privacy:
                    return Environment.current.privacy
                }
            }

            var label: Analytics.Label.Navigation {
                switch self {
                case .info:
                    return .howEcosiaWorks
                case .finance:
                    return .financialReports
                case .trees:
                    return .projects
                case .faq:
                    return .faq
                case .shop:
                    return .shop
                case .privacy:
                    return .privacy
                }
            }
        }
    }

    var delegate: EcosiaHomeDelegate?
    private var items = [NewsModel]()
    private let images = Images(.init(configuration: .ephemeral))
    private let news = News()
    private let personalCounter = PersonalCounter()

    lazy var impactModel: MyImpcactCellModel = {
        let callout = MyImpactStackViewModel.Callout(action: .collapse(text: .localized(.myImpactDescription),
                                                                       button: .localized(.learnMore),
                                                                       selector: #selector(learnMore)))
        let top = MyImpactStackViewModel(title: "\(User.shared.impact)",
                                         highlight: true, subtitle: .localized(.myTrees),
                                         imageName: "personalCounter",
                                         callout: callout)

        let middle = MyImpactStackViewModel(title: .localizedPlural(.treesPlural, num: User.shared.searchImpact),
                                            highlight: false,
                                            subtitle: .localizedPlural(.searches, num: personalCounter.state!),
                                            imageName: "impactSearch",
                                            callout: nil)

        let bottom = MyImpactStackViewModel(title: .localizedPlural(.treesPlural, num: User.shared.referralImpact),
                                            highlight: false,
                                            subtitle: .localizedPlural(.referrals, num: User.shared.referralCount),
                                            imageName: "impactReferrals",
                                            callout: nil)

        return MyImpcactCellModel(top: top, middle: middle, bottom: bottom)
    }()

    convenience init(delegate: EcosiaHomeDelegate?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        self.init(collectionViewLayout: layout)
        self.title = .localized(.myImpact).capitalized
        self.delegate = delegate
        navigationItem.largeTitleDisplayMode = .always
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let done = UIBarButtonItem(barButtonSystemItem: .done) { [ weak self ] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        navigationItem.rightBarButtonItem = done

        Section.allCases.forEach {
            collectionView!.register($0.cell, forCellWithReuseIdentifier: String(describing: $0.cell))
        }
        collectionView!.register(NewsHeaderCell.self, forCellWithReuseIdentifier: "NewsHeaderCell")
        collectionView.register(NewsButtonCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .scrollableAxes

        NotificationCenter.default.addObserver(self, selector: #selector(updateLayout), name: UIDevice.orientationDidChangeNotification, object: nil)

        applyTheme()

        news.subscribeAndReceive(self) { [weak self] in
            self?.items = $0
            self?.collectionView.reloadSections([Section.news.rawValue])
        }

        personalCounter.subscribeAndReceive(self)  { [weak self] _ in
            self?.collectionView.reloadSections([Section.impact.rawValue])
        }
    }

    private var hasAppeared: Bool = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        news.load(session: .shared, force: items.isEmpty)
        Analytics.shared.navigation(.view, label: .home)
        guard hasAppeared else { return hasAppeared = true }
        updateBarAppearance()
        collectionView.scrollRectToVisible(.init(x: 0, y: 0, width: 1, height: 1), animated: false)
        collectionView.reloadSections([Section.impact.rawValue])
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .impact: return 1
        case .multiply: return 1
        case .explore: return Section.Explore.allCases.count + 1 // header
        case .news: return min(3, items.count) + 1 // header
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let section = Section(rawValue: indexPath.section)!
        let margin = max(16, collectionView.safeAreaInsets.left)

        switch  section {
        case .impact:
            let infoCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: section.cell), for: indexPath) as! MyImpactCell
            infoCell.widthConstraint.constant = collectionView.bounds.width - 2 * margin
            infoCell.display(impactModel)
            return infoCell
        case .multiply:
            let multiplyCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: section.cell), for: indexPath) as! MultiplyImpactCell
            multiplyCell.widthConstraint.constant = collectionView.bounds.width - 2 * margin
            let model = MyImpactStackViewModel(title: .localized(.multiplyImpact),
                                               highlight: false,
                                               subtitle: nil,
                                               imageName: "impactMultiply",
                                               callout: .init(action: .tap(text: .localized(.inviteFriends), action: #selector(inviteFriends))))
            multiplyCell.stack.display(model)
            return multiplyCell
        case .explore:
            if indexPath.row == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsHeaderCell", for: indexPath) as! NewsHeaderCell
                cell.titleLabel.text = section.sectionTitle
                cell.widthConstraint.constant = collectionView.bounds.width - 2 * margin
                return cell
            } else {
                let exploreCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: section.cell), for: indexPath) as! EcosiaExploreCell
                var width = (view.bounds.width - 2 * margin - 16)/2.0
                width = min(width, 180)
                exploreCell.widthConstraint.constant = width
                Section.Explore(rawValue: indexPath.row - 1).map { exploreCell.display($0) }
                return exploreCell
            }
        case .news:
            if indexPath.row == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsHeaderCell", for: indexPath) as! NewsHeaderCell
                cell.titleLabel.text = section.sectionTitle
                cell.widthConstraint.constant = collectionView.bounds.width - 2 * margin
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: section.cell), for: indexPath) as! NewsCell
                let itemCount = self.collectionView(collectionView, numberOfItemsInSection: Section.news.rawValue) - 1
                cell.configure(items[indexPath.row - 1], images: images, positions: .derive(row: indexPath.row - 1, items: itemCount))
                cell.widthConstraint.constant = collectionView.bounds.width
                return cell
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer", for: indexPath) as! NewsButtonCell
            view.moreButton.setTitle(.localized(.more), for: .normal)
            view.moreButton.addTarget(self, action: #selector(allNews), for: .touchUpInside)
            return view
        default:
            return UICollectionReusableView()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }

        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .impact:
            if indexPath.row == 0 {
                delegate?.ecosiaHome(didSelectURL: Environment.current.aboutCounter)
                Analytics.shared.navigation(.open, label: .counter)
                dismiss(animated: true, completion: nil)
            }
        case .news:
            delegate?.ecosiaHome(didSelectURL: items[indexPath.row].targetUrl)
            Analytics.shared.navigationOpenNews(items[indexPath.row].trackingName)
            dismiss(animated: true, completion: nil)
        case .explore:
            Section.Explore(rawValue: indexPath.row)
                .map {
                    delegate?.ecosiaHome(didSelectURL: $0.url)
                    Analytics.shared.navigation(.open, label: $0.label)
                }
            dismiss(animated: true, completion: nil)
        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = Section(rawValue: indexPath.section)!
        let margin = max(16, collectionView.safeAreaInsets.left)

        switch section {
        case .impact:
            return CGSize(width: view.bounds.width - 2 * margin, height: 226)
        case .multiply:
            return CGSize(width: view.bounds.width - 2 * margin, height: 56)
        case .news:
            return CGSize(width: view.bounds.width, height: 130)
        case .explore:

            var width = (view.bounds.width - 2 * margin - 16)/2.0
            width = min(width, 180)
            return CGSize(width: width, height: width + 32)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {

        switch Section(rawValue: section)! {
        case .news:
            return CGSize(width: view.bounds.width - 32, height: 36)
        default:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .news:
            return 0
        default:
            return 16
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let section = Section(rawValue: section), section == .explore else { return .zero }
        return .init(top: 0, left: 16, bottom: 0, right: 16)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        showSeparator = scrollView.contentOffset.y + scrollView.adjustedContentInset.top <= 12
    }

    private var showSeparator = false {
        didSet {
            if showSeparator != oldValue {
                updateBarAppearance()
            }
        }
    }

    private func updateBarAppearance() {
        guard #available(iOS 13, *), let appearance = navigationController?.navigationBar.standardAppearance else { return }

        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.theme.ecosia.modalBackground
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.theme.ecosia.highContrastText]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.theme.ecosia.highContrastText]

        if showSeparator {
            appearance.shadowColor = nil
            appearance.shadowImage = nil
        } else {
            appearance.shadowColor = UIColor.theme.ecosia.barSeparator
            appearance.shadowImage = UIImage()
        }
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.setNeedsDisplay()
    }

    @objc private func allNews() {
        let news = NewsController(items: items, delegate: delegate)
        navigationController?.pushViewController(news, animated: true)
        Analytics.shared.navigation(.open, label: .news)
    }

    func applyTheme() {
        collectionView.reloadData()
        view.backgroundColor = UIColor.theme.ecosia.modalBackground
        collectionView.backgroundColor = UIColor.theme.ecosia.modalBackground
        navigationItem.leftBarButtonItem?.tintColor = UIColor.theme.ecosia.primaryToolbar
        updateBarAppearance()
    }

    @objc func updateLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }

    @objc func inviteFriends() {
        // entry point to Referral Screen
    }

    @objc func learnMore() {
        delegate?.ecosiaHome(didSelectURL: Environment.current.aboutCounter)
        Analytics.shared.navigation(.open, label: .counter)
        dismiss(animated: true, completion: nil)
    }

    @objc func resizeStack(sender: MyImpactStackView) {
        guard let model = sender.model, let collapsed = model.callout?.collapsed else { return }
        impactModel.top.callout?.collapsed = !collapsed

        UIView.animate(withDuration: 0.3) {
            self.collectionView.reloadItems(at: [IndexPath(item: 0, section: Section.impact.rawValue)])
            self.collectionViewLayout.invalidateLayout()
        }
    }
}
