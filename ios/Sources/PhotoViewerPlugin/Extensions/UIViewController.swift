//
//  UIViewController.swift
//  CapacitorCommunityPhotoviewer
//
//  Created by  Quéau Jean Pierre on 03/10/2022.
//

import UIKit
extension UIViewController {

    func showToast(message: String, font: UIFont) {

        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(_) in
            toastLabel.removeFromSuperview()
        })
    }
    // MARK: - Drag to close

    // The viewer follows a vertical drag, up or down, and fades as it goes, uncovering the page
    // (it's presented over full screen). Let go past a quarter of the screen, or flicked that
    // way, it slides off and closes; otherwise it springs back. Upstream closed on any short
    // flick (UISwipeGestureRecognizer), with no drag.
    func handleDragToClose(_ pan: UIPanGestureRecognizer, willClose: () -> Void) {
        let height = view.bounds.height
        // in window coordinates: the view itself moves with the drag
        let offset = pan.translation(in: nil).y
        switch pan.state {
        case .changed:
            view.transform = CGAffineTransform(translationX: 0, y: offset)
            view.alpha = 1 - min(abs(offset) / height, 1) * 0.6
        case .ended, .cancelled, .failed:
            let velocity = pan.velocity(in: nil).y
            let farEnough = abs(offset) > height / 4
            let flicked = abs(velocity) > 800 && (velocity > 0) == (offset > 0)
            if pan.state == .ended && offset != 0 && (farEnough || flicked) {
                willClose()
                let target = offset > 0 ? height : -height
                let duration = min(max(TimeInterval(abs(target - offset) / max(abs(velocity), 1)), 0.15), 0.3)
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
                    self.view.transform = CGAffineTransform(translationX: 0, y: target)
                    self.view.alpha = 0.4
                }, completion: { _ in
                    self.dismiss(animated: false, completion: nil)
                })
            } else {
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85,
                               initialSpringVelocity: 0, options: [.allowUserInteraction], animations: {
                                self.view.transform = .identity
                                self.view.alpha = 1
                               })
            }
        default:
            break
        }
    }

    // Starts only for a drag that is more vertical than horizontal (sideways is paging)
    func isVerticalDrag(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: nil)
        return abs(velocity.y) > abs(velocity.x)
    }

    func dismissWithTransition(swipeDirection: String) {
        // Close button and swipe down: the standard modal dismiss, which slides the viewer
        // down and uncovers the page beneath it. Upstream pushed a window-level CATransition
        // instead, which slid the page in from the top (or from the right for the close
        // button), so the page was never beneath the viewer.
        guard swipeDirection == "up",
              let window = self.view.window,
              let snapshot = self.view.snapshotView(afterScreenUpdates: false) else {
            self.dismiss(animated: true, completion: nil)
            return
        }

        // Swipe up: the mirror image, the viewer slides up and uncovers the page. The page is
        // only back in the window once the viewer is dismissed, so a snapshot of the viewer is
        // laid over the window (zPosition keeps it above the page whatever order UIKit puts the
        // views back in) and animated away after a non-animated dismiss.
        snapshot.frame = self.view.convert(self.view.bounds, to: window)
        snapshot.layer.zPosition = 1000
        window.addSubview(snapshot)
        self.dismiss(animated: false) {
            UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
                snapshot.transform = CGAffineTransform(translationX: 0, y: -window.bounds.height)
            }, completion: { _ in
                snapshot.removeFromSuperview()
            })
        }
    }

}
