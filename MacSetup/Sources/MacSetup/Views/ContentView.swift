import SwiftUI

struct ContentView: View {
    @StateObject private var guideStore = GuideStore()
    @StateObject private var runner = CommandRunner()

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            GuideSidebarView(guideStore: guideStore)
        } content: {
            if guideStore.guides.isEmpty {
                ContentUnavailableView(
                    "Markdown 가이드를 추가하세요",
                    systemImage: "doc.badge.plus",
                    description: Text("파일을 이 창에 드래그앤드롭하거나 사이드바의 + 버튼으로 선택하세요")
                )
            } else if let guide = guideStore.selectedGuide, let section = guideStore.selectedSection {
                StepListView(guide: guide, section: section, guideStore: guideStore, runner: runner)
            } else {
                ContentUnavailableView(
                    "섹션을 선택하세요",
                    systemImage: "sidebar.left",
                    description: Text("왼쪽에서 가이드 섹션을 선택하면 명령어가 표시됩니다")
                )
            }
        } detail: {
            TerminalOutputView(runner: runner)
        }
        .navigationSplitViewStyle(.balanced)
        .dropDestination(for: URL.self) { urls, _ in
            urls.forEach { guideStore.addGuide(from: $0) }
            return true
        }
        .onAppear {
            guideStore.loadSavedGuides()
        }
    }
}
