@testable import TCAUIKit
import XCTest

final class StateTests: XCTestCase {
    func testColdStateWithKeyPath() throws {
        struct Model {
            var count = 0
            var string: String = ""
        }
        var state = State.cold(Model())
        var listState = state.pullback(\.string)
        var history: [String] = []
        let cancelable = listState.publisher.sink { history.append($0) }
        listState.value += "1"
        XCTAssertEqual(history, ["1"])
        state.string += "2"
        XCTAssertEqual(history, ["1", "12"])
        cancelable.cancel()
    }

    func testHotStateWithKeyPath() throws {
        struct Model {
            var count = 0
            var string: String = ""
        }
        var state = State.hot(Model())
        var listState = state.pullback(\.string)
        var history: [String] = []
        let cancelable = listState.publisher.sink { history.append($0) }
        listState.value.append("1")
        XCTAssertEqual(history, ["", "1"])
        state.string.append("2")
        XCTAssertEqual(history, ["", "1", "12"])
        cancelable.cancel()
    }

    func testColdStateWithGetterSetter() throws {
        struct Model {
            var count = 0
            var string: String = ""
        }
        var state = State.cold(Model())
        var listState = state.pullback {
            $0.string
        } setter: { $0.string = $1
        }

        var history: [String] = []
        let cancelable = listState.publisher.sink { history.append($0) }
        listState.value.append("1")
        XCTAssertEqual(history, ["1"])
        state.string.append("2")
        XCTAssertEqual(history, ["1", "12"])
        cancelable.cancel()
    }

    func testHotStateWithGetterSetter() throws {
        struct Model {
            var count = 0
            var string: String = ""
        }
        var state = State.hot(Model())
        var listState = state.pullback {
            $0.string
        } setter: { $0.string = $1
        }
        var history: [String] = []
        let cancelable = listState.publisher.sink { history.append($0) }
        listState.value.append("1")
        XCTAssertEqual(history, ["", "1"])
        state.string.append("2")
        XCTAssertEqual(history, ["", "1", "12"])
        cancelable.cancel()
    }
}

