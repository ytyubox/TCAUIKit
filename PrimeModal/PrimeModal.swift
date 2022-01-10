import ComposableArchitecture
import UIKit
import Combine
public struct PrimeModalState{
    public init(count: Int, favoritePrimes: [Int], isPrime: Bool?) {
        self.count = count
        self.favoritePrimes = favoritePrimes
        self.isPrime = isPrime
    }
    
    public var count: Int
    public var favoritePrimes: [Int]
    public var isPrime: Bool?
}
public enum PrimeModalAction {
    case startLoadingIsPrime
    case isPrimeResponse(Bool)
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

public func primeModalReducer(state: inout PrimeModalState, action: PrimeModalAction) -> [Effect<PrimeModalAction>] {
    switch action {
        case .removeFavoritePrimeTapped:
            state.favoritePrimes.removeAll(where: { $0 == state.count })
            return []
        case .saveFavoritePrimeTapped:
            state.favoritePrimes.append(state.count)
            return []
        case .startLoadingIsPrime:
            state.isPrime = nil
            return [
                isPrime(state.count)
                    .map(PrimeModalAction.isPrimeResponse)
                    .receive(on: DispatchQueue.main)
            ]
        case let .isPrimeResponse(isPrime):
            state.isPrime = isPrime
            return []
    }
}

public class IsPrimeModelViewController: UIViewController {
    public var store: StateStore<PrimeModalState, PrimeModalAction> = .needInject
    @IBOutlet var label: UILabel!
    @IBOutlet var button: UIButton!
    var cancellable: Cancellable?
    override public func viewDidLoad() {
        super.viewDidLoad()
        cancellable = store.value.publisher.sink { [self] (value) in
            if let isPrime = value.isPrime {
                if isPrime {
                    label.text = "\(String(describing: store.value.count)) is prime 🎉"
                    button.isHidden = false
                    if store.value.favoritePrimes.contains(store.value.count) {
                        button.setTitle("Remove from favorite primes", for: .normal)
                    } else {
                        button.setTitle("Save to favorite primes", for: .normal)
                    }
                } else {
                    label.text = "\(String(describing: store.value.count)) is not prime :("
                    button.isHidden = true
                }
               
            } else {
                label.text = "Calculating..."
                button.isHidden = true
            }
        }
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        store.send(.startLoadingIsPrime)
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancellable?.cancel()
    }
    
    @IBAction func didTapSaveButton(_: UIButton) {
        if store.value.favoritePrimes.contains(store.value.count) {
            store.send(.removeFavoritePrimeTapped)
        } else {
            store.send(.saveFavoritePrimeTapped)
        }
    }

}

func isPrime(_ p: Int) -> Effect<Bool> {
    Effect { callback in
        let result: Bool
        defer {
            DispatchQueue.main.async {
                callback(result)
            }
        }
        if p <= 1 { return result = false }
        if p <= 3 { return result = true }
        for i in 2 ... Int(sqrtf(Float(p))) {
            if p % i == 0 { return result = false }
        }
        return result = true
    }
    .run(on: DispatchQueue.global())
}
