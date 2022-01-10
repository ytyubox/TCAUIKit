//
/*
 *		Created by 游宗諭 in 2022/1/8
 *
 *		Using Swift 5.0
 *
 *		Running on macOS 12.1
 */

import ComposableArchitecture
import XCTest

class ComposableArchitectureTests: XCTestCase {
    func testSwiftUIBasedStore() throws {
        struct Target {
            var count = 0
            var string = ""
        }
        let store = ObservableStore<Target, String>(initialValue: Target()) {
            ($0.count, $0.string) = (Int($1) ?? 0, $1)
            return []
        }

        let countStore = store.view(value: \.count, action: { $0 })
        countStore.send("1")
        XCTAssertEqual(store.value.count, 1)
        XCTAssertEqual(countStore.value, 1)
    }
}
