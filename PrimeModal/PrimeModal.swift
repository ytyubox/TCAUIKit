import ComposableArchitecture
import UIKit
public typealias PrimeModalState = (count: Int, favoritePrimes: [Int])
public enum PrimeModalAction {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

public func primeModalReducer(state: inout PrimeModalState, action: PrimeModalAction) -> Effect {
    switch action {
    case .removeFavoritePrimeTapped:
        state.favoritePrimes.removeAll(where: { $0 == state.count })

    case .saveFavoritePrimeTapped:
        state.favoritePrimes.append(state.count)
    }
    return {}
}

public class IsPrimeModelViewController: UIViewController {
    public var store: StateStore<PrimeModalState, PrimeModalAction> = .needInject
    @IBOutlet var label: UILabel!
    @IBOutlet var button: UIButton!

    override public func viewDidLoad() {
        super.viewDidLoad()
        if isPrime(store.value.count) {
            label.text = "\(String(describing: store.value.count)) is prime 🎉"
            updateButton()

        } else {
            label.text = "\(String(describing: store.value.count)) is not prime :("
            button.isHidden = true
        }
    }

    @IBAction func didTapSaveButton(_: UIButton) {
        if store.value.favoritePrimes.contains(store.value.count) {
            store.send(.removeFavoritePrimeTapped)
        } else {
            store.send(.saveFavoritePrimeTapped)
        }
        updateButton()
    }

    fileprivate func updateButton() {
        if store.value.favoritePrimes.contains(store.value.count) {
            button.setTitle("Remove from favorite primes", for: .normal)
        } else {
            button.setTitle("Save to favorite primes", for: .normal)
        }
    }
}

func isPrime(_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2 ... Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}
