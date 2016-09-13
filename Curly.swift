//
//  Curly.swift
//  Curly
//
//  Created by Adolfo Rodriguez on 2014-11-04.
//  Copyright (c) 2014 Wircho. All rights reserved.
//

import Foundation

import UIKit

//MARK: Constants

private var CurlyAssociatedDelegateHandle: UInt8 = 0
private var CurlyAssociatedDelegateDictionaryHandle: UInt8 = 0
private var CurlyAssociatedDeinitDelegateArrayHandle: UInt8 = 0
private var CurlyAssociatedLayoutDelegateHandle: UInt8 = 0
private var CurlyAssociatedConnectionDelegateHandle: UInt8 = 0

//MARK: NSNotification Token Helper Class

open class CurlyNotificationToken {
    
    open weak var listener:AnyObject?
    private var observer:NSObjectProtocol!
    
    public init(listener:AnyObject, observer:NSObjectProtocol) {
        self.listener = listener
        self.observer = observer
    }
    
    deinit {
        self.cancel()
    }
    
    func cancel() {
        guard let observer = observer else { return }
        self.observer = nil
        NotificationCenter.default.removeObserver(observer)
    }
}

//MARK: Extensions

public extension String {
    func observeFrom<T:AnyObject>(listener:T,object:AnyObject? = nil,closure:@escaping (T,NSNotification)->Void) -> CurlyNotificationToken {
        var token:CurlyNotificationToken? = nil
        let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: self), object: object, queue: nil) {
            note in
            guard let actualToken = token else { return }
            guard let listener = actualToken.listener as? T else {
                actualToken.cancel()
                token = nil
                return
            }
            closure(listener,note as NSNotification)
        }
        token = CurlyNotificationToken(listener: listener, observer: observer)
        (listener as? NSObject)?.deinited {
            [weak token] in
            token?.cancel()
        }
        return token!
    }
}

public extension UINavigationController {
    
    func setDelegate(willShow:((_ viewController:UIViewController,_ animated:Bool)->Void)?, didShow:((_ viewController:UIViewController,_ animated:Bool)->Void)? = nil) {
        
        let delegate = Curly.NavigationControllerDelegate(willShow: willShow, didShow: didShow)
        self.delegate = delegate
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateHandle, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
}

public extension UIGestureRecognizer {
    
    //Objective-C Support
    convenience init (block:@escaping (UIGestureRecognizer)->Void) {
        self.init(closure:block)
    }
    
