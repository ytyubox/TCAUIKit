import XCTest

final class Ep74ExercisesTestsTests: XCTestCase {
    func testQ1() throws {
        try explainInNextEpisode(Q: """
        skip for explain in the next episode
        Q: It can be useful to produce “read-only” stores that cannot send any actions. Write a view that transforms a store that can perform actions into a store that cannot perform actions. What is the appropriate data type to describe the Action of such a store?

        In our second episode on algebraic data types, we explored such a transformation.
        """)
    }

    func testQ2() throws {
        try explainInNextEpisode(Q: """
        skip for explain in the next episode
        Q:In our first episode on algebraic data types, we introduced the Either type, which is the most generic, non-trivial enum one could make:

        ```swift
        enum Either<A, B> {
          case left(A)
          case right(B)
        }
        ```
        In this episode we create a wrapper enum called CounterViewAction to limit the counter view’s ability to send any app action. Instead of introducing an ad hoc enum, refactor things to utilize the Either type.

        How does this compare to utilizing structs and tuples for intermediate state?
        """)
    }
}
