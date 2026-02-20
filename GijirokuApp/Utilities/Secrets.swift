import Foundation

enum Secrets {
    static let supabaseProjectId = "mbhcyaocfngegssvtdgl"

    static var supabaseURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !url.isEmpty else {
            // 開発時のフォールバック
            return ""
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty else {
            return ""
        }
        return key
    }
}
