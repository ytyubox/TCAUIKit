import Combine
import ComposableArchitecture

protocol Publishing {
    associatedtype Value

    var publisher: AnyPublisher<Value, Never> { get }
}

extension Store: Publishing where Value: Publishing {
    var publisher: AnyPublisher<Value.Value, Never> {
        value!.publisher
    }
}