    convenience init<T:UIGestureRecognizer>(closure:@escaping(T)->Void) {
        let delegate = Curly.GestureRecognizerDelegate(recognized: closure)
        self.init(target: delegate, action: #selector(Curly.GestureRecognizerDelegate.recognizedGestureRecognizer(gr:)))
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateHandle, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

public extension UIBarButtonItem {
    
    convenience init(barButtonSystemItem: UIBarButtonSystemItem, closure:@escaping()->Void) {
        let delegate = Curly.BarButtonItemDelegate(tapped: closure)
        self.init(barButtonSystemItem: barButtonSystemItem, target:delegate, action:#selector(Curly.BarButtonItemDelegate.tappedButtonItem))
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateHandle, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    convenience init(image: UIImage?, landscapeImagePhone: UIImage?, style: UIBarButtonItemStyle, closure:@escaping()->Void) {
        let delegate = Curly.BarButtonItemDelegate(tapped: closure)
        self.init(image: image, landscapeImagePhone: landscapeImagePhone, style: style, target:delegate, action:#selector(Curly.BarButtonItemDelegate.tappedButtonItem))
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateHandle, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
    
    convenience init(image: UIImage?, style: UIBarButtonItemStyle, closure:@escaping()->Void) {
        let delegate = Curly.BarButtonItemDelegate(tapped: closure)
        self.init(image: image, style: style, target:delegate, action:#selector(Curly.BarButtonItemDelegate.tappedButtonItem))
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateHandle, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    convenience init(title: String?, style: UIBarButtonItemStyle, closure:@escaping()->Void) {
        let delegate = Curly.BarButtonItemDelegate(tapped: closure)
        self.init(title: title, style: style, target:delegate, action:#selector(Curly.BarButtonItemDelegate.tappedButtonItem))
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateHandle, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
}

public extension UIControl {
    
    //Objective C support
    public func addAction(events:UIControlEvents,block:(UIControl)->Void)
    {
        self.addAction(events: events, block: block)
    }
    
    public func addAction<T:UIControl>(events:UIControlEvents,closure:@escaping(T)->Void) {
        var delegateDictionary = objc_getAssociatedObject(self, &CurlyAssociatedDelegateDictionaryHandle) as! [UInt:[Curly.ControlDelegate]]!
        if delegateDictionary == nil {
            delegateDictionary = [:]
        }
        if delegateDictionary?[events.rawValue] == nil {
            delegateDictionary?[events.rawValue] = []
        }
        let delegate = Curly.ControlDelegate(received: closure)
        self.addTarget(delegate, action: #selector(Curly.ControlDelegate.recognizedControlEvent(ctl:)), for: events)
        delegateDictionary?[events.rawValue]!.append(delegate)
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateDictionaryHandle, delegateDictionary, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
    
    public func removeActions(events:UIControlEvents) {
        var delegateDictionary = objc_getAssociatedObject(self, &CurlyAssociatedDelegateDictionaryHandle) as! [UInt:[Curly.ControlDelegate]]!
        guard delegateDictionary != nil else { return }
        if let array = delegateDictionary?[events.rawValue] {
            for delegate in array {
                self.removeTarget(delegate, action: #selector(Curly.ControlDelegate.recognizedControlEvent(ctl:)), for: events)
            }
        }
        delegateDictionary?[events.rawValue] = nil
        objc_setAssociatedObject(self, &CurlyAssociatedDelegateDictionaryHandle, delegateDictionary, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
}

public extension NSObject {
    
    public func deinited(closure:@escaping()->Void) {
        var deinitArray = objc_getAssociatedObject(self, &CurlyAssociatedDeinitDelegateArrayHandle) as! [Curly.DeinitDelegate]!
        if deinitArray == nil {
            deinitArray = []
        }
        deinitArray!.append(Curly.DeinitDelegate(deinited: closure))
        objc_setAssociatedObject(self, &CurlyAssociatedDeinitDelegateArrayHandle, deinitArray, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    public func removeDeinitObservers() {
        guard let deinitArray = objc_getAssociatedObject(self, &CurlyAssociatedDeinitDelegateArrayHandle) as? [Curly.DeinitDelegate] else { return }
        for delegate in deinitArray {
            delegate.deinited = nil
        }
        objc_setAssociatedObject(self, &CurlyAssociatedDeinitDelegateArrayHandle, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

//MARK: Curly Class

private class Curly : NSObject {
    
    //MARK: Delegates
    
    open class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
        
        var willShow:((_ viewController:UIViewController,_ animated:Bool)->Void)?
        var didShow:((_ viewController:UIViewController,_ animated:Bool)->Void)?
        
        init(willShow v_willShow:((_ viewController:UIViewController,_ animated:Bool)->Void)?, didShow v_didShow:((_ viewController:UIViewController,_ animated:Bool)->Void)?) {
            self.willShow = v_willShow
            self.didShow = v_didShow
            super.init()
        }
        
        @objc public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
            if willShow != nil {
                willShow!(viewController, animated);
            }
        }
        
        @objc public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
            if didShow != nil {
                didShow!(viewController, animated);
            }
        }
        
    }
    
    
    open class BarButtonItemDelegate: NSObject {
        let tapped:()->Void
        
        @objc public func tappedButtonItem() {
            tapped()
        }
        
        public init(tapped:@escaping ()->Void) {
            self.tapped = tapped
            super.init()
        }
    }
    
    open class GestureRecognizerDelegate: NSObject {
        
        let recognized:(UIGestureRecognizer)->Void
        
        @objc func recognizedGestureRecognizer(gr:UIGestureRecognizer) {
            recognized(gr)
        }
        
        public init<T:UIGestureRecognizer>(recognized:@escaping (T)->Void) {
            self.recognized = { (gestureRecognizer:UIGestureRecognizer) -> Void in
                if let gr = gestureRecognizer as? T {
                    recognized(gr)
                }
            }
            
            super.init()
        }
    }
    
    open class ControlDelegate: NSObject {
        
        let received:(UIControl)->Void
        
        @objc func recognizedControlEvent(ctl:UIControl) {
            received(ctl)
        }
        
        public init<T:UIControl>(received: @escaping (T)->Void) {
            self.received = { (control:UIControl) -> Void in
                if let ctl = control as? T {
                    received(ctl)
                }
            }
            super.init()
        }
    }
    
    open class DeinitDelegate: NSObject {
        
        var deinited:(()->Void)!
        
        deinit {
            if deinited != nil {
                deinited()
            }
        }
        
        public init(deinited: @escaping ()->Void) {
            self.deinited = deinited
            super.init()
        }
        
    }
}



