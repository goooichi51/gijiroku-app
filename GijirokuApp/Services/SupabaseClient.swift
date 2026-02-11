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
            // 開発中はダミーURLで初期化（Edge Function呼び出し時にエラーになる）
            client = SupabaseClient(
                supabaseURL: URL(string: "https://placeholder.supabase.co")!,
                supabaseKey: "placeholder"
            )
        } else {
            client = SupabaseClient(
                supabaseURL: URL(string: url)!,
                supabaseKey: key
            )
        }
    }
}
