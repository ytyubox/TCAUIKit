import ComposableArchitecture
import Counter
import FavoritePrimes
import Foundation
struct AppState {
    var count = 0
    var favoritePrimes: [Int] = []
    var loggedInUser: User? = nil
    var alertNthPrime: String? = nil
    var isNthPrimeButtonEnabled = true
    var activityFeed: [Activity] = []
    var isPrime: Bool? = nil
    var isPresentPrimeModal:Bool = false
    struct Activity {
        let timestamp: Date
        let type: ActivityType

        enum ActivityType {
            case addedFavoritePrime(Int)
            case removedFavoritePrime(Int)
            case save([Int])
            case load([Int])
            case nthPrimeResponse(Int?)
        }
    }

    struct User {
        let id: Int
        let name: String
        let bio: String
    }
}

enum AppAction {
    case counterView(CounterViewAction)
    case favoritePrimes(FavoritePrimesAction)

    var favoritePrimes: FavoritePrimesAction? {
        get {
            guard case let .favoritePrimes(value) = self else { return nil }
            return value
        }
        set {
            guard case .favoritePrimes = self, let newValue = newValue else { return }
            self = .favoritePrimes(newValue)
        }
    }

    var counterView: CounterViewAction? {
        get {
            guard case let .counterView(value) = self else { return nil }
            return value
        }
        set {
            guard case .counterView = self, let newValue = newValue else { return }
            self = .counterView(newValue)
        }
    }
}

extension AppState {
    var counterViewState: CounterViewState {
        get {
            CounterViewState(
                alertNthPrime: alertNthPrime,
                count: count,
                isNthPrimeButtonEnabled: isNthPrimeButtonEnabled,
                favoritePrimes: favoritePrimes,
                isPrime: isPrime, isPresentPrimeModal: isPresentPrimeModal
            )
        }
        set {
            (count,
             favoritePrimes,
             isNthPrimeButtonEnabled,
             alertNthPrime,
             isPrime,
             isPresentPrimeModal
            ) = (
                newValue.count,
                newValue.favoritePrimes,
                newValue.isNthPrimeButtonEnabled,
                newValue.alertNthPrime,
                newValue.isPrime,
                newValue.isPresentPrimeModal
            )
        }
    }
}

func activityFeed(
    _ reducer: @escaping Reducer<AppState, AppAction>
) -> Reducer<AppState, AppAction> {
    return { state, action in
        switch action {
        case .counterView(.counter),
             .favoritePrimes(.loadButtonTapped),
             .favoritePrimes(.saveButtonTapped),
                    .counterView(.primeModal(.startLoadingIsPrime)),
                    .counterView(.primeModal(.isPrimeResponse(_))):
            break

        case .counterView(.primeModal(.removeFavoritePrimeTapped)):
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))

        case .counterView(.primeModal(.saveFavoritePrimeTapped)):
            state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))

        case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
            for index in indexSet {
                state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.favoritePrimes[index])))
            }

        case let .favoritePrimes(.favoritePrimesLoaded(primes)):
            state.activityFeed.append(.init(timestamp: Date(), type: .load(primes)))
          
        }

        return reducer(&state, action)
    }
}

let appReducer: Reducer<AppState, AppAction> = combine(
    pullback(counterViewReducer, value: \.counterViewState, action: \.counterView),
    pullback(favoritePrimesReducer, value: \.favoritePrimes, action: \.favoritePrimes)
)
let AppReducer: Reducer<AppState, AppAction> = with(
    appReducer,
    compose(logging, activityFeed)
)
