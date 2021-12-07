/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SDWebImage
import Storage

private struct TopSiteCellUX {
    static let TitleHeight: CGFloat = 24
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CellCornerRadius: CGFloat = 4
    static let TitleOffset: CGFloat = 4
    static let OverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let IconCornerRadius: CGFloat = 4
    static let BackgroundSize = CGSize(width: 52, height: 52)
    static let IconBackgroundSize: CGFloat = 52
    static let IconSize: CGFloat = 32
    static var BorderColor: UIColor { return .theme.ecosia.secondaryButton }
    static let BorderWidth: CGFloat = 1
    static let PinIconSize: CGFloat = 16
    static let PinColor = UIColor.Photon.Grey60
    static let FavIconInset: CGFloat = 18
}

/*
 *  The TopSite cell that appears in the ASHorizontalScrollView.
 */
class TopSiteItemCell: UICollectionViewCell, Themeable {

    var url: URL?

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = TopSiteCellUX.IconCornerRadius
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var titleWrapper = UIView()

    lazy var pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.templateImageNamed("pin_small")
        return imageView
    }()

    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2
        titleLabel.allowsDefaultTighteningForTruncation = true
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        return titleLabel
    }()

    lazy private var faviconBG: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TopSiteCellUX.IconBackgroundSize / 2.0
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        return view
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()

    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityIdentifier = "TopSite"
        contentView.addSubview(titleWrapper)
        titleWrapper.addSubview(titleLabel)
        contentView.addSubview(faviconBG)
        faviconBG.addSubview(imageView)
        contentView.addSubview(selectedOverlay)

        titleWrapper.snp.makeConstraints { make in
            make.top.equalTo(faviconBG.snp.bottom).offset(8)
            make.bottom.centerX.equalTo(contentView)
            make.width.lessThanOrEqualTo(TopSiteCellUX.BackgroundSize.width + 20)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(contentView).offset(TopSiteCellUX.TitleOffset)
            make.right.equalTo(contentView).offset(-TopSiteCellUX.TitleOffset)
            make.top.equalTo(faviconBG.snp.bottom).offset(4)
            let maxHeight = titleLabel.font.pointSize * (CGFloat(titleLabel.numberOfLines) + 0.6) + 8
            make.height.lessThanOrEqualTo(maxHeight)
        }

        imageView.snp.makeConstraints { make in
            make.size.equalTo(TopSiteCellUX.IconSize)
            make.center.equalTo(faviconBG)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        faviconBG.snp.makeConstraints { make in
            make.size.equalTo(TopSiteCellUX.IconBackgroundSize)
            make.top.equalTo(contentView).offset(TopSiteCellUX.FavIconInset)
            make.centerX.equalTo(contentView)
        }
        faviconBG.widthAnchor.constraint(equalTo: faviconBG.heightAnchor, multiplier: 1.0).isActive = true

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = UIColor.clear
        imageView.image = nil
        imageView.backgroundColor = UIColor.clear
        faviconBG.backgroundColor = UIColor.clear
        pinImageView.removeFromSuperview()
        imageView.sd_cancelCurrentImageLoad()
        titleLabel.text = ""
    }

    func configureWithTopSiteItem(_ site: Site) {
        url = site.tileURL

        /* Ecosia: use html title for top sites */
        if !site.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            titleLabel.text = site.title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        else if let provider = site.metadata?.providerName {
            titleLabel.text = provider.lowercased()
        } else {
            titleLabel.text = site.tileURL.shortDisplayString
        }
        let words = titleLabel.text?.components(separatedBy: .whitespacesAndNewlines).count ?? 0
        titleLabel.numberOfLines = min(max(words, 1), 2)
        titleLabel.snp.updateConstraints { make in
            let maxHeight = titleLabel.font.pointSize * (CGFloat(titleLabel.numberOfLines) + 0.6) + 8
            make.height.lessThanOrEqualTo(maxHeight)
        }

        // If its a pinned site add a bullet point to the front
        if let _ = site as? PinnedSite {
            contentView.addSubview(pinImageView)
            pinImageView.snp.makeConstraints { make in
                make.top.left.equalTo(self.faviconBG)
                make.size.equalTo(TopSiteCellUX.PinIconSize)
            }
            /* Ecosia
            titleLabel.snp.updateConstraints { make in
                make.leading.equalTo(titleWrapper).offset(TopSiteCellUX.PinIconSize + TopSiteCellUX.TitleOffset)
            }
            */
        } else {
            /* Ecosia
            titleLabel.snp.updateConstraints { make in
                make.leading.equalTo(titleWrapper)
            }
            */
        }

        accessibilityLabel = titleLabel.text
        faviconBG.backgroundColor = .clear
        self.imageView.setFaviconOrDefaultIcon(forSite: site) { [weak self] in
            self?.imageView.snp.remakeConstraints { make in
                guard let faviconBG = self?.faviconBG else { return }
                make.size.equalTo(TopSiteCellUX.IconSize)
                make.center.equalTo(faviconBG)
            }

            self?.faviconBG.backgroundColor = self?.imageView.backgroundColor
        }

        applyTheme()
    }

    func applyTheme() {
        pinImageView.tintColor = UIColor.theme.homePanel.topSitePin
        faviconBG.backgroundColor = .theme.ecosia.secondaryButton
        selectedOverlay.backgroundColor = TopSiteCellUX.OverlayColor
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.theme.ecosia.primaryText
    }
}

