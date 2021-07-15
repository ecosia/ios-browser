/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol SearchbarCellDelegate: AnyObject {
    func searchbarCellPressed(_ cell: SearchbarCell)
}

final class SearchbarCell: UICollectionViewCell, Themeable {
    private weak var search: UIButton!
    private weak var image: UIImageView!
    weak var delegate: SearchbarCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let search = SearchButton(type: .custom)
        search.translatesAutoresizingMaskIntoConstraints = false
        search.layer.cornerRadius = 10
        search.titleEdgeInsets.left = 40
        search.titleEdgeInsets.right = 8
        search.setTitle(.localized(.searchAndPlant), for: .normal)
        search.titleLabel?.lineBreakMode = .byTruncatingTail
        search.titleLabel?.font = .preferredFont(forTextStyle: .body)
        search.contentHorizontalAlignment = .left
        self.search = search
        applyTheme()

        search.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        contentView.addSubview(search)
        search.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        search.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
        search.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        search.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true

        let image = UIImageView(image: .init(named: "quickSearch"))
        image.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(image)
        self.image = image

        image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        image.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }

    func applyTheme() {
        search.backgroundColor = UIColor.theme.textField.backgroundInOverlay
        search.setTitleColor(UIColor.theme.ecosia.textfieldPlaceholder, for: .normal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    @objc func tapped() {
        delegate?.searchbarCellPressed(self)
    }
}

class SearchButton: UIButton {
    override var isSelected: Bool {
        get { return super.isSelected }
        set { super.isSelected = newValue }
    }
}
