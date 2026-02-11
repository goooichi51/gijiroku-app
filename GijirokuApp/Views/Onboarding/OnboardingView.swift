import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "mic.fill",
            iconColor: .blue,
            title: "録音するだけ",
            description: "AIが議事録を自動作成します",
            buttonTitle: "次へ"
        ),
        OnboardingPage(
            icon: "wand.and.stars",
            iconColor: .purple,
            title: "4つのテンプレート",
            description: "用途に合わせた議事録フォーマットを選択できます",
            buttonTitle: "次へ"
        ),
        OnboardingPage(
            icon: "doc.text.fill",
            iconColor: .green,
            title: "A4 PDFできれいに出力",
            description: "LINEやメールで簡単に共有できます",
            buttonTitle: "無料で始める"
        ),
    ]

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<pages.count, id: \.self) { index in
                OnboardingPageView(page: pages[index]) {
                    if index == pages.count - 1 {
                        onComplete()
                    } else {
                        withAnimation { currentPage = index + 1 }
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let buttonTitle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let action: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.iconColor)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .bold()
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            Button(action: action) {
                Text(page.buttonTitle)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}