// An empty cell to show when a row is incomplete
class EmptyTopsiteDecorationCell: UICollectionReusableView, Themeable {

    lazy private var emptyBG: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TopSiteCellUX.IconBackgroundSize/2.0
        view.layer.borderWidth = TopSiteCellUX.BorderWidth
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(emptyBG)
        emptyBG.snp.makeConstraints { make in
            make.size.equalTo(TopSiteCellUX.IconBackgroundSize)
            make.top.equalTo(self).offset(TopSiteCellUX.FavIconInset)
            make.centerX.equalTo(self)
        }
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme () {
        emptyBG.layer.borderColor = UIColor.theme.ecosia.secondaryButton.cgColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}

private struct ASHorizontalScrollCellUX {
    static let TopSiteCellIdentifier = "TopSiteItemCell"
    static let TopSiteEmptyCellIdentifier = "TopSiteItemEmptyCell"

    static let TopSiteItemSize = CGSize(width: 80, height: 90)
    static let MinimumInsets: CGFloat = 0
    static let VerticalInsets: CGFloat = 16
    static let MaxWidth: CGFloat = 120
}

/*
 The View that describes the topSite cell that appears in the tableView.
 */
class ASHorizontalScrollCell: UICollectionViewCell, Themeable {

    var heightConstraint: NSLayoutConstraint!
    var widthConstraint: NSLayoutConstraint!

    lazy var collectionView: UICollectionView = {
        let layout  = HorizontalFlowLayout()
        layout.itemSize = ASHorizontalScrollCellUX.TopSiteItemSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TopSiteItemCell.self, forCellWithReuseIdentifier: ASHorizontalScrollCellUX.TopSiteCellIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.layer.masksToBounds = false
        return collectionView
    }()

    weak var delegate: ASHorizontalScrollCellManager? {
        didSet {
            collectionView.delegate = delegate
            collectionView.dataSource = delegate
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        accessibilityIdentifier = "TopSitesCell"
        backgroundColor = UIColor.clear
        contentView.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeArea.edges)
        }

        let heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 100)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        self.heightConstraint = heightConstraint

        let widthConstraint = collectionView.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        collectionView.visibleCells.forEach {
            ($0 as? Themeable)?.applyTheme()
        }
    }
}
/*
    A custom layout used to show a horizontal scrolling list with paging. Similar to iOS springboard.
    A modified version of http://stackoverflow.com/a/34167915
 */

class HorizontalFlowLayout: UICollectionViewLayout {
    fileprivate var cellCount: Int {
        if let collectionView = collectionView, let dataSource = collectionView.dataSource {
            return dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
        }
        return 0
    }
    var boundsSize = CGSize.zero
    private var insets = UIEdgeInsets(equalInset: ASHorizontalScrollCellUX.MinimumInsets)
    private var sectionInsets: CGFloat = 0
    var itemSize = CGSize.zero
    var cachedAttributes: [UICollectionViewLayoutAttributes]?

    override func prepare() {
        super.prepare()
        if boundsSize != self.collectionView?.frame.size {
            self.collectionView?.setContentOffset(.zero, animated: false)
        }
        boundsSize = self.collectionView?.frame.size ?? .zero
        cachedAttributes = nil
        register(EmptyTopsiteDecorationCell.self, forDecorationViewOfKind: ASHorizontalScrollCellUX.TopSiteEmptyCellIdentifier)
    }

    func numberOfPages(with bounds: CGSize) -> Int {
        return 1
    }

    func calculateLayout(for size: CGSize) -> (size: CGSize, cellSize: CGSize, cellInsets: UIEdgeInsets) {
        let width = size.width
        guard width != 0 else {
            return (size: .zero, cellSize: self.itemSize, cellInsets: self.insets)
        }

        let horizontalItemsCount = maxHorizontalItemsCount(width: width) // 8
        var estimatedItemSize = itemSize
        estimatedItemSize.width = min(width/Double(horizontalItemsCount), ASHorizontalScrollCellUX.MaxWidth)

        //calculate our estimates.
        let rows = CGFloat(ceil(Double(Float(cellCount)/Float(horizontalItemsCount))))
        let estimatedHeight = (rows * estimatedItemSize.height) + (8 * rows)
        let estimatedSize = CGSize(width: width, height: estimatedHeight)

        // Take the number of cells and subtract its space in the view from the width. The left over space is the white space.
        // The left over space is then divided evenly into (n - 1) parts to figure out how much space should be in between a cell
        let calculatedSpacing = floor((width - (CGFloat(horizontalItemsCount) * estimatedItemSize.width)) / CGFloat(horizontalItemsCount - 1))
        let insets = max(ASHorizontalScrollCellUX.MinimumInsets, calculatedSpacing)
        let estimatedInsets = UIEdgeInsets(top: ASHorizontalScrollCellUX.VerticalInsets, left: insets, bottom: ASHorizontalScrollCellUX.VerticalInsets, right: insets)

        return (size: estimatedSize, cellSize: estimatedItemSize, cellInsets: estimatedInsets)
    }

