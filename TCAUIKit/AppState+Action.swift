import Foundation
// MARK: - AppState

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
        }
    }

    struct User {
        let id: Int
        let name: String
        let bio: String
    }
}

// MARK: - Actions

enum CounterAction {
    case decrTapped
    case incrTapped
}

enum PrimeModalAction {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

enum FavoritePrimesAction {
    case deleteFavoritePrimes(IndexSet)
}

enum AppAction {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    case favoritePrimes(FavoritePrimesAction)
    
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
}

func counterReducer(state: inout Int, action: CounterAction) {
  switch action {
  case .decrTapped: state -= 1
  case .incrTapped: state += 1
  }
}

func primeModalReducer(state: inout AppState, action: PrimeModalAction) {
  switch action {
  case .removeFavoritePrimeTapped:
    state.favoritePrimes.removeAll(where: { $0 == state.count })
    state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))

  case .saveFavoritePrimeTapped:
    state.favoritePrimes.append(state.count)
    state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))
  }
}

struct FavoritePrimesState {
  var favoritePrimes: [Int]
  var activityFeed: [AppState.Activity]
}

func favoritePrimesReducer(state: inout FavoritePrimesState, action: FavoritePrimesAction) {
  switch action {
  case let .deleteFavoritePrimes(indexSet):
    for index in indexSet {
      state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.favoritePrimes[index])))
      state.favoritePrimes.remove(at: index)
    }
  }
}

extension AppState {
  var favoritePrimesState: FavoritePrimesState {
    get {
      FavoritePrimesState(
        favoritePrimes: self.favoritePrimes,
        activityFeed: self.activityFeed
      )
    }
    set {
      self.favoritePrimes = newValue.favoritePrimes
      self.activityFeed = newValue.activityFeed
    }
  }
}

let appReducer: (inout AppState, AppAction) -> Void = combine(
    pullback(counterReducer, value: \.count, action: \.counter),
    pullback(primeModalReducer, value: \.self, action: \.primeModal),
    pullback(favoritePrimesReducer, value: \.favoritePrimesState, action: \.favoritePrimes)
)
