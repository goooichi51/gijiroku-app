import SwiftUI

@main
struct GijirokuAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                Text("議事録アプリ")
                    .font(.largeTitle)
                    .bold()
                Text("開発中...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("議事録")
        }
    }
}
