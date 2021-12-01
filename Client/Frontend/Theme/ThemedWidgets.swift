/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import UIKit

class ThemedTableViewCell: UITableViewCell, Themeable {
    var detailTextColor = UIColor.theme.tableView.disabledRowText
    let style: UITableViewCell.CellStyle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.style = style
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        textLabel?.textColor = UIColor.theme.tableView.rowText
        detailTextLabel?.textColor = detailTextColor
        backgroundColor = UIColor.theme.tableView.rowBackground
        tintColor = UIColor.theme.general.controlTint
    }

    private var textFrame: CGRect?
    private var detailFrame: CGRect?

    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {

        // Fix autosizing of UITableViewCellStyle.Value1
        guard style == .value1, let textLabel = self.textLabel, let detailTextLabel = self.detailTextLabel else {
            return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
        }

        self.layoutIfNeeded()
        var size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)

        let detailHeight = detailTextLabel.frame.size.height
        let textHeight = textLabel.frame.size.height
        let xMargin: CGFloat = 16
        let yMargin:CGFloat = 10
        let labelsMargin: CGFloat = 6
        let factor: CGFloat = 0.6

        size.height = max(detailHeight, textHeight) + 2 * yMargin

        var accessoryOffset = accessoryView?.frame.size.width ?? 0.0
        if accessoryOffset > 0 { accessoryOffset += 8 }

        if textLabel.frame.maxX > size.width * factor, textLabel.frame.maxX + labelsMargin >= detailTextLabel.frame.minX {
            var textFrame = textLabel.frame
            textFrame.origin.y = yMargin
            textFrame.size.width = size.width * factor
            textFrame.size.height = size.height - 2.0 * yMargin
            textFrame.size = textLabel.sizeThatFits(textFrame.size)
            self.textFrame = textFrame

            var detailFrame = detailTextLabel.frame
            detailFrame.origin.y = yMargin
            detailFrame.origin.x = textFrame.maxX + labelsMargin
            detailFrame.size.height = size.height - 2 * yMargin
            detailFrame.size.width = size.width - 2 * xMargin - textFrame.width - accessoryOffset - labelsMargin
            self.detailFrame = detailFrame
            size.height = max(detailFrame.height, textFrame.height) + 2 * yMargin
        } else if textFrame != nil, detailFrame != nil {
            // fix position on rotation
            textFrame!.size = textLabel.sizeThatFits(size)
            detailFrame!.size = detailTextLabel.sizeThatFits(size)
            size.height = max(detailFrame!.height, textFrame!.height) + 2 * yMargin
            detailFrame!.origin.x = textFrame!.maxX + labelsMargin
            detailFrame!.size.height = size.height - 2 * yMargin
            detailFrame!.size.width = size.width - 2 * xMargin - textFrame!.width - accessoryOffset - labelsMargin
        }
        return size
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let textFrame = textFrame, let detailFrame = detailFrame {
            self.textLabel?.frame = textFrame
            self.detailTextLabel?.frame = detailFrame
        }
    }
}

class ThemedTableViewController: UITableViewController, Themeable {
    override init(style: UITableView.Style = .grouped) {
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .subtitle, reuseIdentifier: nil)
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
    }

    func applyTheme() {
        tableView.separatorColor = UIColor.theme.tableView.separator
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
        tableView.reloadData()

        (tableView.tableHeaderView as? Themeable)?.applyTheme()
    }
}

class ThemedTableSectionHeaderFooterView: UITableViewHeaderFooterView, Themeable {
    private struct UX {
        static let titleHorizontalPadding: CGFloat = 15
        static let titleVerticalPadding: CGFloat = 6
        static let titleVerticalLongPadding: CGFloat = 20
    }

    enum TitleAlignment {
        case top
        case bottom
    }

    var titleAlignment: TitleAlignment = .bottom {
        didSet {
            remakeTitleAlignmentConstraints()
        }
    }

    lazy var titleLabel: UILabel = {
        var headerLabel = UILabel()
        headerLabel.font = UIFont.systemFont(ofSize: 12.0, weight: UIFont.Weight.regular)
        headerLabel.numberOfLines = 0
        return headerLabel
    }()

    fileprivate lazy var bordersHelper = ThemedHeaderFooterViewBordersHelper()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        bordersHelper.initBorders(view: self)
        setDefaultBordersValues()
        setupInitialConstraints()
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        bordersHelper.applyTheme()
        contentView.backgroundColor = UIColor.theme.tableView.headerBackground
        titleLabel.textColor = UIColor.theme.tableView.headerTextLight
    }

    func setupInitialConstraints() {
        remakeTitleAlignmentConstraints()
    }

    func showBorder(for location: ThemedHeaderFooterViewBordersHelper.BorderLocation, _ show: Bool) {
        bordersHelper.showBorder(for: location, show)
    }

    func setDefaultBordersValues() {
        bordersHelper.showBorder(for: .top, false)
        bordersHelper.showBorder(for: .bottom, false)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setDefaultBordersValues()
        titleLabel.text = nil
        titleAlignment = .bottom

        applyTheme()
    }

    fileprivate func remakeTitleAlignmentConstraints() {
        switch titleAlignment {
        case .top:
            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalTo(self.contentView).inset(UX.titleHorizontalPadding)
                make.top.equalTo(self.contentView).offset(UX.titleVerticalPadding)
                make.bottom.equalTo(self.contentView).offset(-UX.titleVerticalLongPadding)
            }
        case .bottom:
            titleLabel.snp.remakeConstraints { make in
                make.left.right.equalTo(self.contentView).inset(UX.titleHorizontalPadding)
                make.bottom.equalTo(self.contentView).offset(-UX.titleVerticalPadding)
                make.top.equalTo(self.contentView).offset(UX.titleVerticalLongPadding)
            }
        }
    }
}

class ThemedHeaderFooterViewBordersHelper: Themeable {
    enum BorderLocation {
        case top
        case bottom
    }

    fileprivate lazy var topBorder: UIView = {
        let topBorder = UIView()
        return topBorder
    }()

    fileprivate lazy var bottomBorder: UIView = {
        let bottomBorder = UIView()
        return bottomBorder
    }()

    func showBorder(for location: BorderLocation, _ show: Bool) {
        switch location {
        case .top:
            topBorder.isHidden = !show
        case .bottom:
            bottomBorder.isHidden = !show
        }
    }

    func initBorders(view: UITableViewHeaderFooterView) {
        view.contentView.addSubview(topBorder)
        view.contentView.addSubview(bottomBorder)
        
        topBorder.snp.makeConstraints { make in
            make.left.right.top.equalTo(view.contentView)
            make.height.equalTo(0.25)
        }

        bottomBorder.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view.contentView)
            make.height.equalTo(0.5)
        }
    }

    func applyTheme() {
        topBorder.backgroundColor = UIColor.theme.tableView.separator
        bottomBorder.backgroundColor = UIColor.theme.tableView.separator
    }
}

class UISwitchThemed: UISwitch {
    override func layoutSubviews() {
        super.layoutSubviews()
        onTintColor = UIColor.theme.general.controlTint
    }
}
