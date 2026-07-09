import Foundation
import AppKit

struct OutputLine: Identifiable {
    let id = UUID()
    let text: String
    let isError: Bool
}

@MainActor
class CommandRunner: ObservableObject {
    @Published var outputLines: [OutputLine] = []
    @Published var isRunning = false
    @Published var commandResults: [String: Bool] = [:]

    private var currentProcess: Process?

    func run(command: String, commandId: String) {
        guard !isRunning else { return }

        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        append("$ \(trimmed)", isError: false)

        if requiresAdmin(command: trimmed) {
            runWithAdmin(command: trimmed, commandId: commandId)
        } else {
            runNormal(command: trimmed, commandId: commandId)
        }
    }

    func openInTerminal(command: String) {
        let appleScript = """
        on run argv
        set commandText to item 1 of argv
        tell application "Terminal"
            activate
            do script commandText
        end tell
        end run
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript, command]
        do {
            try process.run()
            append("↗ Terminal.app에서 실행 중", isError: false)
        } catch {
            append("❌ Terminal 열기 실패: \(error.localizedDescription)", isError: true)
        }
    }

    func clear() {
        outputLines = []
    }

    // MARK: - Private

    private func runNormal(command: String, commandId: String) {
        isRunning = true

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.appendMultiline(text, isError: false)
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.appendMultiline(text, isError: true)
            }
        }

        process.terminationHandler = { [weak self] proc in
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            let status = proc.terminationStatus
            DispatchQueue.main.async {
                self?.append(status == 0 ? "✅ 완료 (exit 0)" : "❌ 실패 (exit \(status))", isError: status != 0)
                self?.commandResults[commandId] = (status == 0)
                self?.isRunning = false
            }
        }

        do {
            try process.run()
            currentProcess = process
        } catch {
            append("오류: \(error.localizedDescription)", isError: true)
            isRunning = false
        }
    }

    private func runWithAdmin(command: String, commandId: String) {
        isRunning = true
        append("⚠️ 관리자 권한 명령어 — 시스템 암호 입력 대화상자가 표시됩니다", isError: false)

        let adminCommand = commandWithoutSudoPrefixes(command)
        let appleScript = """
        on run argv
        set commandText to item 1 of argv
        do shell script "/bin/zsh -lc " & quoted form of commandText with administrator privileges
        end run
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript, adminCommand]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.appendMultiline(text, isError: false)
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.appendMultiline(text, isError: true)
            }
        }

        process.terminationHandler = { [weak self] proc in
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            let status = proc.terminationStatus
            DispatchQueue.main.async {
                self?.append(status == 0 ? "✅ 완료 (exit 0)" : "❌ 실패 (exit \(status))", isError: status != 0)
                self?.commandResults[commandId] = (status == 0)
                self?.isRunning = false
            }
        }

        do {
            try process.run()
            currentProcess = process
        } catch {
            append("오류: \(error.localizedDescription)", isError: true)
            commandResults[commandId] = false
            isRunning = false
        }
    }

    private func append(_ text: String, isError: Bool) {
        outputLines.append(OutputLine(text: text, isError: isError))
    }

    private func appendMultiline(_ text: String, isError: Bool) {
        let cleaned = text.hasSuffix("\n") ? String(text.dropLast()) : text
        for line in cleaned.components(separatedBy: "\n") {
            outputLines.append(OutputLine(text: line, isError: isError))
        }
    }

    private func requiresAdmin(command: String) -> Bool {
        command.components(separatedBy: .newlines).contains { line in
            line.trimmingCharacters(in: .whitespaces).hasPrefix("sudo ")
        }
    }

    private func commandWithoutSudoPrefixes(_ command: String) -> String {
        command.components(separatedBy: .newlines).map { line in
            let leadingWhitespace = line.prefix { $0 == " " || $0 == "\t" }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("sudo ") {
                return String(leadingWhitespace) + String(trimmed.dropFirst(5))
            }
            return line
        }
        .joined(separator: "\n")
    }
}
