//
//  HybridNavigationDestination.swift
//  RouteStack
//
//  Created by ahmed suliman on 16/04/2026.
//

import SwiftUI

private enum HybridNavigationConstants {
    static let frameworkName = "swiftui"
}

private struct HybridNavigationDestination<D: Hashable, Destination: View>: ViewModifier {
    @EnvironmentObject private var routeStack: RouteStack

    let dataType: D.Type
    let destination: (D) -> Destination

    func body(content: Content) -> some View {
        if let navigationController = routeStack.navigationController,
           case let className = String(reflecting: type(of: navigationController)),
           className.lowercased().contains(HybridNavigationConstants.frameworkName) {
            content
                .navigationDestination(for: dataType, destination: destination)
        } else {
            content
                .task {
                    routeStack.registerDestination(for: dataType) { value in
                        let hostingController = UIHostingController(
                            rootView: destination(value).environmentObject(routeStack)
                        )
                        hostingController.routeStack = routeStack
                        hostingController.swiftUIScreenType = ObjectIdentifier(Destination.self)
                        return hostingController
                    }
                }
        }
    }
}

// MARK: - SwiftUI Helpers

public extension View {
    func registerRouteStackScreenType<V: View>(routeStack: RouteStack, viewType: V.Type) -> some View {
        task { routeStack.registerRouteStackScreenType(to: viewType) }
    }

    func hybridNavigationDestination<D: Hashable, Destination: View>(
        for data: D.Type,
        @ViewBuilder destination: @escaping (D) -> Destination
    ) -> some View {
        modifier(
            HybridNavigationDestination(
                dataType: data,
                destination: destination
            )
        )
    }
}
