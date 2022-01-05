import Combine
import Foundation

final class Store<Value, Action> {
    private let reducer: (inout Value, Action) -> Void
    private(set) var value: Value!

    init(initialValue: Value, reducer: @escaping (inout Value, Action) -> Void) {
        self.reducer = reducer
        value = initialValue
    }

    func send(_ action: Action) {
        reducer(&value, action)
    }

    private init() {
        value = nil
        reducer = { _, _ in }
    }

    static var needInject: Store<Value, Action> {
        self.init()
    }
}

protocol Publishing {
    associatedtype Value

    var publisher: CurrentValueSubject<Value, Never> { get }
}

extension Store: Publishing where Value: Publishing {
    var publisher: CurrentValueSubject<Value.Value, Never> {
        value!.publisher
    }
}
