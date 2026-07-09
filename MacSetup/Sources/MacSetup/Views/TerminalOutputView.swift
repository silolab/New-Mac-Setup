import SwiftUI

struct TerminalOutputView: View {
    @ObservedObject var runner: CommandRunner

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("터미널 출력")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                if runner.isRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 4)
                }
                Button("지우기") {
                    runner.clear()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .disabled(runner.outputLines.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // Output
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(runner.outputLines) { line in
                            Text(line.text)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(lineColor(line))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .id(line.id)
                        }
                    }
                    .padding(10)
                }
                .background(Color(nsColor: .black))
                .onChange(of: runner.outputLines.count) {
                    if let last = runner.outputLines.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
    }

    private func lineColor(_ line: OutputLine) -> Color {
        if line.text.hasPrefix("$") { return .cyan }
        if line.text.hasPrefix("✅") { return .green }
        if line.text.hasPrefix("❌") || line.isError { return .red }
        if line.text.hasPrefix("⚠️") { return .yellow }
        return .white.opacity(0.85)
    }
}
