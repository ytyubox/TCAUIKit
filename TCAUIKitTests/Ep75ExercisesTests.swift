import ComposableArchitecture
import SwiftUI
import XCTest

final class Ep75ExercisesTests: XCTestCase {
    func testQ1() throws {
        struct Target {
            var count = 0
            var string = ""
        }
        let sut = ObservableStore<Target, String>(
            initialValue: Target(),
            reducer: {
                $0.count += Int($1)!
                return {}
            }
        )
        let binding = sut.send(
            \.description,
            binding: \.count
        )
        binding.wrappedValue = 3
        XCTAssertEqual(sut.value.count, 3)
        XCTAssertEqual(sut.value.string, "")
    }

    func testQ2() throws {
        throw XCTSkip("""
        Skip for UIKit do not need binding.
        Q:Using the send implementation from the previous exercise, change the Text view that holds the counter into a TextField, which would allow the user to enter any number they want. To accomplish this you will need to introduce a new counter action counterTextFieldChanged(String) in order to be notified when the user types into the field.
        """)
    }
}
