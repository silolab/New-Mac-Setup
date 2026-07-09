import SwiftUI

struct StepListView: View {
    let guide: Guide
    let section: GuideSection
    @ObservedObject var guideStore: GuideStore
    @ObservedObject var runner: CommandRunner

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                GuideSummaryHeader(guide: guide)
                SectionProgressHeader(section: section, guideStore: guideStore)

                ForEach(section.steps) { step in
                    StepCard(step: step, guideStore: guideStore, runner: runner)
                }
            }
            .padding()
        }
        .navigationTitle(section.title)
    }
}

private struct GuideSummaryHeader: View {
    let guide: Guide

    private var chips: [(String, String)] {
        [
            ("버전", guide.version),
            ("담당", guide.owner),
            ("업데이트", guide.updated),
            ("예상", guide.estimatedTime)
        ].filter { !$0.1.isEmpty }
    }

    var body: some View {
        if !guide.summary.isEmpty || !chips.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if !guide.summary.isEmpty {
                    Text(guide.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !chips.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(chips, id: \.0) { label, value in
                            Label("\(label) \(value)", systemImage: chipIcon(for: label))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func chipIcon(for label: String) -> String {
        switch label {
        case "버전": return "number"
        case "담당": return "person"
        case "업데이트": return "calendar"
        case "예상": return "clock"
        default: return "info.circle"
        }
    }
}

private struct SectionProgressHeader: View {
    let section: GuideSection
    @ObservedObject var guideStore: GuideStore

    private var completed: Int { guideStore.completedCount(in: section) }
    private var total: Int { section.steps.count }
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("진행률")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(completed)/\(total) 완료")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .controlSize(.small)
        }
        .padding(.bottom, 2)
    }
}

private struct StepCard: View {
    let step: Step
    @ObservedObject var guideStore: GuideStore
    @ObservedObject var runner: CommandRunner

    var isCompleted: Bool { guideStore.isCompleted(stepId: step.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(action: { guideStore.toggleCompleted(stepId: step.id) }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCompleted ? .green : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Text(step.title)
                    .font(.title3)
                    .strikethrough(isCompleted, color: .secondary)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
            }

            if !step.description.isEmpty {
                MarkdownDescription(text: step.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !step.commands.isEmpty {
                VStack(spacing: 8) {
                    ForEach(step.commands) { cmd in
                        CommandRowView(command: cmd, runner: runner)
                    }
                }
            }
        }
        .padding(12)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct MarkdownDescription: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let text):
                    RichMarkdownText(text: text)
                case .callout(let callout):
                    CalloutView(callout: callout)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var blocks: [DescriptionBlock] {
        DescriptionBlock.parse(text)
    }
}

private struct RichMarkdownText: View {
    let text: String

    var body: some View {
        Text(attributedText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributedText: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        var result = AttributedString()
        var remainder = text[...]
        let tokenPattern = #"\{\{(red|danger):(.+?)\}\}"#

        while let range = remainder.range(of: tokenPattern, options: .regularExpression) {
            let prefix = String(remainder[..<range.lowerBound])
            result.append(markdown(prefix, options: options))

            let token = String(remainder[range])
            let content = token
                .replacingOccurrences(of: #"^\{\{(red|danger):"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\}\}$"#, with: "", options: .regularExpression)

            var highlighted = markdown(content, options: options)
            highlighted.foregroundColor = .red
            highlighted.font = .body.bold()
            result.append(highlighted)

            remainder = remainder[range.upperBound...]
        }

        result.append(markdown(String(remainder), options: options))
        return result
    }

    private func markdown(_ text: String, options: AttributedString.MarkdownParsingOptions) -> AttributedString {
        (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

private struct CalloutView: View {
    let callout: Callout

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: callout.kind.icon)
                .foregroundStyle(callout.kind.tint)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(callout.kind.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(callout.kind.tint)
                RichMarkdownText(text: callout.text)
                    .font(.callout)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(callout.kind.tint.opacity(0.10))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(callout.kind.tint)
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private enum DescriptionBlock {
    case text(String)
    case callout(Callout)

    static func parse(_ text: String) -> [DescriptionBlock] {
        var blocks: [DescriptionBlock] = []
        var textBuffer: [String] = []
        var activeCallout: (kind: CalloutKind, lines: [String])?

        func flushText() {
            let body = textBuffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty {
                blocks.append(.text(body))
            }
            textBuffer = []
        }

        func flushCallout() {
            guard let callout = activeCallout else { return }
            let body = callout.lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            blocks.append(.callout(Callout(kind: callout.kind, text: body)))
            activeCallout = nil
        }

        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if let kind = CalloutKind(markerLine: trimmed) {
                flushText()
                flushCallout()
                activeCallout = (kind, [])
                continue
            }

            if trimmed.hasPrefix(">") {
                let content = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                if var callout = activeCallout {
                    callout.lines.append(content)
                    activeCallout = callout
                } else {
                    textBuffer.append(content)
                }
                continue
            }

            if activeCallout != nil {
                flushCallout()
            }
            textBuffer.append(line)
        }

        flushCallout()
        flushText()
        return blocks
    }
}

private struct Callout {
    let kind: CalloutKind
    let text: String
}

private enum CalloutKind: String {
    case note
    case tip
    case important
    case warning
    case danger

    init?(markerLine: String) {
        guard markerLine.hasPrefix("> [!"), markerLine.hasSuffix("]") else { return nil }
        let marker = markerLine
            .replacingOccurrences(of: "> [!", with: "")
            .replacingOccurrences(of: "]", with: "")
            .lowercased()
        self.init(rawValue: marker)
    }

    var title: String {
        switch self {
        case .note: return "안내"
        case .tip: return "팁"
        case .important: return "중요"
        case .warning: return "주의"
        case .danger: return "위험"
        }
    }

    var icon: String {
        switch self {
        case .note: return "info.circle"
        case .tip: return "lightbulb"
        case .important: return "star.circle"
        case .warning: return "exclamationmark.triangle"
        case .danger: return "xmark.octagon"
        }
    }

    var tint: Color {
        switch self {
        case .note: return .blue
        case .tip: return .green
        case .important: return .purple
        case .warning: return .orange
        case .danger: return .red
        }
    }
}
