import SwiftUI
import AppKit

struct GuideSidebarView: View {
    @ObservedObject var guideStore: GuideStore

    var body: some View {
        List(selection: $guideStore.selectedSectionId) {
            if guideStore.guides.isEmpty {
                ContentUnavailableView(
                    "가이드 없음",
                    systemImage: "doc.text",
                    description: Text("+ 버튼으로 마크다운 파일을 추가하세요")
                )
            }

            ForEach(guideStore.guides) { guide in
                Section {
                    ForEach(guide.sections) { section in
                        SectionRow(section: section, guide: guide, guideStore: guideStore)
                            .tag(section.id)
                    }
                } header: {
                    GuideHeader(guide: guide, guideStore: guideStore)
                }
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            urls.forEach { guideStore.addGuide(from: $0) }
            return true
        }
        .navigationTitle("MacSetup")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    if let guide = guideStore.selectedGuide {
                        GuideDialogs.confirmRemove(guide, guideStore: guideStore)
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(!guideStore.canRemoveSelectedGuide)
                .help("선택한 가져온 가이드 제거")

                Button(action: guideStore.addGuide) {
                    Image(systemName: "plus")
                }
                .help("가이드 파일 추가 (.md)")
            }
        }
    }
}

private struct GuideHeader: View {
    let guide: Guide
    @ObservedObject var guideStore: GuideStore

    private var completed: Int { guideStore.completedCount(in: guide) }
    private var total: Int { guideStore.totalStepCount(in: guide) }
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(guide.name)
                    .font(.subheadline.weight(.semibold))
                    .textCase(nil)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Button {
                    confirmReset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("이 가이드의 완료 체크 초기화")

                if !guide.isBundled {
                    Button(role: .destructive) {
                        GuideDialogs.confirmRemove(guide, guideStore: guideStore)
                    } label: {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("가이드 제거")
                }
            }

            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .controlSize(.small)
                Text("\(completed)/\(total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func confirmReset() {
        GuideDialogs.confirmReset(guide, guideStore: guideStore)
    }
}

@MainActor
private enum GuideDialogs {
    static func confirmReset(_ guide: Guide, guideStore: GuideStore) {
        let alert = NSAlert()
        alert.messageText = "\(guide.name) 완료 기록을 초기화할까요?"
        alert.informativeText = "체크한 단계만 초기화되고 가이드 파일은 유지됩니다."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "초기화")
        alert.addButton(withTitle: "취소")

        if alert.runModal() == .alertFirstButtonReturn {
            guideStore.resetCompletion(for: guide)
        }
    }

    static func confirmRemove(_ guide: Guide, guideStore: GuideStore) {
        guard !guide.isBundled else { return }

        let alert = NSAlert()
        alert.messageText = "\(guide.name) 가이드를 제거할까요?"
        alert.informativeText = "앱 목록에서만 제거되며 원본 Markdown 파일은 삭제되지 않습니다."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "제거")
        alert.addButton(withTitle: "취소")

        if alert.runModal() == .alertFirstButtonReturn {
            guideStore.removeGuide(guide)
        }
    }
}

private struct SectionRow: View {
    let section: GuideSection
    let guide: Guide
    @ObservedObject var guideStore: GuideStore

    var completed: Int { guideStore.completedCount(in: section) }
    var total: Int { section.steps.count }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.body)
                    .lineLimit(2)
                if total > 0 {
                    Text("\(completed)/\(total) 완료")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if completed == total && total > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                GuideDialogs.confirmReset(guide, guideStore: guideStore)
            } label: {
                Label("완료 체크 초기화", systemImage: "arrow.counterclockwise")
            }

            if !guide.isBundled {
                Button(role: .destructive) {
                    GuideDialogs.confirmRemove(guide, guideStore: guideStore)
                } label: {
                    Label("가이드 제거", systemImage: "trash")
                }
            }
        }
    }
}
