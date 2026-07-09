import Foundation

struct GuideSection: Identifiable {
    let id: String
    var title: String
    var steps: [Step]

    init(id: String, title: String, steps: [Step] = []) {
        self.id = id
        self.title = title
        self.steps = steps
    }
}
