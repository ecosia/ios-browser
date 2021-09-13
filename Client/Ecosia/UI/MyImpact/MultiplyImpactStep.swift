import UIKit

final class MultiplyImpactStep: UIView, Themeable {
    
    required init?(coder: NSCoder) { nil }
    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func applyTheme() {
        
    }
}
