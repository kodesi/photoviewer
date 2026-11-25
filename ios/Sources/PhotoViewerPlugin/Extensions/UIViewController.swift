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
