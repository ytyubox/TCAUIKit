import Combine
import ComposableArchitecture
import Foundation
import PrimeModal
import SwiftUI
import UIKit
import UIKitHelper
public enum CounterAction {
    case decrTapped
    case incrTapped
    case nthPrimeButtonTapped
    case nthPrimeResponse(Int?)
    case nthPrimeDismissButtonTapped
}

public struct CounterState {
    public init(alertNthPrime: String? = nil, count: Int, isNthPrimeButtonEnabled: Bool) {
        self.alertNthPrime = alertNthPrime
        self.count = count
        self.isNthPrimeButtonEnabled = isNthPrimeButtonEnabled
    }

    var alertNthPrime: String?
    var count: Int
    var isNthPrimeButtonEnabled: Bool
}

public func counterReducer(state: inout CounterState, action: CounterAction) -> [Effect<CounterAction>] {
    switch action {
    case .decrTapped:
        state.count -= 1
        return []
    case .incrTapped:
        state.count += 1
        return []
    case .nthPrimeButtonTapped:
        state.isNthPrimeButtonEnabled = false
        let count = state.count
        return [{ callback in
            nthPrime(count) { prime in
                callback(.nthPrimeResponse(prime))
            }
        }]
    case let .nthPrimeResponse(prime):
        state.alertNthPrime = prime.map { prime in
            "The \(ordinal(state.count)) prime is \(prime)"
        }
        state.isNthPrimeButtonEnabled = true
        return []
    case .nthPrimeDismissButtonTapped:
        state.alertNthPrime = nil
        return []
    }
}

public struct CounterViewState {
    public init(alertNthPrime: String? = nil, count: Int, isNthPrimeButtonEnabled: Bool, favoritePrimes: [Int]) {
        self.alertNthPrime = alertNthPrime
        self.count = count
        self.isNthPrimeButtonEnabled = isNthPrimeButtonEnabled
        self.favoritePrimes = favoritePrimes
    }

    public var alertNthPrime: String?
    public var count: Int
    public var isNthPrimeButtonEnabled: Bool
    public var favoritePrimes: [Int]
    var CounterState: CounterState {
        get {
            Counter.CounterState(alertNthPrime: alertNthPrime, count: count, isNthPrimeButtonEnabled: isNthPrimeButtonEnabled)
        }
        set {
            (count, isNthPrimeButtonEnabled, alertNthPrime) = (newValue.count, newValue.isNthPrimeButtonEnabled, newValue.alertNthPrime)
        }
    }

    var primeModalState: PrimeModalState {
        get {
            PrimeModalState(count: count, favoritePrimes: favoritePrimes)
        }
        set {
            (count, favoritePrimes) = (newValue.count, newValue.favoritePrimes)
        }
    }
}

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
    pullback(counterReducer, value: \.CounterState, action: \.counter),
    pullback(primeModalReducer, value: \.primeModalState, action: \.primeModal)
)
public class CounterViewController: UIViewController {
    public var store: StateStore<CounterViewState, CounterViewAction> = .needInject
    @IBOutlet private var label: UILabel!
    @IBOutlet private var nthPrimeButton: UIButton!
    var cancelable: Cancellable?
    var alert: UIAlertController?
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Counter demo"
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cancelable = store.publisher.sink { [self] state in
            label?.text = state.count.description
            nthPrimeButton?.setTitle("What is the \(ordinal(state.count)) prime?", for: .normal)
            nthPrimeButton.isEnabled = state.isNthPrimeButtonEnabled
            if let alertNthPrime = state.alertNthPrime {
                let alert = UIAlertController(
                    title: alertNthPrime,
                    message: nil,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(
                    title: "ok",
                    style: .default,
                    handler: { _ in
                        store.send(.counter(.nthPrimeDismissButtonTapped))
                    }
                ))

                self.present(alert, animated: true, completion: {
                    self.alert = alert
                })
            } else {
                alert?.dismiss(animated: true, completion: nil)
            }
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
        store.send(.counter(.nthPrimeButtonTapped))
    }
}

func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}