    override var collectionViewContentSize: CGSize {
        let estimatedLayout = calculateLayout(for: boundsSize)
        insets = estimatedLayout.cellInsets
        itemSize = estimatedLayout.cellSize
        boundsSize.height = estimatedLayout.size.height
        return estimatedLayout.size
    }

    func maxHorizontalItemsCount(width: CGFloat) -> Int {
        let horizontalItemsCount = Int(floor(width / (ASHorizontalScrollCellUX.TopSiteItemSize.width + insets.left)))
        if let delegate = self.collectionView?.delegate as? ASHorizontalLayoutDelegate {
            return delegate.numberOfHorizontalItems()
        } else {
            return horizontalItemsCount
        }
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let decorationAttr = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
        let cellAttr = self.computeLayoutAttributesForCellAtIndexPath(indexPath)
        decorationAttr.frame = cellAttr.frame

        decorationAttr.frame.size.height -= TopSiteCellUX.TitleHeight
        decorationAttr.zIndex = -1
        return decorationAttr
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if cachedAttributes != nil {
            return cachedAttributes
        }
        var allAttributes = [UICollectionViewLayoutAttributes]()
        for i in 0 ..< cellCount {
            let indexPath = IndexPath(row: i, section: 0)
            let attr = self.computeLayoutAttributesForCellAtIndexPath(indexPath)
            allAttributes.append(attr)
        }

        //create decoration attributes
        let horizontalItemsCount = maxHorizontalItemsCount(width: boundsSize.width)
        var numberOfCells = cellCount
        while numberOfCells % horizontalItemsCount != 0 {
            //we need some empty cells dawg.

            let attr = self.layoutAttributesForDecorationView(ofKind: ASHorizontalScrollCellUX.TopSiteEmptyCellIdentifier, at: IndexPath(item: numberOfCells, section: 0))
            allAttributes.append(attr!)
            numberOfCells += 1
        }
        cachedAttributes = allAttributes
        return allAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.computeLayoutAttributesForCellAtIndexPath(indexPath)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        cachedAttributes = nil
        // Sometimes when the topsiteCell isnt on the screen the newbounds that it tries to layout in is 0
        // Resulting in incorrect layouts. Only layout when a valid width is given
        return newBounds.width > 0 && newBounds.size != self.collectionView?.frame.size
    }

    func computeLayoutAttributesForCellAtIndexPath(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let row = indexPath.row
        let bounds = self.collectionView!.bounds

        let horizontalItemsCount = maxHorizontalItemsCount(width: bounds.size.width)
        let columnPosition = row % horizontalItemsCount
        let rowPosition = Int(row/horizontalItemsCount)

        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        var frame = CGRect.zero
        frame.origin.x = CGFloat(columnPosition) * (itemSize.width + insets.left)
        frame.origin.y = CGFloat(rowPosition) * (itemSize.height + insets.top)
        
        frame.size = itemSize
        attr.frame = frame
        return attr
    }
}

/*
    Defines the number of items to show in topsites for different size classes.
*/
private struct ASTopSiteSourceUX {
    static let CellIdentifier = "TopSiteItemCell"
}

protocol ASHorizontalLayoutDelegate {
    func numberOfHorizontalItems() -> Int
}

/*
 This Delegate/DataSource is used to manage the ASHorizontalScrollCell's UICollectionView.
 This is left generic enough for it to be re used for other parts of Activity Stream.
 */

class ASHorizontalScrollCellManager: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, ASHorizontalLayoutDelegate {

    var content: [Site] = []

    var urlPressedHandler: ((Site, IndexPath) -> Void)?
    // The current traits that define the parent ViewController. Used to determine how many rows/columns should be created.
    var currentTraits: UITraitCollection?

    func numberOfHorizontalItems() -> Int {
        guard let traits = currentTraits else {
            return 0
        }
        /* Ecosia: always have 4 items in 1 row on iPhone */
        if UIDevice.current.userInterfaceIdiom == .phone {
            return 4
        } else {
            let numItems = Int(FirefoxHomeUX.numberOfItemsPerRowForSizeClassIpad[traits.horizontalSizeClass])
            return numItems
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.content.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ASTopSiteSourceUX.CellIdentifier, for: indexPath) as! TopSiteItemCell
        let contentItem = content[indexPath.row]
        cell.configureWithTopSiteItem(contentItem)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let contentItem = content[indexPath.row]
        urlPressedHandler?(contentItem, indexPath)
    }
}
