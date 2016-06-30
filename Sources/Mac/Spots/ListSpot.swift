import Cocoa
import Sugar
import Brick

public class ListSpot: NSObject, Listable {

  struct Key {
    static let contentInsetsTop = "insetTop"
    static let contentInsetsLeft = "insetLeft"
    static let contentInsetsBottom = "insetBottom"
    static let contentInsetsRight = "insetRight"
    static let doubleAction = "doubleClick"
  }

  public struct Default {
    public static var contentInsetsTop: CGFloat = 0.0
    public static var contentInsetsLeft: CGFloat = 0.0
    public static var contentInsetsBottom: CGFloat = 0.0
    public static var contentInsetsRight: CGFloat = 0.0
  }

  public static var views = ViewRegistry()
  public static var configure: ((view: NSTableView) -> Void)?
  public static var defaultView: View.Type = ListSpotItem.self
  public static var defaultKind: StringConvertible = "list"

  public weak var spotsDelegate: SpotsDelegate?

  public var cachedViews = [String : SpotConfigurable]()
  public var component: Component
  public var configure: (SpotConfigurable -> Void)?
  public var index = 0

  public private(set) var stateCache: SpotCache?

  public var adapter: SpotAdapter? {
    return listAdapter
  }

  private lazy var listAdapter: ListAdapter = ListAdapter(spot: self)

  public lazy var scrollView: ScrollView = ScrollView().then {
    $0.documentView = NSView()
  }

  public lazy var tableView: NSTableView = NSTableView(frame: CGRect.zero).then {
    $0.allowsColumnReordering = false
    $0.allowsColumnResizing = false
    $0.allowsColumnSelection = false
    $0.allowsEmptySelection = true
    $0.allowsMultipleSelection = false
    $0.headerView = nil
    $0.selectionHighlightStyle = .None
  }

  public required init(component: Component) {
    self.component = component
    super.init()

    setupTableView()
    scrollView.contentView.addSubview(tableView)
    configureLayout(component)
  }

  public convenience init(cacheKey: String) {
    let stateCache = SpotCache(key: cacheKey)

    self.init(component: Component(stateCache.load()))
    self.stateCache = stateCache
  }

  public func setupTableView() {
    tableView.setDelegate(listAdapter)
    tableView.setDataSource(listAdapter)
    tableView.target = self
    tableView.doubleAction = #selector(self.doubleAction(_:))
  }

  public func doubleAction(sender: AnyObject?) {
    guard component.meta("doubleClick", type: Bool.self) == true else { return }
    let viewModel = item(tableView.selectedRow)
    spotsDelegate?.spotDidSelectItem(self, item: viewModel)
  }

  public func render() -> ScrollView {
    return scrollView
  }

  public func layout(size: CGSize) { }
  public func prepare() { }

  public func setup(size: CGSize) {
    component.items.enumerate().forEach {
      component.items[$0.index].size.width = size.width
    }

    tableView.sizeToFit()
    scrollView.frame.size.height = tableView.frame.height
    scrollView.frame.size.width = size.width
    ListSpot.configure?(view: tableView)
  }
}
