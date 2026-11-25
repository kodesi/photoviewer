//
//  SliderViewController.swift
//  Plugin
//
//  Created by  Quéau Jean Pierre on 25/02/2021.
//  Copyright © 2021 Max Lynch. All rights reserved.
//
import UIKit

import SDWebImage

// swiftlint:disable file_length

extension NSNotification.Name {
    static var movieCompleted: Notification.Name {
        return .init(rawValue: "movieCompleted")}
}

// swiftlint:disable type_body_length
class SliderViewController: UIViewController {

    private var _numCells: CGFloat = 3
    private var _numImages: Int = 0
    private var _mode: String = "slider"
    private var _imageList: [[String: String]] = []
    private var _options: [String: Any] = [:]
    private var _position: IndexPath = [0, 0]
    private var _selectedPosition: IndexPath?
    private var _isShare: Bool = true
    private var _isFilm: Bool = false
    private var _isLaidOut: Bool = false
    private var _didScrollToStart: Bool = false
    private var _maxZoomScale: Double = 3
    private var _compressionQuality: Double = 0.8
    private var _movieOptions: [String: Any] = [:]
    private var _movieObserver: Any?
    private var _backgroundColor: String = "black"
    private var _backColor: BackgroundColor = BackgroundColor()
    private var _colorRange: [String] = ["white", "ivory", "lightgrey"]
    private var _btColor: UIColor = UIColor.white

    // MARK: - Set-up position

    var position: IndexPath {
        get {
            return self._position
        }
        set {
            self._position = newValue
        }
    }

    // MARK: - Set-up imageList

    var imageList: [[String: String]] {
        get {
            return self._imageList
        }
        set {
            self._imageList = newValue
            self._numImages = self._imageList.count
        }
    }

    // MARK: - Set-up mode

    var mode: String {
        get {
            return self._mode
        }
        set {
            self._mode = newValue
        }
    }

    // MARK: - Set-up options

    var options: [String: Any] {
        get {
            return self._options
        }
        set {
            self._options = newValue
            if self._options.keys.contains("share") {
                if let isShare = self._options["share"] as? Bool {
                    self._isShare = isShare
                }
            }
            if self._options.keys.contains("maxzoomscale") {
                if let maxZoomScale = self._options["maxzoomscale"] as? Double {
                    self._maxZoomScale = maxZoomScale
                }
            }
            if self._options.keys.contains("compressionquality") {
                if let compressionQuality = self._options["compressionquality"]
                    as? Double {
                    self._compressionQuality = compressionQuality
                }
            }
            if self._options.keys.contains("movieoptions") {
                if let movieOptions: [String: Any] = self._options["movieoptions"]
                    as? [String: Any] {
                    self._movieOptions = movieOptions
                    self._isFilm = true
                }
            }
            if self._options.keys.contains("backgroundcolor") {
                if let backgroundColor = self._options["backgroundcolor"]
                    as? String {
                    self._backgroundColor = backgroundColor
                    if _colorRange.contains(_backgroundColor) {
                        _btColor = UIColor.black
                    }
                }
            }
        }
    }

    // MARK: - Set-up Navigation Items

    lazy var navBar: UINavigationBar = { () -> UINavigationBar in

        let navigationBar = UINavigationBar(
            frame: CGRect(x: 0, y: 35, width: view.frame.size.width, height: 64))
        navigationBar.isTranslucent = true
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        let navigationItem = UINavigationItem()
        if self._isFilm {
            navigationItem.rightBarButtonItems = [mClose, mFilm]
        } else {
            navigationItem.rightBarButtonItem = mClose
        }
        if self._isShare {
            navigationItem.leftBarButtonItem = mShare
        }
        navigationBar.setItems([navigationItem], animated: false)
        return navigationBar
    }()
    lazy var mClose: UIBarButtonItem = {
        let bClose = UIBarButtonItem()
        let image: UIImage?
        let configuration = UIImage.SymbolConfiguration(scale: .large)
        image = UIImage(systemName: "multiply",
                        withConfiguration: configuration)
        bClose.image = image?.withTintColor(_btColor, renderingMode: .alwaysOriginal)
        bClose.tintColor = _btColor
        bClose.action = #selector(closeButtonTapped)
        return bClose
    }()
    lazy var  mShare: UIBarButtonItem = {
        let bShare = UIBarButtonItem()
        let image: UIImage?
        let configuration = UIImage.SymbolConfiguration(scale: .large)
        image = UIImage(systemName: "square.and.arrow.up",
                        withConfiguration: configuration)
        bShare.image = image?.withTintColor(_btColor, renderingMode: .alwaysOriginal)
        bShare.tintColor = _btColor
        bShare.action = #selector(shareButtonTapped)
        return bShare

    }()

    lazy var  mFilm: UIBarButtonItem = {
        let bFilm = UIBarButtonItem()
        let image: UIImage?
        let configuration = UIImage.SymbolConfiguration(scale: .large)
        image = UIImage(systemName: "film",
                        withConfiguration: configuration)
        bFilm.image = image?.withTintColor(_btColor, renderingMode: .alwaysOriginal)
        bFilm.tintColor = _btColor
        bFilm.action = #selector(filmButtonTapped)
        return bFilm

    }()

