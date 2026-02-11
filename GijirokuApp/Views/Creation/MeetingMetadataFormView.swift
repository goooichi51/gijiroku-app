import SwiftUI

struct MeetingMetadataFormView: View {
    @Binding var title: String
    @Binding var date: Date
    @Binding var location: String
    @Binding var participants: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("会議情報")
                .font(.headline)

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("タイトル")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("会議のタイトル", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("日時")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("場所")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("場所", text: $location)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("参加者")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ParticipantTagView(participants: $participants)
                }
            }
        }
    }
}
