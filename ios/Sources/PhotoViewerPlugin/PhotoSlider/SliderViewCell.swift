//
//  SliderViewCell.swift
//  Plugin
//
//  Created by  Quéau Jean Pierre on 25/02/2021.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

import UIKit
import SDWebImage
import ISVImageScrollView

// Each page is zoomable in place, like the one-photo viewer: pinch follows the fingers and a
// double tap (handled by ISVImageScrollView) zooms in at the tapped point or back out to 1x.
// When the photo is zoomed in, a horizontal pan moves around it first and the pager takes over
// at the edge (nested scroll views).
class SliderViewCell: UICollectionViewCell, UIScrollViewDelegate {
    static let identifier = "SliderViewCell"

    private var _options: [String: Any] = [:]
    private var _isTitle: Bool = true
    private var _maxZoomScale: CGFloat = 3.0
    private var _minZoomScale: CGFloat = 1.0
    private var _imageUrl: String?
    private var _backgroundColor: String = "black"
    private var _backColor: BackgroundColor = BackgroundColor()

    // MARK: - Set-up options

    var options: [String: Any] {
        get {
            return self._options
        }
        set {
            self._options = newValue
            if self._options.keys.contains("title") {
                if let isTitle = self._options["title"] as? Bool {
                    self._isTitle = isTitle
                }
            }
            if self._isTitle {
                contentView.addSubview(mLabel)
            }
            if self._options.keys.contains("maxzoomscale") {
                if let maxZoomScale = self._options["maxzoomscale"] as? Double {
                    self._maxZoomScale = CGFloat(maxZoomScale)
                }
            }
            mScrollView.minimumZoomScale = self._minZoomScale
            mScrollView.maximumZoomScale = self._maxZoomScale
            if self._options.keys.contains("backgroundcolor") {
                if let backgroundColor = self._options["backgroundcolor"]
                    as? String {
                    self._backgroundColor = backgroundColor
                    contentView.backgroundColor =  _backColor
                        .setBackColor(color: _backgroundColor)
                }
            } else {
                contentView.backgroundColor =  _backColor
                    .setBackColor(color: _backgroundColor)
            }
        }
    }

    // MARK: - Zoom state

    var isZoomed: Bool {
        return mScrollView.zoomScale > self._minZoomScale
    }

    func resetZoom() {
        mScrollView.setZoomScale(self._minZoomScale, animated: false)
    }

    // MARK: - Set-up Views

    lazy var mImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    lazy var mScrollView: ISVImageScrollView = {
        let scrollView = ISVImageScrollView()
        scrollView.delegate = self
        return scrollView
    }()
    lazy var mLabel: UILabel = {
        let label = UILabel()
        label.text = "title"
        label.textAlignment = .center
        label.clipsToBounds = true
        label.textColor = .lightGray
        label.font = UIFont(name: "HelveticaNeue-Bold", size: 18.0)
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(mScrollView)
        contentView.clipsToBounds = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - layoutSubviews

    override func layoutSubviews() {
        super.layoutSubviews()
        if mScrollView.frame.size != contentView.bounds.size {
            // New page size (first layout or rotation): show the whole photo again at 1x
            resetZoom()
            mScrollView.frame = contentView.bounds
            if mImageView.image != nil {
                showImage()
            }
        }
        mLabel.frame = CGRect(x: 5, y: contentView.bounds.size.height-100,
                              width: contentView.bounds.size.width-10, height: 100)
    }

    // MARK: - configure

    func configure(imageUrl: String, title: String) {
        _imageUrl = imageUrl
        resetZoom()
        mScrollView.frame = contentView.bounds
        if imageUrl.prefix(4) == "http" || imageUrl.contains("base64") {
            mImageView.sd_setImage(with: URL(string: imageUrl),
                                   placeholderImage: nil,
                                   completed: { [weak self] image, _, _, _ in
                                    // the cell may have been reused for another photo meanwhile
                                    guard let self = self, image != nil,
                                          self._imageUrl == imageUrl else { return }
                                    self.showImage()
                                   })
        }
        if imageUrl.prefix(38) ==
            "file:///var/mobile/Media/DCIM/100APPLE" ||
            imageUrl.prefix(38) ==
            "capacitor://localhost/_capacitor_file_" {

            let image: UIImage = UIImage()
            self.mImageView.image = image.getImage(path: imageUrl,
                                                   placeHolder: "livephoto.slash")
            showImage()
        }

        mLabel.text = title
    }

    // (Re)assigning the image view makes ISVImageScrollView fit it to the page at 1x
    private func showImage() {
        resetZoom()
        mScrollView.imageView = mImageView
        mScrollView.setNeedsLayout()
    }

    // MARK: - prepareForReuse

    override func prepareForReuse() {
        super.prepareForReuse()
        mImageView.sd_cancelCurrentImageLoad()
        _imageUrl = nil
        resetZoom()
        mImageView.image = nil
        mLabel.text = nil
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mScrollView.imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // no shrinking below the whole photo
        if scrollView.zoomScale < self._minZoomScale {
            scrollView.zoomScale = self._minZoomScale
        }
    }
}
