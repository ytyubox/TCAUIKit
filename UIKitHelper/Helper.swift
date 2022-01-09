import UIKit
public extension UIViewController {
    class func make(from storyboard: UIStoryboard, id: String) -> Self {
        storyboard.instantiateViewController(withIdentifier: id) as! Self
    }
}

public extension UIStoryboard {
    static var main: UIStoryboard {
        UIStoryboard(name: "Main", bundle: .main)
    }
}
