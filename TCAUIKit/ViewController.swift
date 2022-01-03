//
/* 
 *		Created by 游宗諭 in 2022/1/3
 *
 *		Using Swift 5.0
 *
 *		Running on macOS 12.1
 */


import UIKit
import Combine

struct AppState {
    
}
class Box<Value>: Publisher {
    internal init(getter: @escaping () -> Value, setter: @escaping (Value) -> Void) {
        self.getter = getter
        self.setter = setter
        subject = .init(getter())
    }
    let getter: () -> Value
    let setter: (Value) -> Void
    var value: Value {
        get {getter()}
        set {
            setter(newValue)
            subject.value = getter()
        }
    }
    typealias Output = Value
    typealias Failure = Never
    let subject: CurrentValueSubject<Value, Never>
    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Value == S.Input {
        subject.receive(subscriber: subscriber)
    }
}


class ViewController: UITableViewController {
    lazy var dataSource: UITableViewDiffableDataSource<Int, Row> = UITableViewDiffableDataSource<Int, Row>(tableView: tableView) { tableView, indexPath, itemIdentifier in
        let cell = UITableViewCell()
        cell.textLabel?.text = itemIdentifier.text
        return cell
    }
    struct Row: Equatable, Hashable{
        static func == (lhs: ViewController.Row, rhs: ViewController.Row) -> Bool {
            lhs.text == rhs.text
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(text)
        }
        
        var id: String {text}
        let text: String
        let link: () -> UIViewController
    }
    var count = 0
    lazy var rows = [Row(text: "Counter demo", link: {
        let vc = CounterViewController.make(from: .main, id: "CounterViewController")
        vc.countBox = Box {self.count} setter: {self.count = $0}
        return vc
    }),
                     Row(text: "Favorite primes", link: {
        UIViewController()
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


class CounterViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    var countBox: Box<Int>!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var nthPrimeButton: UIButton!
    var cancelable: Cancellable?
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Counter demo"
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cancelable = countBox.sink{ [label, nthPrimeButton]
            count in
            label?.text = count.description
            nthPrimeButton?.setTitle("What is the \(ordinal(count)) prime?", for: .normal)}
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelable?.cancel()
    }
    @IBAction func didTapPlusButton(_ sender: UIButton) {
        countBox.value += 1
    }
    @IBAction func didTapDownButton(_ sender: UIButton) {
        countBox.value -= 1
    }
    @IBAction func didTapIsThisPrimeButton(_ sender: UIButton) {
    }
    @IBAction func didTapWhatNthPrimeButton(_ sender: UIButton) {
    }
}

extension UIViewController {
    class func make(from storyboard: UIStoryboard, id: String) -> Self {
        storyboard.instantiateViewController(withIdentifier: id) as! Self
    }
}
extension UIStoryboard {
    static var main: UIStoryboard {
        UIStoryboard(name: "Main", bundle: .main)
    }
}

private func isPrime (_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}

class IsPrimeModelViewController: UIViewController {
    
}
