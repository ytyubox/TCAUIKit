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



// MARK: - ViewController

class ViewController: UITableViewController {
    let store =
        Store(initialValue:
            State(
                AppState(count: 0, favoritePrimes: [])
            )
        ) {
            state, action in
            appReducer(&state.value, action)
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
        /**
         work around for console warning: Warning once only: UITableView was told to layout its visible cells and other contents without being in the view hierarchy?
         https://stackoverflow.com/a/67848690
         xcode 13.2.1, iOS 15.2
         */
        var first = false
        cancelable = store.publisher.sink(receiveValue: { state in
            self.dataSource.apply(Self.makeSnapShot(state), animatingDifferences: first)
            first = true
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

    private static func makeSnapShot(_ state: AppState) -> NSDiffableDataSourceSnapshot<Int, Int> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(state.favoritePrimes, toSection: 0)
        return snapshot
    }
}
