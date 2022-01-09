import Combine
import ComposableArchitecture
import Foundation
import PrimeModal
import UIKit
import UIKitHelper
public enum CounterAction {
    case decrTapped
    case incrTapped
}

public func counterReducer(state: inout Int, action: CounterAction) -> [Effect<CounterAction>] {
    switch action {
    case .decrTapped:
        state -= 1

    case .incrTapped:
        state += 1
    }
    return []
}

public typealias CounterViewState = (count: Int, favoritePrimes: [Int])

public enum CounterViewAction {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
        }
    }

    var primeModal: PrimeModalAction? {
        get {
            guard case let .primeModal(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeModal = self, let newValue = newValue else { return }
            self = .primeModal(newValue)
        }
    }
}

public let counterViewReducer: Reducer<CounterViewState, CounterViewAction> = combine(
    pullback(counterReducer, value: \.count, action: \.counter),
    pullback(primeModalReducer, value: \.self, action: \.primeModal)
)
public class CounterViewController: UIViewController {
    public var store: StateStore<CounterViewState, CounterViewAction> = .needInject
    @IBOutlet private var label: UILabel!
    @IBOutlet private var nthPrimeButton: UIButton!
    var cancelable: Cancellable?
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Counter demo"
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cancelable = store.publisher.sink { [self] state in
            label?.text = state.count.description
            nthPrimeButton?.setTitle("What is the \(ordinal(state.count)) prime?", for: .normal)
        }
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelable?.cancel()
    }

    @IBAction func didTapPlusButton(_: UIButton) {
        store.send(.counter(.incrTapped))
    }

    @IBAction func didTapDownButton(_: UIButton) {
        store.send(.counter(.decrTapped))
    }

    @IBAction func didTapIsThisPrimeButton(_: UIButton) {
        let vc = IsPrimeModelViewController.make(from: .main, id: "IsPrimeModelViewController")
        vc.store = store.view(value: { ($0.count, $0.favoritePrimes) },
                              action: { .primeModal($0) })
        present(vc, animated: true, completion: nil)
    }

    @IBAction func didTapWhatNthPrimeButton(_: UIButton) {
        nthPrimeButton.isEnabled = false
        nthPrime(store.value.count) { prime in
            DispatchQueue.main.async {
                if let prime = prime {
                    let alert = UIAlertController(title: "The \(ordinal(self.store.value.count)) prime is \(prime)", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "ok", style: .default, handler: { _ in
                        alert.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
                self.nthPrimeButton.isEnabled = true
            }
        }
    }
}

func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}
