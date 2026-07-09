import Foundation

struct MDParser {
    static func parse(
        from url: URL,
        guideId: String? = nil,
        displayName: String? = nil
    ) throws -> Guide {
        let content = try String(contentsOf: url, encoding: .utf8)
        let document = parseDocument(from: content)
        let baseId = guideId ?? "file:\(url.standardizedFileURL.path)"
        let name = displayName ?? document.metadata["title"] ?? document.title ?? url.deletingPathExtension().lastPathComponent
        let sections = parseSections(from: document.body, baseId: baseId)
        return Guide(
            id: baseId,
            name: name,
            filePath: url.path,
            summary: document.metadata["summary"] ?? "",
            version: document.metadata["version"] ?? "",
            owner: document.metadata["owner"] ?? "",
            updated: document.metadata["updated"] ?? "",
            estimatedTime: document.metadata["estimated"] ?? document.metadata["estimated_time"] ?? "",
            sections: sections
        )
    }

    private static func parseSections(from content: String, baseId: String) -> [GuideSection] {
        var sections: [GuideSection] = []

        var currentSectionTitle: String? = nil
        var currentStepTitle: String? = nil
        var currentStepDesc: [String] = []
        var currentStepCommands: [Command] = []
        var currentSectionSteps: [Step] = []
        var sectionIndex = 0
        var stepIndex = 0
        var commandIndex = 0

        var inCodeBlock = false
        var codeBlockLines: [String] = []
        var inCommentBlock = false

        let lines = content.components(separatedBy: "\n")

        func flushCodeBlock() {
            let code = codeBlockLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !code.isEmpty {
                ensureCurrentStep()
                guard currentStepTitle != nil else { return }
                commandIndex += 1
                currentStepCommands.append(Command(id: makeId(baseId, "section", sectionIndex, "step", stepIndex, "command", commandIndex), text: code))
            }
            codeBlockLines = []
            inCodeBlock = false
        }

        func flushStep() {
            guard currentSectionTitle != nil, let title = currentStepTitle else { return }
            let desc = currentStepDesc.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let step = Step(
                id: makeId(baseId, "section", sectionIndex, "step", stepIndex, title),
                title: title,
                description: desc,
                commands: currentStepCommands
            )
            currentSectionSteps.append(step)
            currentStepTitle = nil
            currentStepDesc = []
            currentStepCommands = []
            commandIndex = 0
        }

        func flushSection() {
            guard let title = currentSectionTitle else { return }
            let section = GuideSection(
                id: makeId(baseId, "section", sectionIndex, title),
                title: title,
                steps: currentSectionSteps
            )
            sections.append(section)
            currentSectionTitle = nil
            currentSectionSteps = []
            stepIndex = 0
        }

        func ensureCurrentStep() {
            guard let sectionTitle = currentSectionTitle else { return }
            if currentStepTitle == nil {
                stepIndex += 1
                currentStepTitle = sectionTitle
            }
        }

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") {
                if inCodeBlock {
                    flushCodeBlock()
                } else {
                    inCodeBlock = true
                }
                continue
            }

            if inCodeBlock {
                codeBlockLines.append(line)
                continue
            }

            if inCommentBlock {
                if trimmedLine.contains("-->") {
                    inCommentBlock = false
                }
                continue
            }

            if trimmedLine.hasPrefix("<!--") {
                if !trimmedLine.contains("-->") {
                    inCommentBlock = true
                }
                continue
            }

            if line.hasPrefix("# ") && !line.hasPrefix("## ") {
                continue
            }

            if line.hasPrefix("## ") {
                flushStep()
                flushSection()
                sectionIndex += 1
                currentSectionTitle = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                continue
            }

            if line.hasPrefix("### ") {
                flushStep()
                guard currentSectionTitle != nil else { continue }
                stepIndex += 1
                currentStepTitle = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                continue
            }

            if currentSectionTitle != nil, !trimmedLine.isEmpty, trimmedLine != "---" {
                ensureCurrentStep()
                currentStepDesc.append(line)
            }
        }

        if inCodeBlock {
            flushCodeBlock()
        }
        flushStep()
        flushSection()
        return sections
    }

    private static func makeId(_ parts: Any...) -> String {
        parts.map { String(describing: $0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "::")
    }

    private static func parseDocument(from content: String) -> (metadata: [String: String], title: String?, body: String) {
        let (metadata, body) = splitFrontMatter(from: content)
        let title = body.components(separatedBy: "\n").first { line in
            line.hasPrefix("# ") && !line.hasPrefix("## ")
        }?.dropFirst(2).trimmingCharacters(in: .whitespaces)
        return (metadata, title, body)
    }

    private static func splitFrontMatter(from content: String) -> (metadata: [String: String], body: String) {
        guard content.hasPrefix("---") else {
            return ([:], content)
        }

        let lines = content.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return ([:], content)
        }

        var metadata: [String: String] = [:]
        var endIndex: Int?

        for index in lines.indices.dropFirst() {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                endIndex = index
                break
            }

            guard let separator = line.firstIndex(of: ":") else { continue }
            let key = line[..<separator]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let value = line[line.index(after: separator)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

            if !key.isEmpty {
                metadata[key] = value
            }
        }

        guard let endIndex else {
            return ([:], content)
        }

        let body = lines.dropFirst(endIndex + 1).joined(separator: "\n")
        return (metadata, body)
    }
}
