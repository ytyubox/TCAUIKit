import CoreText
import Foundation

struct Parallel<A> {
    let run: (@escaping (A) -> Void) -> Void
}

public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]
public typealias Callback<Action> = (Action) -> Void

public struct Effect<Action> {
    public init(run: @escaping (@escaping Callback<Action>) -> Void) {
        self.run = run
    }

    private let run: (@escaping Callback<Action>) -> Void
    public func run(_ callback: @escaping Callback<Action>) {
        run(callback)
    }

    public func map<B>(_ f: @escaping (Action) -> B) -> Effect<B> {
        Effect<B> { callback in self.run { a in callback(f(a)) } }
    }
}

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
        effects.forEach {
            effect in
            effect.run(self.send)
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
        let value = value
        return Store<LocalValue, LocalAction>(initialValue: toLocalValue(value)) {
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
        let effects = reducers.flatMap { $0(&value, action) }
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
            localEffect.map { localAction in
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
        return [Effect { [value] _ in
            print("Action: \(action)")
            print("Value:")
            dump(value)
            print("---")
        }] + effects
    }
}

public extension Effect {
    func receive(on queue: DispatchQueue) -> Effect {
        return Effect { callback in
            self.run { a in
                queue.async { callback(a) }
            }
        }
    }
    func run(on queue: DispatchQueue) -> Effect {
        return Effect { callback in
            queue.async {
                self.run { a in
                    callback(a)
                }
            }
        }
    }
}
