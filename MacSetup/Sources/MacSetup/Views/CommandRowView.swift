import SwiftUI
import AppKit

struct CommandRowView: View {
    let command: Command
    @ObservedObject var runner: CommandRunner
    @State private var editableCommand: String
    @State private var copied = false

    init(command: Command, runner: CommandRunner) {
        self.command = command
        self.runner = runner
        _editableCommand = State(initialValue: command.text)
    }

    private var safety: CommandSafety {
        CommandSafety.evaluate(currentCommand)
    }

    private var currentCommand: String {
        editableCommand.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEdited: Bool {
        editableCommand != command.text
    }

    private var resultKey: String {
        "\(command.id)::\(currentCommand)"
    }

    private var editorHeight: CGFloat {
        let lineCount = max(3, editableCommand.components(separatedBy: .newlines).count)
        return CGFloat(min(lineCount, 8)) * 18 + 24
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                TextEditor(text: $editableCommand)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .frame(minHeight: editorHeight, maxHeight: max(editorHeight, 180))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isEdited ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
                    }

                VStack(spacing: 4) {
                    Button(action: copyCommand) {
                        Label(copied ? "복사됨" : "복사", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.subheadline)
                            .frame(width: 70)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(copied ? .green : .secondary)

                    Button(action: runCommand) {
                        Label("실행", systemImage: "play.fill")
                            .font(.subheadline)
                            .frame(width: 70)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    .disabled(runner.isRunning || currentCommand.isEmpty || !safety.canRunInline)
                    .help(safety.runHelp)

                    if let success = runner.commandResults[resultKey] {
                        Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(success ? .green : .red)
                            .font(.title3)
                            .help(success ? "성공 (exit 0)" : "실패 - 터미널 출력 확인")
                    }

                    Button(action: openInTerminal) {
                        Label("터미널", systemImage: "terminal")
                            .font(.subheadline)
                            .frame(width: 70)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(currentCommand.isEmpty || safety.requiresEditing)
                    .help(safety.terminalHelp)

                    if isEdited {
                        Button(action: resetCommand) {
                            Label("원본", systemImage: "arrow.uturn.backward")
                                .font(.subheadline)
                                .frame(width: 70)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .help("원래 명령어로 되돌리기")
                    }
                }
            }

            if let note = safety.note {
                Label(note, systemImage: safety.systemImage)
                    .font(.caption)
                    .foregroundStyle(safety.noteColor)
                    .labelStyle(.titleAndIcon)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentCommand, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = false
        }
    }

    private func runCommand() {
        runner.run(command: currentCommand, commandId: resultKey)
    }

    private func openInTerminal() {
        runner.openInTerminal(command: currentCommand)
    }

    private func resetCommand() {
        editableCommand = command.text
    }
}

private struct CommandSafety {
    let canRunInline: Bool
    let requiresEditing: Bool
    let note: String?
    let systemImage: String
    let noteColor: Color

    var runHelp: String {
        if requiresEditing {
            return "명령어 칸에서 YOUR_NAME, YOUR_EMAIL 같은 값을 직접 바꾼 뒤 실행하세요"
        }
        if !canRunInline {
            return "이 명령어는 Terminal.app에서 실행하는 편이 안전합니다"
        }
        return "앱에서 명령어 실행"
    }

    var terminalHelp: String {
        requiresEditing ? "명령어 칸에서 값을 먼저 수정한 뒤 터미널에서 실행하세요" : "Terminal.app에서 실행"
    }

    static func evaluate(_ command: String) -> CommandSafety {
        let normalized = command.lowercased()
        let requiresEditing = command.contains("YOUR_")
        let terminalPreferred = [
            "claude login",
            "ssh -t ",
            "ssh -T ".lowercased(),
            "git clone "
        ].contains { normalized.contains($0.lowercased()) }

        if requiresEditing {
            return CommandSafety(
                canRunInline: false,
                requiresEditing: true,
                note: "명령어 칸에서 개인 값으로 직접 수정한 뒤 실행하세요.",
                systemImage: "pencil",
                noteColor: .orange
            )
        }

        if terminalPreferred {
            return CommandSafety(
                canRunInline: false,
                requiresEditing: false,
                note: "로그인, 인증, 긴 다운로드가 포함될 수 있어 Terminal 실행을 권장합니다.",
                systemImage: "terminal",
                noteColor: .secondary
            )
        }

        return CommandSafety(
            canRunInline: true,
            requiresEditing: false,
            note: nil,
            systemImage: "checkmark.circle",
            noteColor: .secondary
        )
    }
}
