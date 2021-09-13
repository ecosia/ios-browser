import UIKit

final class MultiplyImpactStep: UIView, Themeable {
    private weak var titleLabel: UILabel?
    private weak var subtitleLabel: UILabel?
    
    required init?(coder: NSCoder) { nil }
    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.isUserInteractionEnabled = false
        indicator.backgroundColor = .Photon.Grey20
        indicator.clipsToBounds = true
        indicator.layer.cornerRadius = 6
        addSubview(indicator)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(titleLabel)
        self.titleLabel = titleLabel
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(subtitleLabel)
        self.subtitleLabel = subtitleLabel
        
        bottomAnchor.constraint(equalTo: subtitleLabel.bottomAnchor).isActive = true
        
        indicator.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        indicator.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        indicator.widthAnchor.constraint(equalToConstant: 12).isActive = true
        indicator.heightAnchor.constraint(equalTo: indicator.widthAnchor).isActive = true
        
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: indicator.rightAnchor, constant: 12).isActive = true
        titleLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -12).isActive = true
        
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        subtitleLabel.leftAnchor.constraint(equalTo: indicator.rightAnchor, constant: 12).isActive = true
        subtitleLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -12).isActive = true
    }
    
    func applyTheme() {
        titleLabel?.textColor = .theme.ecosia.highContrastText
        subtitleLabel?.textColor = .theme.ecosia.secondaryText
    }
}
