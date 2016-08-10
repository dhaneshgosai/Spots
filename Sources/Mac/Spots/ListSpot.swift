import Cocoa
import Sugar
import Brick

public class ListSpot: NSObject, Listable {

  public struct Key {
    public static let titleSeparator = "titleSeparator"
    public static let titleFontSize = "titleFontSize"
    public static let titleTopInset = "titleTopInset"
    public static let titleBottomInset = "titleBottomInset"
    public static let titleLeftInset = "titleLeftInset"
    public static let contentInsetsTop = "insetTop"
    public static let contentInsetsLeft = "insetLeft"
    public static let contentInsetsBottom = "insetBottom"
    public static let contentInsetsRight = "insetRight"
    public static let doubleAction = "doubleClick"
  }

  public struct Default {
    public static var titleSeparator: Bool = true
    public static var titleFontSize: CGFloat = 18.0
    public static var titleLeftInset: CGFloat = 0.0
    public static var titleTopInset: CGFloat = 10.0
    public static var titleBottomInset: CGFloat = 10.0
    public static var contentInsetsTop: CGFloat = 0.0
    public static var contentInsetsLeft: CGFloat = 0.0
    public static var contentInsetsBottom: CGFloat = 0.0
    public static var contentInsetsRight: CGFloat = 0.0
  }

  public static var views = ViewRegistry()
  public static var configure: ((view: NSTableView) -> Void)?
  public static var defaultView: View.Type = ListSpotItem.self
  public static var defaultKind: StringConvertible = Component.Kind.List.string

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

  public lazy var titleView: NSTextField = NSTextField().then {
    $0.editable = false
    $0.selectable = false
    $0.bezeled = false
    $0.textColor = NSColor.grayColor()
    $0.drawsBackground = false
  }

  public lazy var tableView: NSTableView = NSTableView(frame: CGRect.zero).then {
    $0.backgroundColor = NSColor.clearColor()
    $0.allowsColumnReordering = false
    $0.allowsColumnResizing = false
    $0.allowsColumnSelection = false
    $0.allowsEmptySelection = true
    $0.allowsMultipleSelection = false
    $0.headerView = nil
    $0.selectionHighlightStyle = .None
    $0.allowsTypeSelect = true
    $0.focusRingType = .None
  }

  public lazy var tableColumn = NSTableColumn(identifier: "tableview-column").then {
    $0.maxWidth = 250
    $0.width = 250
    $0.minWidth = 150
  }

  lazy var lineView = NSView().then {
    $0.frame.size.height = 1
    $0.wantsLayer = true
    $0.layer?.backgroundColor = NSColor.grayColor().colorWithAlphaComponent(0.2).CGColor
  }

  public required init(component: Component) {
    self.component = component
    super.init()

    scrollView.contentView.addSubview(tableView)
    configureLayout(component)
  }

  public convenience init(cacheKey: String) {
    let stateCache = SpotCache(key: cacheKey)

    self.init(component: Component(stateCache.load()))
    self.stateCache = stateCache
  }

  deinit {
    tableView.setDelegate(nil)
    tableView.setDataSource(nil)
  }

  public func doubleAction(sender: AnyObject?) {
    guard let viewModel = item(tableView.clickedRow)
    where component.meta(Key.doubleAction, type: Bool.self) == true else { return }
    spotsDelegate?.spotDidSelectItem(self, item: viewModel)
  }

  public func action(sender: AnyObject?) {
    guard let viewModel = item(tableView.clickedRow)
      where component.meta(Key.doubleAction, false) == false else { return }
    spotsDelegate?.spotDidSelectItem(self, item: viewModel)
  }

  public func render() -> ScrollView {
    return scrollView
  }

  public func layout(size: CGSize) {
    scrollView.contentInsets.top = component.meta(Key.contentInsetsTop, Default.contentInsetsTop)
    scrollView.contentInsets.left = component.meta(Key.contentInsetsLeft, Default.contentInsetsLeft)
    scrollView.contentInsets.bottom = component.meta(Key.contentInsetsBottom, Default.contentInsetsBottom)
    scrollView.contentInsets.right = component.meta(Key.contentInsetsRight, Default.contentInsetsRight)

    if component.title.isPresent {
      configureTitleView()
    }

    tableView.sizeToFit()
    scrollView.frame.size.width = size.width
    scrollView.frame.size.height = tableView.frame.height + scrollView.contentInsets.top + scrollView.contentInsets.bottom
  }

  public func setup(size: CGSize) {
    component.items.enumerate().forEach {
      component.items[$0.index].size.width = size.width
    }

    tableView.setDelegate(listAdapter)
    tableView.setDataSource(listAdapter)
    tableView.target = self
    tableView.addTableColumn(tableColumn)
    tableView.action = #selector(self.action(_:))
    tableView.doubleAction = #selector(self.doubleAction(_:))
    tableView.sizeToFit()

    if component.title.isPresent {
      scrollView.addSubview(titleView)
      if component.meta(Key.titleSeparator, Default.titleSeparator) {
        scrollView.addSubview(lineView)
      }
      configureTitleView()
    }

    layout(size)
    ListSpot.configure?(view: tableView)
  }

  private func configureTitleView() {
    titleView.stringValue = component.title
    titleView.font = NSFont.systemFontOfSize(component.meta(Key.titleFontSize, Default.titleFontSize))
    titleView.sizeToFit()
    titleView.enabled = false
    titleView.frame.origin.x = tableView.frame.origin.x + component.meta(Key.titleLeftInset, Default.titleLeftInset)
    scrollView.contentInsets.top += titleView.frame.size.height * 2
    titleView.frame.origin.y = titleView.frame.size.height / 2

    lineView.frame.size.width = scrollView.frame.size.width - (component.meta(Key.titleLeftInset, Default.titleLeftInset) * 2)
    lineView.frame.origin.x = component.meta(Key.titleLeftInset, Default.titleLeftInset)
    lineView.frame.origin.y = titleView.frame.maxY + 8
  }
}