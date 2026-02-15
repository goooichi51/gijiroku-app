import Foundation
import Supabase

@MainActor
class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let url = Secrets.supabaseURL
        let key = Secrets.supabaseAnonKey

        if url.isEmpty || key.isEmpty {
            AppLogger.sync.warning("Supabase URLまたはAnon Keyが未設定です")
        }

        let supabaseURL = URL(string: url.isEmpty ? "https://placeholder.supabase.co" : url)
            ?? URL(string: "https://placeholder.supabase.co")!
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key.isEmpty ? "placeholder" : key
        )
    }
}
