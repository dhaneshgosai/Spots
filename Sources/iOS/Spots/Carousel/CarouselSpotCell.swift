import UIKit
import Imaginary
import Sugar

class CarouselSpotCell: UICollectionViewCell, Itemble {

  var size = CGSize(width: 88, height: 88)
  var item: ListItem?

  var label: UILabel = {
    let label = UILabel(frame: CGRect(x: 0, y: 0,
      width: 200,
      height: 200))
    label.textAlignment = .Center
    return label
    }()

  lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.autoresizingMask = [.FlexibleWidth]
    imageView.contentMode = .ScaleAspectFill
    return imageView
    }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    [imageView, label].forEach { contentView.addSubview($0) }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(inout item: ListItem) {
    if !item.image.isEmpty {
      imageView.setImage(NSURL(string: item.image))
    }

    imageView.frame = contentView.frame
    label.text = item.title
  }
}
