//
//  HybridNavigationDestination.swift
//  RouteStack
//
//  Created by ahmed suliman on 16/04/2026.
//

import SwiftUI

private struct HybridNavigationDestination<D: Hashable, Destination: View>: ViewModifier {
    @EnvironmentObject private var routeStack: RouteStack

    let dataType: D.Type
    let destination: (D) -> Destination

    func body(content: Content) -> some View {
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
