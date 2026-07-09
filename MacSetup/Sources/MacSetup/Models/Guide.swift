import Foundation

struct Guide: Identifiable {
    let id: String
    var name: String
    var filePath: String
    var isBundled: Bool
    var summary: String
    var version: String
    var owner: String
    var updated: String
    var estimatedTime: String
    var sections: [GuideSection]

    init(
        id: String,
        name: String,
        filePath: String,
        isBundled: Bool = false,
        summary: String = "",
        version: String = "",
        owner: String = "",
        updated: String = "",
        estimatedTime: String = "",
        sections: [GuideSection] = []
    ) {
        self.id = id
        self.name = name
        self.filePath = filePath
        self.isBundled = isBundled
        self.summary = summary
        self.version = version
        self.owner = owner
        self.updated = updated
        self.estimatedTime = estimatedTime
        self.sections = sections
    }
}