    // MARK: - Set-up Layout

    lazy var layout: UICollectionViewFlowLayout = { () -> UICollectionViewFlowLayout in
        let mLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        mLayout.minimumLineSpacing = 0
        mLayout.minimumInteritemSpacing = 0
        return mLayout
    }()

    // MARK: - Set-up collectionView

    lazy var collectionView: UICollectionView = {
        let mColView = UICollectionView(
            frame: .zero, collectionViewLayout: layout)
        mColView.register(SliderViewCell.self, forCellWithReuseIdentifier: SliderViewCell.identifier)
        mColView.dataSource = self
        mColView.delegate = self
        mColView.isPagingEnabled = true
        return mColView
    }()

    // MARK: - Deinit

    deinit {
        NotificationCenter.default
            .removeObserver(self._movieObserver as Any)
    }

    // MARK: - loadView

    override func loadView() {
        view = UIView()
        let screenSize: CGRect = UIScreen.main.bounds
        view.frame.size.width = screenSize.width
        view.frame.size.height = screenSize.height
        view.sizeToFit()
        view.backgroundColor = _backColor.setBackColor(color: _backgroundColor)
        self._movieObserver = NotificationCenter.default
            .addObserver(forName: .movieCompleted, object: nil,
                         queue: nil, using: movieCompleted)
    }

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        // also control the status bar when presented over full screen (gallery mode)
        modalPresentationCapturesStatusBarAppearance = true
        setupGestureRecognizers()
    }

    // MARK: - Status bar

    // Like the one-photo viewer: no status bar, and the X button always stays visible
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - viewWillAppear

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !_isLaidOut {
            view.addSubview(collectionView)
            view.addSubview(navBar)
            setupCollectionViewConstraints()
            _isLaidOut = true
        }
    }

    // MARK: - viewDidDisappear

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        destroyAllGestures()
    }

    // MARK: - viewWillLayoutSubviews

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateLayout(view.frame.size)
        self.navBar.frame = CGRect(x: 0, y: 35,
                                   width: view.frame.size.width, height: 64)
    }

    // MARK: - viewDidLayoutSubviews

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Open on the requested photo once. Scrolling to it on every layout pass would snap the
        // pager back while the user swipes or zooms.
        if !_didScrollToStart && collectionView.bounds.width > 0 {
            _didScrollToStart = true
            collectionView.layoutIfNeeded()
            scrollToPage(position.row)
        }
    }

    // MARK: - setupCollectionViewConstraints

    private func setupCollectionViewConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor
            .constraint(equalTo: view.topAnchor)
            .isActive = true
        collectionView.leadingAnchor
            .constraint(equalTo: view.leadingAnchor)
            .isActive = true
        collectionView.trailingAnchor
            .constraint(equalTo: view.trailingAnchor)
            .isActive = true
        collectionView.bottomAnchor
            .constraint(equalTo: view.bottomAnchor)
            .isActive = true
    }

    // MARK: - updateLayout

    private func updateLayout(_ size: CGSize) {
        layout.scrollDirection = .horizontal
        if layout.itemSize != size {
            layout.itemSize = size
        }
    }

    // MARK: - Current page

    private var currentPage: Int {
        var mPosition = self.position
        if let selPos = self._selectedPosition {
            mPosition = selPos
        }
        return mPosition.row
    }

    private var currentCell: SliderViewCell? {
        return collectionView.cellForItem(at: IndexPath(row: currentPage, section: 0))
            as? SliderViewCell
    }

    private func scrollToPage(_ page: Int) {
        guard _numImages > 0 else { return }
        let mPage = min(max(page, 0), _numImages - 1)
        collectionView.contentOffset = CGPoint(
            x: CGFloat(mPage) * collectionView.bounds.width, y: 0)
    }

    private func updateSelectedPosition() {
        let width = collectionView.bounds.width
        guard width > 0, _numImages > 0 else { return }
        let page = Int((collectionView.contentOffset.x / width).rounded())
        _selectedPosition = IndexPath(row: min(max(page, 0), _numImages - 1), section: 0)
    }

    // MARK: - viewWillTransition

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Keep the current photo, centred at 1x
        let page = currentPage
        for case let cell as SliderViewCell in collectionView.visibleCells {
            cell.resetZoom()
        }
        coordinator.animate(alongsideTransition: { _ in
            self.updateLayout(size)
            self.view.layoutIfNeeded()
            self.scrollToPage(page)
            self.navBar.frame = CGRect(x: 0, y: 35,
                                       width: size.width, height: 64)
        })
    }

    // MARK: - closeButtonTapped

    @objc func closeButtonTapped() {
        if mode == "slider" {
            var mPosition = self.position
            if let selPos = self._selectedPosition {
                mPosition = selPos
            }
            let vId: [String: Any] =
                ["result": true,
                 "imageIndex": mPosition.row as Any
                ]
            NotificationCenter.default.post(name: .photoviewerExit,
                                            object: nil,
                                            userInfo: vId)
        }
        self.dismissWithTransition(swipeDirection: "no")
    }

    // MARK: - shareButtonTapped

    @objc func shareButtonTapped() {
        var mPosition = self.position
        if let selPos = self._selectedPosition {
            mPosition = selPos
        }
        if let imageUrl: String = self.imageList[mPosition.row]["url"] {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            if imageUrl.prefix(4) == "http" || imageUrl.contains("base64") {
                imageView.sd_setImage(with: URL(string: imageUrl),
                                      placeholderImage: nil)
            }
            if imageUrl.prefix(38) ==
                "file:///var/mobile/Media/DCIM/100APPLE" ||
                imageUrl.prefix(38) ==
                "capacitor://localhost/_capacitor_file_" {

                let image: UIImage = UIImage()
                imageView.image = image.getImage(path: imageUrl,
                                                 placeHolder: "livephoto.slash")
            }

            if let image = imageView.image {
                if let data = image.jpegData(compressionQuality:
                                                CGFloat(_compressionQuality)) {
                    let avc = UIActivityViewController(activityItems: [data],
                                                       applicationActivities: [])
                    present(avc, animated: true)
                }
            } else {
                print("No imgage available")
            }
        } else {
            print("No url available")
        }
    }

    // MARK: - filmButtonTapped

    @objc func filmButtonTapped() {
        let imagesToVideo: ImagesToVideo = ImagesToVideo()
        imagesToVideo.imageList = self.imageList
        imagesToVideo.options = self._movieOptions

        //        DispatchQueue.global(qos: .userInitiated).async { [] in
        imagesToVideo.createFilm()
        //        }

    }

    // MARK: - swipeAction

    @objc func swipeAction(swipe: UISwipeGestureRecognizer) {
        if mode == "slider" {
            var mPosition = self.position
            if let selPos = self._selectedPosition {
                mPosition = selPos
            }
            let vId: [String: Any] =
                ["result": true,
                 "imageIndex": mPosition.row as Any
                ]
            NotificationCenter.default.post(name: .photoviewerExit,
                                            object: nil,
                                            userInfo: vId)
        }
        if swipe.direction == .up {
            // Slide-up gesture
            dismissWithTransition(swipeDirection: "up")
        } else if swipe.direction == .down {
            // Slide-down gesture
            dismissWithTransition(swipeDirection: "down")
        }
    }

    // MARK: - Handle Notifications

    @objc func movieCompleted(notification: Notification) {
        guard let info = notification.userInfo as? [String: Any]
        else { return }
        DispatchQueue.main.async { [self] in
            if let res = info["result"] as? Bool {
                if res {
                    let msg = "Movie created"
                    self.showToast( message: msg,
                                    font: .systemFont(ofSize: 16.0))
                } else {
                    let msg = "Movie failed"
                    self.showToast( message: msg,
                                    font: .systemFont(ofSize: 16.0))
                }
            }
        }
    }

    // MARK: - setupGestureRecognizers

    private func setupGestureRecognizers() {
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeAction(swipe:)))
        upSwipe.direction = UISwipeGestureRecognizer.Direction.up
        upSwipe.delegate = self
        view.addGestureRecognizer(upSwipe)
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeAction(swipe:)))
        downSwipe.direction = UISwipeGestureRecognizer.Direction.down
        downSwipe.delegate = self
        view.addGestureRecognizer(downSwipe)
    }

    // MARK: - destroyAllGestures

    func destroyAllGestures() {
        view.gestureRecognizers?.removeAll()
    }
}
// swiftlint:enable type_body_length

