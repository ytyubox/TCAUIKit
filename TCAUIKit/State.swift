import Foundation
import Combine
// MARK: - State

@dynamicMemberLookup
final class State<Value> {
    let publisher: CurrentValueSubject<Value, Never>!
    
    init(_ value: Value) {
        self.publisher = CurrentValueSubject<Value, Never>(value)
    }
    
    private init() { publisher = nil }
    
    var value: Value {
        get { publisher.value}
        set { publisher.value = newValue}
    }
    
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
        get { publisher.value[keyPath: keyPath]}
        set { publisher.value[keyPath: keyPath] = newValue }
    }
    
    static var needInject: State { self.init() }
}
