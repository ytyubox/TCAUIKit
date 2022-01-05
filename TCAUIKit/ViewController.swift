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
    var count: Int
    var favoritePrimes: [Int]
}

// MARK: - ViewController

class ViewController: UITableViewController {
    let state = State(AppState(count: 0, favoritePrimes: []))
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
        vc.state = self.state
        return vc
    }),
    Row(text: "Favorite primes", link: {
        let vc = FavoritePrimesViewController()
        vc.state = self.state
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    var state: State<AppState> = .needInject
    @IBOutlet private var label: UILabel!
    @IBOutlet private var nthPrimeButton: UIButton!
    var cancelable: Cancellable?
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Counter demo"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cancelable = state.publisher.sink { [self] state in
            label?.text = state.count.description
            nthPrimeButton?.setTitle("What is the \(ordinal(state.count)) prime?", for: .normal)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelable?.cancel()
    }

    @IBAction func didTapPlusButton(_ sender: UIButton) {
        state.count += 1
    }

    @IBAction func didTapDownButton(_ sender: UIButton) {
        state.count -= 1
    }

    @IBAction func didTapIsThisPrimeButton(_ sender: UIButton) {
        let vc = IsPrimeModelViewController.make(from: .main, id: "IsPrimeModelViewController")
        vc.state = state
        present(vc, animated: true, completion: nil)
    }

    @IBAction func didTapWhatNthPrimeButton(_ sender: UIButton) {
        nthPrimeButton.isEnabled = false
        nthPrime(state.count) { prime in
            DispatchQueue.main.async {
                if let prime = prime {
                    let alert = UIAlertController(title: "The \(ordinal(self.state.count)) prime is \(prime)", message: nil, preferredStyle: .alert)
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
    var state: State<AppState>!
    @IBOutlet var label: UILabel!
    @IBOutlet var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        if isPrime(state.count) {
            label.text = "\(String(describing: state.count)) is prime 🎉"
            updateButton()

        } else {
            label.text = "\(String(describing: state.count)) is not prime :("
            button.isHidden = true
        }
    }

    @IBAction func didTapSaveButton(_ sender: UIButton) {
        if state.favoritePrimes.contains(state.count) {
            state.favoritePrimes.removeAll(where: { $0 == self.state.count })
        } else {
            state.favoritePrimes.append(state.count)
        }
        updateButton()
    }

    fileprivate func updateButton() {
        if state.favoritePrimes.contains(state.count) {
            button.setTitle("Remove from favorite primes", for: .normal)
        } else {
            button.setTitle("Save to favorite primes", for: .normal)
        }
    }
}

// MARK: - FavoritePrimesViewController

class FavoritePrimesViewController: UITableViewController {
    var state: State<AppState> = .needInject

    lazy var dataSource = UITableViewDiffableDataSource<Int, Int>(tableView: tableView) { _, _, itemIdentifier in
        let cell = UITableViewCell()
        cell.textLabel?.text = itemIdentifier.description
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorite Primes"
        let snapshot = makeSnapShot()
        tableView.dataSource = dataSource
        dataSource.apply(snapshot)
    }

    func makeSnapShot() -> NSDiffableDataSourceSnapshot<Int, Int> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(state.favoritePrimes, toSection: 0)
        return snapshot
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        UISwipeActionsConfiguration(
            actions:
            [
                UIContextualAction(
                    style: .destructive,
                    title: "delete"
                ) { [self] _, _, callback in
                    self.state.favoritePrimes.remove(at: indexPath.row)
                    dataSource.apply(makeSnapShot())
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
