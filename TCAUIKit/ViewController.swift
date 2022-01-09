//
/*
 *		Created by 游宗諭 in 2022/1/3
 *
 *		Using Swift 5.0
 *
 *		Running on macOS 12.1
 */

import Combine
import ComposableArchitecture
import Counter
import FavoritePrimes
import PrimeModal
import UIKit

// MARK: - ViewController

class ViewController: UITableViewController {
    let store: StateStore<AppState, AppAction> =
        Store(initialValue:
            .hot(
                AppState(count: 0, favoritePrimes: [])
            )
        ) {
            state, action in
            AppReducer(&state.value, action)
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

    lazy var rows = [
        Row(text: "Counter demo") {
            let vc = CounterViewController.make(from: .main, id: "CounterViewController")
            vc.store = self.store.view(
                value: { ($0.count, $0.favoritePrimes) },
                action: {
                    switch $0 {
                    case let .primeModal(action): return .primeModal(action)
                    case let .counter(action): return .counter(action)
                    }
                }
            )
            return vc
        },
        Row(text: "Favorite primes") {
            let vc = FavoritePrimesViewController()
            vc.store = self.store.view(
                value: \.favoritePrimes,
                action: { .favoritePrimes($0) }
            )
            return vc
        },
    ]

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
