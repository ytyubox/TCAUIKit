import Combine
import ComposableArchitecture

// MARK: - State

@dynamicMemberLookup
struct State<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void
    private let _publisher: AnyPublisher<Value, Never>

    var value: Value {
        get { getter() }
        set { setter(newValue) }
    }

    internal init(_ value: Value) {
        let currentValueSubject = CurrentValueSubject<Value, Never>(value)
        self.getter = { currentValueSubject.value }
        self.setter = { currentValueSubject.value = $0 }
        self._publisher = currentValueSubject.eraseToAnyPublisher()
    }

    fileprivate init(
        publisher: AnyPublisher<Value, Never>,
        getter: @escaping () -> Value,
        setter: @escaping (Value) -> Void
    ) {
        self.getter = getter
        self.setter = setter
        self._publisher = publisher
    }

    subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
        get { getter()[keyPath: keyPath] }
        set {
            var copy = getter()
            copy[keyPath: keyPath] = newValue
            setter(copy)
        }
    }

    func map<TargetValue>(
        _ targetValue: WritableKeyPath<Value, TargetValue>
    ) -> State<TargetValue> {
        State<TargetValue>(publisher: _publisher.map(targetValue).eraseToAnyPublisher()) {
            return getter()[keyPath: targetValue]
        } setter: { (newValue: TargetValue) in
            var value = getter()
            value[keyPath: targetValue] = newValue
            setter(value)
        }
    }

    func map<TargetValue>(
        getter targetGetter: @escaping (Value) -> TargetValue,
        setter targetSetter: @escaping (inout Value, TargetValue) -> Void
    ) -> State<TargetValue> {
        State<TargetValue>(publisher: _publisher.map(targetGetter).eraseToAnyPublisher()) {
            return targetGetter(value)
        } setter: { (newValue: TargetValue) in
            var value = getter()
            targetSetter(&value, newValue)
            setter(value)
        }
    }
}

extension State: Publishing {
    var publisher: AnyPublisher<Value, Never> {
        _publisher
    }
}

func viewing<Value, Action, Target>(store: Store<State<Value>, Action>,
                                    target: WritableKeyPath<Value, Target>) -> Store<State<Target>, Action>
{
    store.view { $0.map(target) }
}

extension Store {
    func view<Inner, Target>(_ target: WritableKeyPath<Inner, Target>) -> Store<State<Target>, Action>
        where Value == State<Inner>
    {
        view { $0.map(target) }
    }
}
