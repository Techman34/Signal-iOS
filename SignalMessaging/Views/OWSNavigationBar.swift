//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation
import UIKit

@objc
public protocol NavBarLayoutDelegate: class {
    func navBarCallLayoutDidChange(navbar: OWSNavigationBar)
}

@objc
public class OWSNavigationBar: UINavigationBar {

    @objc
    public weak var navBarLayoutDelegate: NavBarLayoutDelegate?

    @objc
    public let navbarWithoutStatusHeight: CGFloat = 44

    @objc
    public var callBannerHeight: CGFloat {
        return OWSWindowManagerCallScreenHeight()
    }

    @objc
    public var statusBarHeight: CGFloat {
        return CurrentAppContext().statusBarHeight
    }

    @objc
    public var fullWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.isTranslucent = false

        NotificationCenter.default.addObserver(self, selector: #selector(callDidChange), name: .OWSWindowManagerCallDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarFrame), name: .UIApplicationDidChangeStatusBarFrame, object: nil)
    }

    @objc
    public func callDidChange() {
        Logger.debug("\(self.logTag) in \(#function)")
        self.navBarLayoutDelegate?.navBarCallLayoutDidChange(navbar: self)
    }

    @objc
    public func didChangeStatusBarFrame() {
        Logger.debug("\(self.logTag) in \(#function)")
        self.navBarLayoutDelegate?.navBarCallLayoutDidChange(navbar: self)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard OWSWindowManager.shared().hasCall() else {
            return super.sizeThatFits(size)
        }

        if #available(iOS 11, *) {
            return super.sizeThatFits(size)
        } else {
            // pre iOS11, sizeThatFits is repeatedly called to determine how much space to reserve for that navbar.
            // That is, increasing this causes the child view controller to be pushed down.
            // (as of iOS11, this is not used and instead we use additionalSafeAreaInsets)
            return CGSize(width: fullWidth, height: navbarWithoutStatusHeight + statusBarHeight)
        }
    }

    public override func layoutSubviews() {
        guard OWSWindowManager.shared().hasCall() else {
            super.layoutSubviews()
            return
        }

        self.frame = CGRect(x: 0, y: callBannerHeight, width: fullWidth, height: navbarWithoutStatusHeight)
        self.bounds = CGRect(x: 0, y: 0, width: fullWidth, height: navbarWithoutStatusHeight)

        super.layoutSubviews()

        guard #available(iOS 11, *) else {
            return
        }

        // This is only necessary on iOS11, which has some private views within that lay outside of the navbar.
        // They aren't actually visible behind the call status bar, but they looks strange during present/dismiss
        // animations for modal VC's
        for subview in self.subviews {
            let stringFromClass = NSStringFromClass(subview.classForCoder)
            if stringFromClass.contains("BarBackground") {
                subview.frame = self.bounds
            } else if stringFromClass.contains("BarContentView") {
                subview.frame = self.bounds
            }
        }
    }
}
