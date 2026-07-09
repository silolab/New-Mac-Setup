import SwiftUI

struct ContentView: View {
    @StateObject private var guideStore = GuideStore()
    @StateObject private var runner = CommandRunner()

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            GuideSidebarView(guideStore: guideStore)
        } content: {
            if let guide = guideStore.selectedGuide, let section = guideStore.selectedSection {
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
        .onAppear {
            guideStore.loadSavedGuides()
        }
    }
}
