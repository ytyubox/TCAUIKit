import ComposableArchitecture
@testable import TCAUIKit
import XCTest

final class Ep72ExercisesTests: XCTestCase {
    func testQ1() throws {
        struct TestTarget {
            var inner = Inner()
            struct Inner {
                var string = ""
                var value = 0
            }
        }
        let store: Store<TestTarget, String> = Store(initialValue: TestTarget()) { value, action in
            value.inner.value = Int(action) ?? 0
            value.inner.string = String(action)
            return {}
        }
        let stringStore = store.view(value: \.inner.string,
                                     action: { $0 })
        stringStore.send("123")
        XCTAssertEqual(store.value.inner.string, "123")
        XCTAssertEqual(store.value.inner.value, 123)
    }

    func testQ2WithMineStatePublisher() throws {
        struct TestTarget {
            var inner = Inner()
            struct Inner {
                var string = "0"
                var value = 0
            }
        }
        let store: Store<State<TestTarget>, String> = Store(
            initialValue: .hot(TestTarget())
        ) { value, action in

            value.inner = .init(string: String(action),
                                value: Int(action) ?? 0)
            return {}
        }
        let stringStore: Store<State<String>, String> = store.view(
            value: \.inner.string,
            action: { $0 }
        )
        var history: [String] = []
        let cancelable = stringStore.value.publisher.sink {
            history.append($0)
        }
        stringStore.send("123")
        XCTAssertEqual(store.value.inner.string, "123")
        XCTAssertEqual(store.value.inner.value, 123)
        XCTAssertEqual(history, ["0", "123"])
        stringStore.send("notInt")
        XCTAssertEqual(store.value.inner.string, "notInt")
        XCTAssertEqual(store.value.inner.value, 0)
        XCTAssertEqual(history, ["0", "123", "notInt"])
        cancelable.cancel()
    }

    func testQ2WithMineStatePublisherByView() throws {
        struct TestTarget {
            var inner = Inner()
            struct Inner {
                var string = "0"
                var value = 0
            }
        }
        let store: Store<State<TestTarget>, String> = Store(
            initialValue: .hot(TestTarget())
        ) { value, action in

            value.inner = .init(string: String(action),
                                value: Int(action) ?? 0)
            return {}
        }
        let stringStore: Store<State<String>, String> = store.view(
            value: \.inner.string,
            action: { $0 }
        )
        var history: [String] = []
        let cancelable = stringStore.value.publisher.sink {
            history.append($0)
        }
        stringStore.send("123")
        XCTAssertEqual(store.value.inner.string, "123")
        XCTAssertEqual(store.value.inner.value, 123)
        XCTAssertEqual(history, ["0", "123"])
        stringStore.send("notInt")
        XCTAssertEqual(store.value.inner.string, "notInt")
        XCTAssertEqual(store.value.inner.value, 0)
        XCTAssertEqual(history, ["0", "123", "notInt"])
        cancelable.cancel()
    }

    func testQ4() throws {
        throw XCTSkip(
            """
            Skipped, but it is a good question, even can be interview question.
            Q: How do internal, private, and fileprivate access control isolate code? What are the benefits of each scope? How does this isolation differ from module boundaries?
            """
        )
    }

    func testQ5() throws {
        throw XCTSkip("""
        Skipped, dont know the answer.
        Q: Try converting PrimeModalState to a protocol that exposes only the fields of AppState that it cares about, and fix all of the compiler errors until it works. What things unexpectedly break? Does it reduce boilerplate more than the struct or tuple approach?
        """)
    }
}