// MARK: - Extensions

extension SliderViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
        return _numImages
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {

        let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: SliderViewCell
                                    .identifier, for: indexPath) as? SliderViewCell

        if let mCell = cell {
            mCell.options = self.options
            if let imageUrl: String = self.imageList[indexPath.row]["url"] {
                if let title: String = self.imageList[indexPath.row]["title"] {
                    mCell.configure(imageUrl: imageUrl, title: title)
                    return mCell
                } else {
                    mCell.configure(imageUrl: imageUrl, title: "")
                    return mCell
                }
            } else {
                print("Error: image url not found")
                return UICollectionViewCell()
            }
        } else {
            print("Error: cell not found")
            return UICollectionViewCell()
        }
    }
}
extension SliderViewController: UICollectionViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedPosition()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateSelectedPosition()
        }
    }

    // A photo that leaves the screen is back at 1x when the user returns to it
    func collectionView(_ collectionView: UICollectionView,
                        didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        (cell as? SliderViewCell)?.resetZoom()
    }
}

extension SliderViewController: UIGestureRecognizerDelegate {
    // Swipe up/down closes the viewer only when the photo is at 1x: when zoomed in, a vertical
    // pan moves the photo instead
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            return !(currentCell?.isZoomed ?? false)
        }
        return true
    }
}
extension UICollectionViewFlowLayout {
    override open func shouldInvalidateLayout(forBoundsChange: CGRect) -> Bool {
        return true
    }
}
// swiftlint:enable file_length
