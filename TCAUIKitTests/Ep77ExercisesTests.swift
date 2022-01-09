import XCTest

final class Ep77ExercisesTests: XCTestCase {
    func testQ1() throws {
        throw XCTSkip(
            #"""

            Q1. Add support for tracking the “last saved at” date on the favorite primes screen.

            Q2. Introduce UI that displays this “last saved at” date on the favorite primes screen.

            Q3. Add error handling to the load favorite primes effect. A failure to load some favorite primes is currently ignored. This means that if a user has never saved any favorite primes, an attempt to load some favorite primes will fail silently. Instead, it would be nice to present a friendly alert to the end user on failure.

            Update the favorite primes action, state, reducer, and view accordingly to support this feature.

            Q4. Incorporate the side effect of asking Wolfram Alpha for the “nth” prime into the counter reducer.

            In order to do so without further changing the shape of Effect, you may need to introduce some logic to make the asynchronous nature of this effect synchronous, which is something we’ve previously covered in our episode on Async Functional Refactoring.

            What kinds of problems does this solution introduce to the application?

            Q5. In the past on Point-Free, we have modeled asynchrony with the Parallel type, which is defined as follows:
            ```swift
            struct Parallel<A> {
              let run: (@escaping (A) -> Void) -> Void
            }
            ```
            Update Effect to have the same shape and explore how it affects the architecture and the “nth prime” effect.
            """#
        )
    }
}
