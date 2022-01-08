import XCTest

final class Ep71ExercisesTests: XCTestCase {
    func testQ1() throws {
        func filterActions<Value, Action>(_ predicate: @escaping (Action) -> Bool)
          -> (@escaping (inout Value, Action) -> Void)
          -> (inout Value, Action) -> Void {
              {
                  reducer in {
                      value, action in
                      guard predicate(action) else {return}
                      reducer(&value, action)
                  }
              }
        }
        var spy = 1
        filterActions { action in
            action > 0
        }({
          value,action in
            value += action
        })(&spy, 1)
        XCTAssertEqual(spy, 2)
    }
   
    func testQ2() throws {
        struct UndoState<Value: Equatable>: Equatable {
            var value: Value
            var history: [Value]
            var canUndo: Bool { !self.history.isEmpty }
        }
        
        enum UndoAction<Action> {
            case action(Action)
            case undo
        }
        func undo<Value, Action>(
          _ reducer: @escaping (inout Value, Action) -> Void
        ) -> (inout UndoState<Value>, UndoAction<Action>) -> Void {
            {
                undoState, undoAction in
                switch undoAction {
                    case let .action(action):
                        let currentState = undoState.value
                        reducer(&undoState.value, action)
                        undoState.history.append(currentState)
                    case .undo:
                        guard undoState.canUndo else {return}
                        undoState.value = undoState.history.removeLast()
                }
            }
        }
        var spy = UndoState(value: 1, history: [])
        
        let undoReducer:(inout UndoState<Int>, UndoAction<Int>) -> Void = undo { value, action in
            value += action
        }
        undoReducer(&spy, .action(1))
        XCTAssertEqual(spy, .init(value: 2, history: [1]))
        undoReducer(&spy, .undo)
        XCTAssertEqual(spy, .init(value: 1, history: []))
        undoReducer(&spy, .undo)
        XCTAssertEqual(spy, .init(value: 1, history: []))
    }
    func testQ3() throws {
        struct UndoState<Value: Equatable>: Equatable {
            var value: Value
            var history: [Value]
            var canUndo: Bool { !self.history.isEmpty }
        }
        
        enum UndoAction<Action> {
            case action(Action)
            case undo
        }
        func undo<Value, Action>(
            limit: Int,
          _ reducer: @escaping (inout Value, Action) -> Void
        ) -> (inout UndoState<Value>, UndoAction<Action>) -> Void {
            {
                undoState, undoAction in
                switch undoAction {
                    case let .action(action):
                        let currentState = undoState.value
                        reducer(&undoState.value, action)
                        undoState.history.append(currentState)
                        if undoState.history.count > limit {
                            undoState.history.removeFirst()
                        }
                    case .undo:
                        guard undoState.canUndo else {return}
                        undoState.value = undoState.history.removeLast()
                }
            }
        }
        var spy = UndoState(value: 1, history: [])
        
        let undoReducer:(inout UndoState<Int>, UndoAction<Int>) -> Void = undo(limit: 2) { value, action in
            value += action
        }
        undoReducer(&spy, .action(1))
        XCTAssertEqual(spy, .init(value: 2, history: [1]))
        undoReducer(&spy, .action(2))
        XCTAssertEqual(spy, .init(value: 4, history: [1,2]))
        undoReducer(&spy, .action(3))
        XCTAssertEqual(spy, .init(value: 7, history: [2,4]))
        undoReducer(&spy, .undo)
        XCTAssertEqual(spy, .init(value: 4, history: [2]))
        undoReducer(&spy, .undo)
        XCTAssertEqual(spy, .init(value: 2, history: []))
    }
    func testQ4() throws {
        struct UndoState<Value: Equatable>: Equatable {
            var value: Value
            var history: [Value]
            var undone: [Value]
            var canUndo: Bool { !self.history.isEmpty }
            var canRedo: Bool {!self.undone.isEmpty}
        }
        
        enum UndoAction<Action> {
            case action(Action)
            case undo
            case redo
        }
        func undo<Value, Action>(
            limit: Int,
          _ reducer: @escaping (inout Value, Action) -> Void
        ) -> (inout UndoState<Value>, UndoAction<Action>) -> Void {
            {
                undoState, undoAction in
                switch undoAction {
                    case let .action(action):
                        let currentState = undoState.value
                        reducer(&undoState.value, action)
                        undoState.history.append(currentState)
                        if undoState.history.count > limit {
                            undoState.history.removeFirst()
                        }
                    case .undo:
                        guard undoState.canUndo else {return}
                        undoState.undone.append(undoState.value)
                        undoState.value = undoState.history.removeLast()
                        if undoState.undone.count > limit {
                            undoState.undone.removeFirst()
                        }
                    case .redo:
                        guard undoState.canRedo else {
                            return
                        }
                        undoState.history.append(undoState.value)
                        undoState.value = undoState.undone.removeLast()
                        
                        if undoState.history.count > limit {
                            undoState.history.removeFirst()
                        }
                }
            }
        }
        var spy = UndoState(value: 1, history: [], undone: [])
        
        let undoReducer:(inout UndoState<Int>, UndoAction<Int>) -> Void = undo(limit: 2) { value, action in
            value += action
        }
        undoReducer(&spy, .action(1))
        XCTAssertEqual(spy, .init(value: 2, history: [1], undone: []))
        undoReducer(&spy, .action(2))
        XCTAssertEqual(spy, .init(value: 4, history: [1,2], undone: []))
        undoReducer(&spy, .action(3))
        XCTAssertEqual(spy, .init(value: 7, history: [2,4], undone: []))
        undoReducer(&spy, .undo)
        XCTAssertEqual(spy, .init(value: 4, history: [2], undone: [7]))
        undoReducer(&spy, .undo)
        XCTAssertEqual(spy, .init(value: 2, history: [], undone: [7,4]))
        undoReducer(&spy, .redo)
        XCTAssertEqual(spy, .init(value: 4, history: [2], undone: [7]))
        undoReducer(&spy, .redo)
        XCTAssertEqual(spy, .init(value: 7, history: [2,4], undone: []))
    }
    func testQ5() throws {
        throw XCTSkip("""
change the counterView for adopting undo redo, skipped
""")
    }
}

