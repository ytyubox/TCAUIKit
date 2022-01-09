import XCTest

func explainInNextEpisode(Q: String, file: StaticString = #filePath, line: UInt = #line) throws {
    throw XCTSkip(
        """
skip for explain in the next episode
Q: \(Q)
""", file: file, line: line
    )
}

