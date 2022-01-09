import Foundation

public class Store<Value, Action> {
    private let reducer: (inout Value, Action) -> Void
    public var value: Value {
        get {
            storage.value
        }
        set {
            storage = .some(newValue)
        }
    }

    internal var storage: Storage
    internal enum Storage {
        case some(Value)
        case none
        var value: Value {
            get {
                switch self {
                case let .some(value): return value
                case .none: fatalError()
                }
            } set {
                self = .some(newValue)
            }
        }
    }

    public init(initialValue: Value, reducer: @escaping (inout Value, Action) -> Void) {
        self.reducer = reducer
        storage = .some(initialValue)
    }

    public func send(_ action: Action) {
        reducer(&storage.value, action)
    }

    // MARK: - Helper

    private init() {
        storage = .none
        reducer = { _, _ in }
    }

    public static var needInject: Store<Value, Action> {
        Store()
    }

    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        Store<LocalValue, LocalAction>(initialValue: toLocalValue(value)) {
            localValue, localAction in
            self.send(toGlobalAction(localAction))
            localValue = toLocalValue(self.value)
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
