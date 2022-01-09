import XCTest

final class Ep76ExercisesTests: XCTestCase {
    func testQ1() throws {
        throw XCTSkip("")
    }

    func testQ2() throws {
        throw XCTSkip("""
        Q: If instead of allowing effects to mutate state directly, what if we wanted to allow effects to send actions to the store? How could the definition of Effect be changed to allow this?
        """)
    }

    func testQ3() throws {
        throw XCTSkip(
            """
            Q: Not every reducer needs to perform side effects. Write a function that can lift any side-effectless reducer into a signature that supports side effects. Such a function would have the following signature:

            typealias Effect = () -> Void
            typealias Reducer<State, Action> = (inout State, Action) -> Effect

            ```swift
            func pure<State, Action>(
              _ reducer: (inout State, Action) -> Void
            ) -> Reducer<State, Action> {
              fatalError("Unimplemented")
            }
            ```
            """)
    }
}
