//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

class AnimView : UIView
{
    let iv: UIImageView!
    var isLarge = false
    
    func Tap(_ s: UIButton)
    {
        let pt1 = CGPoint(x: 0.1, y: 1.0)
        let pt2 = CGPoint(x: 0.5, y: 1.0)
        let anim = UIViewPropertyAnimator(duration: 2, controlPoint1: pt1, controlPoint2: pt2)
        {
            if self.isLarge
            {
                self.iv.frame = CGRect(x: 50, y: 50, width: 120, height: 120)
                self.iv.center = CGPoint(x: 207, y: 150)

            }
            else {
                self.iv.frame = self.frame
            }
        }
        isLarge = !isLarge
        anim.startAnimation()
        print("Tap")
    }
    
    override init(frame: CGRect) {
        iv = UIImageView(image: UIImage(named: "4202.jpg"))
        iv.frame = CGRect(x: 50, y: 50, width: 120, height: 120)
        iv.center = CGPoint(x: 207, y: 150)
        iv.contentMode = .scaleAspectFit
        super.init(frame: frame)
        addSubview(iv)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

let v = AnimView(frame: CGRect(x: 0, y: 0, width: 414, height: 736))
v.backgroundColor = UIColor.red

let btn = UIButton(frame: CGRect(x: 10, y: 10, width: 0, height: 0))
btn.setTitle("Animate", for: .normal)
btn.sizeToFit()
btn.addTarget(nil, action: #selector(AnimView.Tap(_:)), for: .touchUpInside)
v.addSubview(btn)



PlaygroundPage.current.liveView = v

