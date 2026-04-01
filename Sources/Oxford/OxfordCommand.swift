import ArgumentParser
import Foundation
import OxfordKit

@main
struct OxfordCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "oxford",
        abstract: "Look up words in the New Oxford American Dictionary and Oxford American Writer's Thesaurus.",
        version: "0.1.0"
    )

    @Argument(help: "The word to look up.")
    var word: String

    @Flag(name: [.customShort("t"), .long], help: "Show the thesaurus entry instead of the definition.")
    var thesaurus = false

    func run() throws {
        let result = lookUpWord(word)
        let formatter = OutputFormatter()

        if thesaurus {
            guard let th = result.thesaurus else {
                throw ExitCode(1, message: "No thesaurus entry found for '\(word)'.")
            }
            print(formatter.formatThesaurus(th))
        } else {
            guard let def = result.definition else {
                throw ExitCode(1, message: "No definition found for '\(word)'.")
            }
            print(formatter.formatDefinition(def))
        }
    }
}

private extension ExitCode {
    init(_ code: Int32, message: String) {
        FileHandle.standardError.write(Data("Error: \(message)\n".utf8))
        self.init(rawValue: code)
    }
}
