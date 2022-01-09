import XCTest

final class Ep73ExercisesTestsTests: XCTestCase {
    func testQ1() throws {
        throw XCTSkip("""
        Another way to isolate code is to move it to its own file and mark part of it private or fileprivate. How does this kind of modularization differ from using an actual Swift module?
        skip, dup for ep72 Q4
        """)
    }

    func testQ2() throws {
        class Lazy<A> {
            internal init(run factory: @escaping () -> A) {
                var cache: A?
                run = {
                    [factory] in
                    if let cache = cache { return cache }
                    cache = factory()
                    return cache!
                }
            }

            let run: () -> A
            func map<B>(_ f: @escaping (A) -> B) -> Lazy<B> {
                Lazy<B> {
                    f(self.run())
                }
            }
        }

        let slow = Lazy<Int> {
            usleep(100_000)
            return 1
        }
        let start = CFAbsoluteTimeGetCurrent()
        _ = slow.run() // Returns `1` after a second
        let ph1 = CFAbsoluteTimeGetCurrent()
        _ = slow.run() // Returns `1` immediately
        let ph2 = CFAbsoluteTimeGetCurrent()
        XCTAssertEqual(ph1 - start, 0.1, accuracy: 0.005)
        XCTAssertEqual(ph2 - ph1, 0, accuracy: 0.05)
        let stringSlow = slow.map(\.description)
        _ = stringSlow.run()
        let ph3 = CFAbsoluteTimeGetCurrent()
        XCTAssertEqual(ph3 - ph2, 0.0, accuracy: 0.05)
        throw XCTSkip(
            """
            Skip: did not know the answer.
            Q:Given our discussion around map on the Store type, is it appropriate to call this function map?
            """)
    }

    func testQ3() throws {
        throw XCTSkip(
            """
            Skip for can understand the question
            Q:Sometimes it can be useful to view into a store so that it removes all access to the underlying state of the store. For example, a “debug” screen for your app could have a UI for listing out every single action in your application as buttons, and tapping the button will send the action to the store. Such a screen doesn’t need any access to the app state.

            Try building such a screen, and provide it view of the store that removes all access to the underlying app state.
            """
        )
    }

    func testQ4() throws {
        throw XCTSkip(
            """
            Answer in the next episode.
            Q:Write a function that transforms a Store<GlobalValue, GlobalAction> into a Store<GlobalValue, LocalAction>. That is, a function of the following signature:
            ```swift
            extension Store {
              func view<LocalAction>(
                /* what arguments are needed? */
                ) -> Store<Value, LocalAction> {

                fatalError("Unimplemented")
              }
            }
            ```
            What kind of data does the function need to be supplied with in addition to a store? Is this kind of transformation familiar? Does it have a name we’ve used before on Point-Free?
            """)
    }
}
