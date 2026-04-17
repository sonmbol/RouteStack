//
//  Navigation.swift
//  SDUI-New
//
//  Created by ahmed suliman on 14/04/2026.
//

import Combine
import SwiftUI
import UIKit
import ObjectiveC

// MARK: - RouteStack

@MainActor
public final class RouteStack: ObservableObject {
    private(set) weak var navigationController: UINavigationController?
    @Published public private(set) var path = NavigationPath()
    
    public var pathBinding: Binding<NavigationPath> {
        .init(
            get: { [weak self] in self?.path ?? NavigationPath() },
            set: { [weak self] in self?.path = $0 }
        )
    }

    public init() {
        print("RouteStack init")
    }

    public init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    deinit {
        print("deallocated RouteStack")
    }

    public func attach(to navigationController: UINavigationController) {
        self.navigationController = navigationController
        navigationController.routeStack = self

        if let navigationController = navigationController as? RouteStackNavigationController {
            navigationController.routeStackBridge = self
        }
    }

    public func push(_ viewController: UIViewController, animated: Bool = true) {
        guard let navigationController else { return }
        viewController.routeStack = self
        navigationController.pushViewController(viewController, animated: animated)
    }

    public func push<V: View>(_ view: V, animated: Bool = true) {
        guard let navigationController else { return }

        let hostingController = UIHostingController(
            rootView: view.environmentObject(self)
        )
        hostingController.routeStack = self
        hostingController.swiftUIScreenType = ObjectIdentifier(V.self)
        navigationController.pushViewController(hostingController, animated: animated)
    }

    public func append<V: Hashable>(_ value: V) {
        if let navigationController = navigationController as? RouteStackNavigationController {
            navigationController.append(value)
        } else {
            path.append(value)
        }
    }

    public func removeLast(_ k: Int = 1) {
        guard k > 0 else { return }
        guard path.count >= k else { return }
        path.removeLast(k)
    }

    public func pop(animated: Bool = true) {
        if navigationController?.popViewController(animated: animated) == nil {
            removeLast()
        }
    }

    public func popToRoot(animated: Bool = true) {
        navigationController?.popToRootViewController(animated: animated)
        path = NavigationPath()
    }

    public func pop<T: UIViewController>(to type: T.Type, animated: Bool = true) {
        guard let navigationController else { return }
        guard let target = findViewController(ofType: type, in: navigationController) else { return }

        if let targetNavigationController = target.navigationController {
            targetNavigationController.popToViewController(target, animated: animated)
        }
    }

    public func pop<V: View>(to viewType: V.Type, animated: Bool = true) {
        guard let navigationController else { return }

        let targetType = ObjectIdentifier(V.self)
        guard let target = findSwiftUIViewController(targetType: targetType, in: navigationController) else { return }

        if let targetNavigationController = target.navigationController {
            targetNavigationController.popToViewController(target, animated: animated)
        }
    }

    func registerDestination<D: Hashable>(
        for type: D.Type,
        destination: @escaping (D) -> UIViewController
    ) {
        (navigationController as? RouteStackNavigationController)?
            .registerDestination(for: type, destination: destination)
    }

    func syncPathFromUIKit(_ values: [AnyHashable]) {
        var newPath = NavigationPath()
        for value in values {
            newPath.append(value)
        }
        path = newPath
    }

    private func findViewController<T: UIViewController>(
        ofType type: T.Type,
        in navigationController: UINavigationController
    ) -> T? {
        if let target = navigationController.viewControllers.last(where: { $0 is T }) as? T {
            return target
        }

        for viewController in navigationController.viewControllers {
            if let nestedNavigationController = viewController as? UINavigationController,
               let target = findViewController(ofType: type, in: nestedNavigationController) {
                return target
            }
        }

        return nil
    }

    private func findSwiftUIViewController(
        targetType: ObjectIdentifier,
        in navigationController: UINavigationController
    ) -> UIViewController? {
        if let target = navigationController.viewControllers.last(where: {
            $0.swiftUIScreenType == targetType
        }) {
            return target
        }

        for viewController in navigationController.viewControllers {
            if let nestedNavigationController = viewController as? UINavigationController,
               let target = findSwiftUIViewController(targetType: targetType, in: nestedNavigationController) {
                return target
            }
        }

        return nil
    }

    func registerRouteStackScreenType<V: View>(to viewType: V.Type) {
        guard let navigationController else { return }
        let targetType = ObjectIdentifier(V.self)

        if navigationController.viewControllers.last?.swiftUIScreenType == nil {
            navigationController.viewControllers.last?.swiftUIScreenType = targetType
        }
    }

    public func getPathString() -> String {
        ""
    }
}
