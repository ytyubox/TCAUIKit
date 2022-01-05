//
/*
 *		Created by 游宗諭 in 2022/1/3
 *
 *		Using Swift 5.0
 *
 *		Running on macOS 12.1
 */

import Combine
import UIKit

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
}

func appReducer(value: inout AppState, action: AppAction) {
    switch action {
    case .counter(.decrTapped):
        value.count -= 1

    case .counter(.incrTapped):
        value.count += 1

    case .primeModal(.saveFavoritePrimeTapped):
        value.favoritePrimes.append(value.count)
        value.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(value.count)))

    case .primeModal(.removeFavoritePrimeTapped):
        value.favoritePrimes.removeAll(where: { $0 == value.count })
        value.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(value.count)))

    case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
        for index in indexSet {
            let prime = value.favoritePrimes[index]
            value.favoritePrimes.remove(at: index)
            value.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
        }
    }
}

// MARK: - ViewController

class ViewController: UITableViewController {
    let store =
        Store(initialValue: State(AppState(count: 0, favoritePrimes: []))) {
            state, action in
            appReducer(value: &state.value, action: action)
        }

    lazy var dataSource = UITableViewDiffableDataSource<Int, Row>(tableView: tableView) { _, _, itemIdentifier in
        let cell = UITableViewCell()
        cell.textLabel?.text = itemIdentifier.text
        return cell
    }

    struct Row: Equatable, Hashable {
        static func == (lhs: ViewController.Row, rhs: ViewController.Row) -> Bool {
            lhs.text == rhs.text
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(text)
        }

        var id: String { text }
        let text: String
        let link: () -> UIViewController
    }

    lazy var rows = [Row(text: "Counter demo", link: {
        let vc = CounterViewController.make(from: .main, id: "CounterViewController")
        vc.store = self.store
        return vc
    }),
    Row(text: "Favorite primes", link: {
        let vc = FavoritePrimesViewController()
        vc.store = self.store
        return vc
    })]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "State management"
        var snapshot = NSDiffableDataSourceSnapshot<Int, Row>()
        snapshot.appendSections([0])
        snapshot.appendItems(rows, toSection: 0)

        tableView.dataSource = dataSource
        dataSource.apply(snapshot)
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedItem = dataSource.itemIdentifier(for: indexPath) else { return }
        let vc = selectedItem.link()
        navigationController?.pushViewController(vc, animated: true)
    }
}

private func ordinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}

// MARK: - CounterViewController

class CounterViewController: UIViewController {
    var store: Store<State<AppState>, AppAction> = .needInject
    @IBOutlet private var label: UILabel!
    @IBOutlet private var nthPrimeButton: UIButton!
    var cancelable: Cancellable?
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Counter demo"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cancelable = store.publisher.sink { [self] state in
            label?.text = state.count.description
            nthPrimeButton?.setTitle("What is the \(ordinal(state.count)) prime?", for: .normal)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
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
        vc.store = store
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

private func isPrime(_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2 ... Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}

// MARK: - IsPrimeModelViewController

class IsPrimeModelViewController: UIViewController {
    var store: Store<State<AppState>, AppAction> = .needInject
    @IBOutlet var label: UILabel!
    @IBOutlet var button: UIButton!

    override func viewDidLoad() {
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
            store.send(.primeModal(.removeFavoritePrimeTapped))
        } else {
            store.send(.primeModal(.saveFavoritePrimeTapped))
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

// MARK: - FavoritePrimesViewController

class FavoritePrimesViewController: UITableViewController {
    var store: Store<State<AppState>, AppAction> = .needInject
    var cancelable: Cancellable?
    lazy var dataSource = UITableViewDiffableDataSource<Int, Int>(tableView: tableView) { _, _, itemIdentifier in
        let cell = UITableViewCell()
        cell.textLabel?.text = itemIdentifier.description
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorite Primes"
        tableView.dataSource = dataSource
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cancelable = store.publisher.sink(receiveValue: { state in
            self.dataSource.apply(makeSnapShot(state))
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelable?.cancel()
    }

    override func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        UISwipeActionsConfiguration(
            actions:
            [
                UIContextualAction(
                    style: .destructive,
                    title: "delete"
                ) { [self] _, _, callback in
                    self.store.send(.favoritePrimes(.deleteFavoritePrimes(IndexSet(integer: indexPath.row))))
                    callback(true)
                },
            ])
    }
}

func nthPrime(_ n: Int, callback: @escaping (Int?) -> Void) {
    wolframAlpha(query: "prime \(n)") { result in
        callback(
            result
                .flatMap {
                    $0.queryresult
                        .pods
                        .first(where: { $0.primary == .some(true) })?
                        .subpods
                        .first?
                        .plaintext
                }
                .flatMap(Int.init)
        )
    }
}

// MARK: - WolframAlphaResult

struct WolframAlphaResult: Decodable {
    let queryresult: QueryResult

    struct QueryResult: Decodable {
        let pods: [Pod]

        struct Pod: Decodable {
            let primary: Bool?
            let subpods: [SubPod]

            struct SubPod: Decodable {
                let plaintext: String
            }
        }
    }
}

func wolframAlpha(query: String, callback: @escaping (WolframAlphaResult?) -> Void) {
    var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
    components.queryItems = [
        URLQueryItem(name: "input", value: query),
        URLQueryItem(name: "format", value: "plaintext"),
        URLQueryItem(name: "output", value: "JSON"),
        URLQueryItem(name: "appid", value: wolframAlphaApiKey),
    ]

    URLSession.shared.dataTask(with: components.url(relativeTo: nil)!) { data, _, _ in
        callback(
            data
                .flatMap { try? JSONDecoder().decode(WolframAlphaResult.self, from: $0) }
        )
    }
    .resume()
}

private func makeSnapShot(_ state: AppState) -> NSDiffableDataSourceSnapshot<Int, Int> {
    var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
    snapshot.appendSections([0])
    snapshot.appendItems(state.favoritePrimes, toSection: 0)
    return snapshot
}
