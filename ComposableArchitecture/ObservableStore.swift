import Combine
import SwiftUI
public class ObservableStore<Value, Action>: Store<Value, Action>, ObservableObject {
    override var storage: Store<Value, Action>.Storage {
        willSet {
            objectWillChange.send()
        }
    }

    var cancelable: Cancellable?
    override public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> ObservableStore<LocalValue, LocalAction> {
        let localStore = ObservableStore<LocalValue, LocalAction>(
            initialValue: toLocalValue(value),
            reducer: {
                localValue, localAction in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return {}
            }
        )
        localStore.cancelable = objectWillChange.sink {
            [unowned localStore] _ in
            localStore.storage = .some(toLocalValue(self.value))
        }
        return localStore
    }

    public func send<LocalValue>(
        _ event: @escaping (LocalValue) -> Action,
        binding keyPath: KeyPath<Value, LocalValue>
    ) -> Binding<LocalValue> {
        Binding {
            self.value[keyPath: keyPath]
        } set: {
            self.send(event($0))
        }
    }
}
