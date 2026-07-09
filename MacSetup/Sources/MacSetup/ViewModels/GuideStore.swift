import Foundation
import AppKit

@MainActor
class GuideStore: ObservableObject {
    @Published var guides: [Guide] = []
    @Published var selectedSectionId: String? = nil

    private let guidePathsKey = "savedGuidePaths"
    private let completedStepsKey = "completedSteps"
    private let bundledGuideId = "bundled:sample-mac-setup-guide"

    var selectedGuide: Guide? {
        guides.first { guide in
            guide.sections.contains { $0.id == selectedSectionId }
        }
    }

    var selectedSection: GuideSection? {
        selectedGuide?.sections.first { $0.id == selectedSectionId }
    }

    // MARK: - Load / Save

    func loadSavedGuides() {
        let paths = UserDefaults.standard.stringArray(forKey: guidePathsKey) ?? []
        let savedGuides = paths.compactMap { path in
            let url = URL(fileURLWithPath: path)
            return try? MDParser.parse(from: url)
        }
        guides = ([loadBundledGuide()].compactMap { $0 } + savedGuides).uniquedByPath()
        selectFirstAvailableSectionIfNeeded()
    }

    func addGuide() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.init(filenameExtension: "md")].compactMap { $0 }
        panel.title = "마크다운 가이드 파일 선택"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let guide = try? MDParser.parse(from: url) else { return }

        // Avoid duplicates
        guard !guides.contains(where: { $0.filePath == url.path }) else { return }

        guides.append(guide)
        saveGuidePaths()
        selectedSectionId = guide.sections.first?.id
    }

    func addGuide(from url: URL) {
        guard url.pathExtension == "md" else { return }
        guard !guides.contains(where: { $0.filePath == url.path }) else { return }
        guard let guide = try? MDParser.parse(from: url) else { return }
        guides.append(guide)
        saveGuidePaths()
        selectedSectionId = guide.sections.first?.id
    }

    func removeGuide(_ guide: Guide) {
        guard !guide.isBundled else { return }
        guides.removeAll { $0.id == guide.id }
        if selectedGuide == nil { selectedSectionId = nil }
        saveGuidePaths()
        selectFirstAvailableSectionIfNeeded()
    }

    // MARK: - Completion Tracking

    func isCompleted(stepId: String) -> Bool {
        let completed = UserDefaults.standard.stringArray(forKey: completedStepsKey) ?? []
        return completed.contains(stepId)
    }

    func toggleCompleted(stepId: String) {
        var completed = UserDefaults.standard.stringArray(forKey: completedStepsKey) ?? []
        if let idx = completed.firstIndex(of: stepId) {
            completed.remove(at: idx)
        } else {
            completed.append(stepId)
        }
        UserDefaults.standard.set(completed, forKey: completedStepsKey)
        objectWillChange.send()
    }

    func completedCount(in section: GuideSection) -> Int {
        section.steps.filter { isCompleted(stepId: $0.id) }.count
    }

    func completedCount(in guide: Guide) -> Int {
        guide.sections.reduce(0) { $0 + completedCount(in: $1) }
    }

    func totalStepCount(in guide: Guide) -> Int {
        guide.sections.reduce(0) { $0 + $1.steps.count }
    }

    func resetCompletion(for guide: Guide) {
        let stepIds = Set(guide.sections.flatMap { $0.steps.map(\.id) })
        var completed = UserDefaults.standard.stringArray(forKey: completedStepsKey) ?? []
        completed.removeAll { stepIds.contains($0) }
        UserDefaults.standard.set(completed, forKey: completedStepsKey)
        objectWillChange.send()
    }

    // MARK: - Private

    private func loadBundledGuide() -> Guide? {
        guard let url = Bundle.main.url(forResource: "DefaultMacSetupGuide", withExtension: "md") else {
            return nil
        }

        return try? MDParser.parse(
            from: url,
            guideId: bundledGuideId,
            displayName: nil,
            isBundled: true
        )
    }

    private func selectFirstAvailableSectionIfNeeded() {
        let hasSelectedSection = guides.contains { guide in
            guide.sections.contains { $0.id == selectedSectionId }
        }
        if !hasSelectedSection {
            selectedSectionId = guides.first?.sections.first?.id
        }
    }

    private func saveGuidePaths() {
        let paths = guides.filter { !$0.isBundled }.map { $0.filePath }
        UserDefaults.standard.set(paths, forKey: guidePathsKey)
    }
}

private extension Array where Element == Guide {
    func uniquedByPath() -> [Guide] {
        var seen = Set<String>()
        return filter { guide in
            guard !seen.contains(guide.filePath) else { return false }
            seen.insert(guide.filePath)
            return true
        }
    }
}
