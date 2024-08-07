struct Configuration: Codable {
    /**
     * The input configuration.
     */
    var input: InputConfiguration
    /**
     * The output configuration.
     */
    var output: OutputConfiguration
}

struct InputConfiguration: Codable {
    /**
     * Patterns to match files that should be included.
     */
    var patterns: [String]?
    /**
     * Patterns to match files that should be ignored.
     */
    var ignore: [String]?
}

struct OutputConfiguration: Codable {
    /**
     * The files that match the patterns.
     */
    var file: String
    var commentSymbol: String

    enum CodingKeys: String, CodingKey {
        case file
        case commentSymbol = "comment_symbol"
    }
}
