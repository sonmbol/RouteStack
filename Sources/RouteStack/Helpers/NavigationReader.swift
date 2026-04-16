//
//  NavigationReader.swift
//  SDUI-New
//
//  Created by ahmed suliman on 14/04/2026.
//

import SwiftUI
import UIKit

private struct NavigationControllerReader: UIViewRepresentable {
    let onResolve: @MainActor (UINavigationController) -> Void

    func makeUIView(context: Context) -> ResolverView {
        let view = ResolverView()
        view.onResolve = onResolve
        return view
    }

    func updateUIView(_ uiView: ResolverView, context: Context) {
        uiView.onResolve = onResolve
        uiView.resolveIfNeeded()
    }
}

private final class ResolverView: UIView {
    var onResolve: (@MainActor (UINavigationController) -> Void)?
    private weak var resolvedNavigationController: UINavigationController?

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        resolveIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        resolveIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resolveIfNeeded()
    }

    @MainActor
    func resolveIfNeeded() {
        guard resolvedNavigationController == nil else { return }
        guard let navigationController = findNavigationController() else { return }

        resolvedNavigationController = navigationController
        onResolve?(navigationController)
    }

    private func findNavigationController() -> UINavigationController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let navigationController = current as? UINavigationController {
                return navigationController
            }

            if let viewController = current as? UIViewController,
               let navigationController = viewController.navigationController {
                return navigationController
            }

            responder = current.next
        }
        return nil
    }
}

public extension View {
    func attachRouteStackIfNeeded(_ routeStack: RouteStack) -> some View {
        background(
            NavigationControllerReader { navigationController in
                guard routeStack.navigationController !== navigationController else { return }
                routeStack.attach(to: navigationController)
            }
            .frame(width: 0, height: 0)
        )
    }
}
