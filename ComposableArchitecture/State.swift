import Combine

public protocol Publishing {
    associatedtype Value

    var publisher: AnyPublisher<Value, Never> { get }
}

extension Store: Publishing where Value: Publishing {
    public var publisher: AnyPublisher<Value.Value, Never> {
        value.publisher
    }
}

// MARK: - State

public typealias StateStore<Value, Action> = Store<State<Value>, Action>
@dynamicMemberLookup
public struct State<Value>: Publishing {
    private let getter: () -> Value
    private let setter: (Value) -> Void
    public let publisher: AnyPublisher<Value, Never>

    public var value: Value {
        get { getter() }
        set { setter(newValue) }
    }

    // MARK: - Factory method

    public static func cold(_ value: Value) -> State<Value> {
        var value = value
        let subject = PassthroughSubject<Value, Never>()
        return State(publisher: subject.eraseToAnyPublisher()) { value
        } setter: {
            value = $0
            subject.send(value)
        }
    }

    public static func hot(_ value: Value) -> State<Value> {
        let subject = CurrentValueSubject<Value, Never>(value)
        return State(publisher: subject.eraseToAnyPublisher()) { subject.value
        } setter: { subject.value = $0 }
    }

    fileprivate init(
        publisher: AnyPublisher<Value, Never>,
        getter: @escaping () -> Value,
        setter: @escaping (Value) -> Void
    ) {
        self.getter = getter
        self.setter = setter
        self.publisher = publisher
    }

    // MARK: - Dynamic Member Lookup

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
        get { getter()[keyPath: keyPath] }
        set {
            var copy = getter()
            copy[keyPath: keyPath] = newValue
            setter(copy)
        }
    }

    // MARK: - Pull back

    public func view<TargetValue>(
        _ target: WritableKeyPath<Value, TargetValue>
    ) -> State<TargetValue> {
        self.viewing(getter: { $0[keyPath: target] },
                     setter: { $0[keyPath: target] = $1 })
    }

    public func viewing<TargetValue>(
        getter targetGetter: @escaping (Value) -> TargetValue,
        setter targetSetter: @escaping (inout Value, TargetValue) -> Void
    ) -> State<TargetValue> {
        State<TargetValue>(publisher: publisher.map(targetGetter)
            .eraseToAnyPublisher()) {
                return targetGetter(value)
        } setter: { (newValue: TargetValue) in
            var value = getter()
            targetSetter(&value, newValue)
            setter(value)
        }
    }
}

public extension Store {
    func view<InnerValue, LocalValue, LocalAction>(
        value localValue: WritableKeyPath<InnerValue, LocalValue>,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<State<LocalValue>, LocalAction>
        where Value == State<InnerValue>
    {
        view(value: { inner in
            inner[keyPath: localValue]
        }, action: toGlobalAction)
    }

    func view<InnerValue, LocalValue, LocalAction>(
        value localValue: @escaping (InnerValue) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<State<LocalValue>, LocalAction>

        where Value == State<InnerValue>
    {
        view(value: { $0.viewing(getter: localValue,
                                 setter: { _, _ in }) },
             action: { toGlobalAction($0) })
    }
}
