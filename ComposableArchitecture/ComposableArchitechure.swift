import Combine
import Foundation

public final class Store<Value, Action> {
    private let reducer: (inout Value, Action) -> Void
    public private(set) var value: Value!

    public init(initialValue: Value, reducer: @escaping (inout Value, Action) -> Void) {
        self.reducer = reducer
        value = initialValue
    }

    public func send(_ action: Action) {
        reducer(&value, action)
    }

    // MARK: - Helper

    private init() {
        value = nil
        reducer = { _, _ in }
    }

    public static var needInject: Store<Value, Action> {
        self.init()
    }
}

public extension Store {
    func view<LocalValue>(
        _ f: @escaping (Value) -> LocalValue
    ) -> Store<LocalValue, Action> {
        Store<LocalValue, Action>(initialValue: f(value)) { localValue, action in
            self.send(action)
            localValue = f(self.value)
        }
    }
}

public func combine<Value, Action>(
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    return { value, action in
        for reducer in reducers {
            reducer(&value, action)
        }
    }
}

public func pullback<LocalValue, GlobalValue, GlobalAction, LocalAction>(
    _ reducer: @escaping (inout LocalValue, LocalAction) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: KeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> Void {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        reducer(&globalValue[keyPath: value], localAction)
    }
}

public func logging<Value, Action>(
    _ reducer: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {
    return { value, action in
        reducer(&value, action)
        print("Action: \(action)")
        print("Value:")
        dump(value)
        print("---")
    }
}
