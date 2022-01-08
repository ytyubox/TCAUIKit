import XCTest

final class Ep69ExercisesTests: XCTestCase {
    func testQ1() throws {
        throw XCTSkip(
            #"""
            reducer.pullbark(\.self)
            which keyPath type is WritableKeypath<Root, Root>
            """#
        )
    }

    func testQ2() throws {
        throw XCTSkip(
            """
            FavoritePrimeState can be a typealias, for now
            So far no other part of code need to change
            However, if need to compare the FavoritePrimeState, it need to extra the tuple using `(_, _) = favoritePrimeState` to get each value and compare.
            Although it is not bad, we still painless to translate tuple typealias back to struct.
            """
        )
    }

    func testQ3() throws {
        throw XCTSkip(
            """
            To pullback from a Global action to localAction, it only need a getter that get the localAction if can.
            which can be `KeyPath<GlobalAction, LocalAction?>
            """)
    }

    func testQ4() throws {
        throw XCTSkip("""
        it is in the next episode that is so called `view`?
        """)
    }

    func testQ5() throws {
        throw XCTSkip("""
        yet to understand
        """)
    }

    func testQ6() throws {
        throw XCTSkip("""
        yet to understand
        """)
    }
}
