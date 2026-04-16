//
//  RouteStackNavigationController.swift
//  RouteStack
//
//  Created by ahmed suliman on 16/04/2026.
//

import UIKit
import SwiftUI

// MARK: - Associated Object Keys

nonisolated(unsafe) private var viewControllerRouteStackKey: UInt8 = 0
nonisolated(unsafe) private var viewControllerNavigationValueKey: UInt8 = 0
nonisolated(unsafe) private var swiftUIScreenTypeKey: UInt8 = 0

// MARK: - UIViewController Private Metadata

@MainActor
extension UIViewController {
    var swiftUIScreenType: ObjectIdentifier? {
        get { objc_getAssociatedObject(self, &swiftUIScreenTypeKey) as? ObjectIdentifier }
        set { objc_setAssociatedObject(self, &swiftUIScreenTypeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var navigationValue: AnyHashable? {
        get { objc_getAssociatedObject(self, &viewControllerNavigationValueKey) as? AnyHashable }
        set { objc_setAssociatedObject(self, &viewControllerNavigationValueKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}


// MARK: - RouteStackNavigationController
// UIKit-root flow that supports path-style append without needing a SwiftUI NavigationStack.

@MainActor
public final class RouteStackNavigationController: UINavigationController, UINavigationControllerDelegate {
    private struct DestinationBox {
        let build: (AnyHashable) -> UIViewController?
    }

    private var destinations: [ObjectIdentifier: DestinationBox] = [:]
    private var stackValues: [AnyHashable] = []

    weak var routeStackBridge: RouteStack?

    public override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = self
    }

    func registerDestination<D: Hashable>(
        for type: D.Type,
        destination: @escaping (D) -> UIViewController
    ) {
        destinations[ObjectIdentifier(type)] = DestinationBox { value in
            guard let typedValue = value.base as? D else { return nil }
            let viewController = destination(typedValue)
            viewController.navigationValue = value
            return viewController
        }
    }

    func append<D: Hashable>(_ value: D, animated: Bool = true) {
        let key = ObjectIdentifier(D.self)
        guard let viewController = destinations[key]?.build(AnyHashable(value)) else { return }

        pushViewController(viewController, animated: animated)
        stackValues.append(AnyHashable(value))
        routeStackBridge?.syncPathFromUIKit(stackValues)
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        let currentValues = viewControllers.compactMap(\.navigationValue)

        if currentValues.count != stackValues.count {
            stackValues = currentValues
            routeStackBridge?.syncPathFromUIKit(stackValues)
        }
    }
}

// MARK: - UINavigationController Stored RouteStack

@MainActor
public extension UINavigationController {
    @discardableResult
    func attachRouteStackIfNeeded() -> RouteStack {
        if let routeStack = self.routeStack { return routeStack }
        let routeStack = RouteStack(navigationController: self)
        self.routeStack = routeStack

        if let self = self as? RouteStackNavigationController {
            self.routeStackBridge = routeStack
        }

        return routeStack
    }

    convenience init(routeStack: RouteStack? = nil) {
        self.init()
        let routeStack = routeStack ?? RouteStack()
        self.routeStack = routeStack

        if let self = self as? RouteStackNavigationController {
            self.routeStackBridge = routeStack
        }

        routeStack.attach(to: self)
    }

    convenience init(rootViewController: UIViewController, routeStack: RouteStack? = nil) {
        self.init(rootViewController: rootViewController)
        let routeStack = routeStack ?? RouteStack()
        self.routeStack = routeStack

        if let self = self as? RouteStackNavigationController {
            self.routeStackBridge = routeStack
        }

        routeStack.attach(to: self)
        rootViewController.routeStack = routeStack
    }

    convenience init<Root: View>(rootView: Root, routeStack: RouteStack? = nil) {
        let routeStack = routeStack ?? RouteStack()

        let hostingController = UIHostingController(
            rootView: rootView.environmentObject(routeStack)
        )
        hostingController.routeStack = routeStack
        hostingController.swiftUIScreenType = ObjectIdentifier(Root.self)

        self.init(rootViewController: hostingController)
        self.routeStack = routeStack

        if let self = self as? RouteStackNavigationController {
            self.routeStackBridge = routeStack
        }

        routeStack.attach(to: self)
    }

    func push(_ viewController: UIViewController, animated: Bool = true) {
        let routeStack = attachRouteStackIfNeeded()
        viewController.routeStack = routeStack
        pushViewController(viewController, animated: animated)
    }

    func push<V: View>(_ view: V, animated: Bool = true) {
        let routeStack = attachRouteStackIfNeeded()

        let hostingController = UIHostingController(
            rootView: view.environmentObject(routeStack)
        )
        hostingController.routeStack = routeStack
        hostingController.swiftUIScreenType = ObjectIdentifier(V.self)

        pushViewController(hostingController, animated: animated)
    }
}

// MARK: - UIViewController RouteStack

@MainActor
public extension UIViewController {
    var routeStack: RouteStack? {
        get {
            objc_getAssociatedObject(self, &viewControllerRouteStackKey) as? RouteStack
        }
        set {
            objc_setAssociatedObject(
                self,
                &viewControllerRouteStackKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
