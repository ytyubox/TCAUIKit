import ComposableArchitecture
import Counter
import FavoritePrimes
import Foundation
struct AppState {
    var count = 0
    var favoritePrimes: [Int] = []
    var loggedInUser: User? = nil
    var activityFeed: [Activity] = []

    struct Activity {
        let timestamp: Date
        let type: ActivityType

        enum ActivityType {
            case addedFavoritePrime(Int)
            case removedFavoritePrime(Int)
            case save([Int])
            case load([Int])
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

let appReducer: Reducer<AppState, AppAction> = combine(
    pullback(counterViewReducer, value: \.counterView, action: \.counterView),
    pullback(favoritePrimesReducer, value: \.favoritePrimes, action: \.favoritePrimes)
)
extension AppState {
    var counterView: CounterViewState {
        get {
            CounterViewState(
                count: count,
                favoritePrimes: favoritePrimes
            )
        }
        set {
            count = newValue.count
            favoritePrimes = newValue.favoritePrimes
        }
    }
}

func activityFeed(
    _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> Reducer<AppState, AppAction> {
    return { state, action in
        switch action {
        case .counterView(.counter),
             .favoritePrimes(.loadButtonTapped),
             .favoritePrimes(.saveButtonTapped):
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

        reducer(&state, action)
        return []
    }
}

let AppReducer: Reducer<AppState, AppAction> = with(
    { state, action in
        let effects = appReducer(&state, action)
        effects.forEach { effect in
            guard let action = effect() else { return }
            appReducer(&state, action)
        }
    },
    compose(
        logging,
        activityFeed
    )
)
