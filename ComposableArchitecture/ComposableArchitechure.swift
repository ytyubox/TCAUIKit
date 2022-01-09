import Foundation
public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]
public typealias Effect<Action> = () -> Action?

public class Store<Value, Action> {
    private let reducer: Reducer<Value, Action>
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

    public init(initialValue: Value, reducer: @escaping Reducer<Value, Action>) {
        self.reducer = reducer
        storage = .some(initialValue)
    }

    public func send(_ action: Action) {
        let effects = reducer(&storage.value, action)
        effects.compactMap { $0() }.forEach { _ in
            self.send(action)
        }
    }

    // MARK: - Helper

    private init() {
        storage = .none
        reducer = { _, _ in [] }
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
            return []
        }
    }
}

public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    return { value, action in
        var effects: [Effect<Action>] = []
        for reducer in reducers {
            effects.append(contentsOf: reducer(&value, action))
        }
        return effects
    }
}

public func pullback<LocalValue, GlobalValue, GlobalAction, LocalAction>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return [] }
        let localEffects = reducer(&globalValue[keyPath: value], localAction)
        return localEffects.map { localEffect in
            {
                () -> GlobalAction? in
                guard let localAction = localEffect() else { return nil }
                var globalAction = globalAction
                globalAction[keyPath: action] = localAction
                return globalAction
            }
        }
    }
}

public func logging<Value, Action>(
    _ reducer: @escaping Reducer<Value, Action>
) -> Reducer<Value, Action> {
    return { value, action in
        let effects = reducer(&value, action)
        return [{ [value] in
            print("Action: \(action)")
            print("Value:")
            dump(value)
            print("---")
            return nil
        }] + effects
    }
}
