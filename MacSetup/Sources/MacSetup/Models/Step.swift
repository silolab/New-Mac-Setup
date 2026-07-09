import Foundation

struct Step: Identifiable {
    let id: String
    var title: String
    var description: String
    var commands: [Command]

    init(id: String, title: String, description: String = "", commands: [Command] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.commands = commands
    }
}

struct Command: Identifiable {
    let id: String
    var text: String

    init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}
