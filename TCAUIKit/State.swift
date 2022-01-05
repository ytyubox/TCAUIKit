import Combine
import Foundation

// MARK: - State

@dynamicMemberLookup
struct State<Value> {
    private let _publisher: CurrentValueSubject<Value, Never>!

    init(_ value: Value) {
        self._publisher = CurrentValueSubject<Value, Never>(value)
    }

    private init() { _publisher = nil }

    var value: Value {
        get { _publisher.value }
        set { _publisher.value = newValue }
    }

    subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
        get { _publisher.value[keyPath: keyPath] }
        set { _publisher.value[keyPath: keyPath] = newValue }
    }

    static var needInject: State { self.init() }
}

extension State: Publishing {
    var publisher: CurrentValueSubject<Value, Never> {
        _publisher
    }
}
