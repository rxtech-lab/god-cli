import ArgumentParser
import Foundation

func printInline(_ item: String) {
    if let data = item.data(using: .utf8) {
        FileHandle.standardOutput.write(data)
    }
}

@main
struct GodCommand: AsyncParsableCommand {
    @Argument(parsing: .remaining)
    var sentence: [String]

    mutating func run() async throws {
        // load the API key from the environment
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        let client = OpenAIClient(apiKey: apiKey)
        let fullSentence = sentence.joined(separator: " ")

        if fullSentence.isEmpty {
            print("Please provide an argument")
            return
        }

        for try await response in client.generateStreamResponse(prompt: fullSentence, model: .gpt4o) {
            // print the response in one line
            printInline(response)
        }
        print()
    }
}
