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

        let fallbackURL = "https://\(Secrets.supabaseProjectId).supabase.co"
        let supabaseURL = URL(string: url.isEmpty ? fallbackURL : url)
            ?? URL(string: fallbackURL)!
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key,
            options: .init(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
