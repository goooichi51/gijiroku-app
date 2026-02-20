import UIKit

enum PDFDesign: String, Codable, CaseIterable, Identifiable {
    case business
    case corporate
    case modern
    case minimal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .business: return "ビジネス"
        case .corporate: return "コーポレート"
        case .modern: return "モダン"
        case .minimal: return "ミニマル"
        }
    }

    var description: String {
        switch self {
        case .business: return "枠付き正式文書"
        case .corporate: return "社内会議向け"
        case .modern: return "清潔感のあるデザイン"
        case .minimal: return "テキスト中心"
        }
    }

    var icon: String {
        switch self {
        case .business: return "doc.text"
        case .corporate: return "building.2"
        case .modern: return "rectangle.split.3x1"
        case .minimal: return "text.alignleft"
        }
    }

    var primaryColor: UIColor {
        switch self {
        case .business: return UIColor(red: 0.10, green: 0.15, blue: 0.27, alpha: 1)
        case .corporate: return UIColor(red: 0.17, green: 0.24, blue: 0.31, alpha: 1)
        case .modern: return UIColor(red: 0.29, green: 0.44, blue: 0.65, alpha: 1)
        case .minimal: return UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1)
        }
    }

    var secondaryColor: UIColor {
        switch self {
        case .business: return UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
        case .corporate: return UIColor(red: 0.92, green: 0.94, blue: 0.96, alpha: 1)
        case .modern: return UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        case .minimal: return UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
        }
    }
}
