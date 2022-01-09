import Combine
import ComposableArchitecture
import UIKit
protocol Publishing {
    associatedtype Value

    var publisher: AnyPublisher<Value, Never> { get }
}

extension Store: Publishing where Value: Publishing {
    var publisher: AnyPublisher<Value.Value, Never> {
        value.publisher
    }
}

// MARK: - State

@dynamicMemberLookup
struct State<Value>: Publishing {
    private let getter: () -> Value
    private let setter: (Value) -> Void
    let publisher: AnyPublisher<Value, Never>

    var value: Value {
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

    subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
        get { getter()[keyPath: keyPath] }
        set {
            var copy = getter()
            copy[keyPath: keyPath] = newValue
            setter(copy)
        }
    }

    // MARK: - Pull back

    func pullback<TargetValue>(
        _ target: WritableKeyPath<Value, TargetValue>
    ) -> State<TargetValue> {
        self.pullback {
            $0[keyPath: target]
        } setter: {
            $0[keyPath: target] = $1
        }
    }

    func pullback<TargetValue>(
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

extension Store {
    func view<Inner, Target>(_ target: WritableKeyPath<Inner, Target>) -> Store<State<Target>, Action>
    where Value == State<Inner>
    {
        view {
            $0.pullback(target)
        }
    }
    func view<Inner, Target>(_ f:@escaping (Inner) -> Target) -> Store<State<Target>, Action>
    where Value == State<Inner>
    {
        view {
            $0.pullback(getter: f, setter: {_,_ in })
        }
    }
}

