import Foundation
@testable import TCAUIKit
import XCTest

final class Ep68ExercisesTests: XCTestCase {
    func testQ1() throws {
        func toInout<A>(_ f: @escaping (A) -> A) -> (inout A) -> Void {
            {
                [f] a in
                a = f(a)
            }
        }

        func fromInout<A>(_ f: @escaping (inout A) -> Void) -> (A) -> A {
            {
                [f] a in
                var a = a
                f(&a)
                return a
            }
        }
        var sut = 0
        toInout { a in
            a + 1
        }(&sut)
        XCTAssertEqual(sut, 1)

        let result = fromInout { inoutA in
            inoutA += 10
        }(sut)
        XCTAssertEqual(result, 11)
    }

    func testQ2() throws {
        func combine<Value, Action>(
            _ first: @escaping (inout Value, Action) -> Void,
            _ second: @escaping (inout Value, Action) -> Void
        ) -> (inout Value, Action) -> Void {
            {
                value, action in
                first(&value, action)
                second(&value, action)
            }
        }

        var spy = 0
        combine { inoutA, action in
            inoutA += 2 * action
        } _: { inoutA, action in
            inoutA += 10 * action
        }(&spy, 3)
        XCTAssertEqual(spy, 36)
    }

    private func combine<Value, Action>(
        _ reducers: (inout Value, Action) -> Void...
    ) -> (inout Value, Action) -> Void {
        combine(reducers)
    }

    private func combine<Value, Action>(
        _ reducers: [(inout Value, Action) -> Void]
    ) -> (inout Value, Action) -> Void {
        {
            value, action in
            for reducer in reducers {
                reducer(&value, action)
            }
        }
    }

    func testQ3() throws {
        var spy = 0
        combine({ inoutA, action in
            inoutA += 2 * action
        }, { inoutA, action in
            inoutA += 10 * action
        })(&spy, 3)
        XCTAssertEqual(spy, 36)
    }

    func testQ4() throws {
        func counterReducer(value: inout AppState, action: AppAction) {
            switch action {
            case .counterView(.counter(.decrTapped)): value.count -= 1
            case .counterView(.counter(.incrTapped)): value.count += 1
            default: break
            }
        }
        func primeModalReducer(value: inout AppState, action: AppAction) {
            switch action {
            case .counterView(.primeModal(.saveFavoritePrimeTapped)):
                value.favoritePrimes.append(value.count)
            case .counterView(.primeModal(.removeFavoritePrimeTapped)):
                value.favoritePrimes.removeAll { $0 == value.count }
            default: break
            }
        }
        func FavoritePrimeReducer(value: inout AppState, action: AppAction) {
            switch action {
            case let .favoritePrimes(favoritePrimesAction):
                switch favoritePrimesAction {
                case let .deleteFavoritePrimes(indexSet):
                    for index in indexSet {
                        value.favoritePrimes.remove(at: index)
                    }
                }
            default: break
            }
        }

        var state = AppState(count: 0, favoritePrimes: [], loggedInUser: nil, activityFeed: [])
        let appReducer = combine(
            [counterReducer(value:action:),
             primeModalReducer(value:action:),
             FavoritePrimeReducer(value:action:)]
        )
        appReducer(&state, .counterView(.counter(.incrTapped)))
        XCTAssertEqual(state.count, 1)
        appReducer(&state, .counterView(.counter(.decrTapped)))
        XCTAssertEqual(state.count, 0)
        appReducer(&state, .counterView(.primeModal(.saveFavoritePrimeTapped)))
        XCTAssertEqual(state.favoritePrimes, [0])
        appReducer(&state, .favoritePrimes(.deleteFavoritePrimes([0])))
        XCTAssertEqual(state.favoritePrimes, [])
    }

    func testQ5() throws {
        func transform(
            _ localReducer: @escaping (inout Int, AppAction) -> Void
        ) -> (inout AppState, AppAction) -> Void {
            {
                state, action in
                localReducer(&state.count, action)
            }
        }

        var state = AppState()
        let reducer = transform { count, action in
            switch action {
            case .counterView(.counter(.decrTapped)): count -= 1
            case .counterView(.counter(.incrTapped)): count += 1
            default: break
            }
        }

        reducer(&state, .counterView(.counter(.incrTapped)))
        XCTAssertEqual(state.count, 1)
        reducer(&state, .counterView(.counter(.decrTapped)))
        XCTAssertEqual(state.count, 0)
    }

    func testQ6() throws {
        func transform(
            count: WritableKeyPath<AppState, Int>,
            _ localReducer: @escaping (inout Int, AppAction) -> Void
        ) -> (inout AppState, AppAction) -> Void {
            {
                state, action in

                localReducer(&state[keyPath: count], action)
            }
        }

        var state = AppState()
        let reducer = transform(count: \.count) { count, action in
            switch action {
            case .counterView(.counter(.decrTapped)): count -= 1
            case .counterView(.counter(.incrTapped)): count += 1
            default: break
            }
        }

        reducer(&state, .counterView(.counter(.incrTapped)))
        XCTAssertEqual(state.count, 1)
        reducer(&state, .counterView(.counter(.decrTapped)))
        XCTAssertEqual(state.count, 0)
    }
}
