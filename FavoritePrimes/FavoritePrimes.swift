import Combine
import ComposableArchitecture
import UIKit
public enum FavoritePrimesAction {
    case deleteFavoritePrimes(IndexSet)
    case loadButtonTapped
    case saveButtonTapped
    case favoritePrimesLoaded([Int])
}

public func favoritePrimesReducer(state: inout [Int], action: FavoritePrimesAction) -> [Effect<FavoritePrimesAction>] {
    switch action {
    case let .deleteFavoritePrimes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
        return []
    case .loadButtonTapped:
        return [loadEffect]
    case .saveButtonTapped:
        return [saveEffect(favoritePrimes: state)]
    case let .favoritePrimesLoaded(primes):
        state = primes
        return []
    }
}

private let loadEffect: Effect<FavoritePrimesAction> = { callback in
    let documentsPath = NSSearchPathForDirectoriesInDomains(
        .documentDirectory, .userDomainMask, true
    )[0]
    let documentsUrl = URL(fileURLWithPath: documentsPath)
    let favoritePrimesUrl = documentsUrl
        .appendingPathComponent("favorite-primes.json")
    guard
        let data = try? Data(contentsOf: favoritePrimesUrl),
        let favoritePrimes = try? JSONDecoder().decode([Int].self, from: data)
    else { return }
    return callback(.favoritePrimesLoaded(favoritePrimes))
}

private func saveEffect(favoritePrimes: [Int]) -> Effect<FavoritePrimesAction> {
    return { _ in
        let data = try! JSONEncoder().encode(favoritePrimes)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        )[0]
        let documentsUrl = URL(fileURLWithPath: documentsPath)
        try! data.write(to: documentsUrl.appendingPathComponent("favorite-primes.json"))
    }
}

public class FavoritePrimesViewController: UITableViewController {
    public var store: StateStore<[Int], FavoritePrimesAction> = .needInject
    var cancelable: Cancellable?
    lazy var dataSource = UITableViewDiffableDataSource<Int, Int>(tableView: tableView) { _, _, itemIdentifier in
        let cell = UITableViewCell()
        cell.textLabel?.text = itemIdentifier.description
        return cell
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorite Primes"
        tableView.dataSource = dataSource
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Save", style: .plain,
                            target: self,
                            action: #selector(didTapSaveButton)),
            UIBarButtonItem(title: "Load", style: .plain,
                            target: self,
                            action: #selector(didTapLoadButton)),
        ]
    }

    override public func viewWillAppear(_ animated: Bool) {
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

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelable?.cancel()
    }

    override public func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        UISwipeActionsConfiguration(
            actions:
            [
                UIContextualAction(
                    style: .destructive,
                    title: "delete"
                ) { [self] _, _, callback in
                    self.store.send(.deleteFavoritePrimes(IndexSet(integer: indexPath.row)))
                    callback(true)
                },
            ])
    }

    private static func makeSnapShot(_ state: [Int]) -> NSDiffableDataSourceSnapshot<Int, Int> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(state, toSection: 0)
        return snapshot
    }

    @objc func didTapSaveButton() {
        store.send(.saveButtonTapped)
    }

    @objc func didTapLoadButton() {
        store.send(.loadButtonTapped)
    }
}
