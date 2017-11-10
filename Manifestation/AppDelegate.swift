//
//  AppDelegate.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 4/30/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let previewA = PreviewAnim()
    let dismissA = DismissAnim()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("DocDir Contents: \(try! FileManager.default.contentsOfDirectory(atPath: Preference.DocDir.path))")
        print("AppDir Contents: \(try! FileManager.default.contentsOfDirectory(atPath: Preference.AppDir.path))")
        return true
    }
}


class PreviewVC: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        presentingViewController?.dismiss(animated: true)
    }
    override var shouldAutorotate: Bool {
        return false
    }
    override func viewDidDisappear(_ animated: Bool) {
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    
}

let animationDuration = 0.4
class PreviewAnim: NSObject, UIViewControllerAnimatedTransitioning {
    var startFrame = CGRect.zero
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerV = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        let finalFrame = toView.frame
        let xScale = startFrame.width / finalFrame.width
        let yScale = startFrame.height / finalFrame.height
        let squareScale = max(xScale, yScale)
        let scaleTransform = CGAffineTransform(scaleX: squareScale, y: squareScale)
        let toAlpha = toView.alpha
        
        toView.transform = scaleTransform
        toView.center = CGPoint(x: startFrame.midX, y: startFrame.midY)
        toView.alpha = 0.5
        
        containerV.addSubview(toView)
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: [], animations: {
            toView.transform = CGAffineTransform.identity
            toView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
            toView.alpha = toAlpha
        }) { (_) in
            transitionContext.completeTransition(true)
        }
    }
}

class DismissAnim: NSObject, UIViewControllerAnimatedTransitioning {
    var endFrame = CGRect.zero
    var dismissCompletion: (() -> Void)?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerV = transitionContext.containerView
        let fromView = transitionContext.view(forKey: .from)!
        let imageV = fromView.subviews.first as! UIImageView
        let initialFrame = imageV.frame
        let xScale = endFrame.width / initialFrame.width
        let yScale = endFrame.height / initialFrame.height
        let squareScale = max(xScale, yScale)
        let scaleTransform = CGAffineTransform(scaleX: squareScale, y: squareScale)
        
        fromView.alpha = 0.9
        
        containerV.addSubview(fromView)
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: {
            fromView.transform = scaleTransform
            fromView.center = CGPoint(x: self.endFrame.midX, y: self.endFrame.midY)
            fromView.alpha = 1
        }) { (_) in
            self.dismissCompletion?()
            transitionContext.completeTransition(true)
        }
    }
}
