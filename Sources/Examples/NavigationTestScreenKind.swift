//
//  NavigationTestScreenKind.swift
//  SDUI-New
//
//  Created by ahmed suliman on 14/04/2026.
//


import SwiftUI
import UIKit
import RouteStack

// MARK: - Entry Points

@MainActor
public func makeNavigationTestRootViewController() -> UIViewController {
    RouteStackNavigationController(
        rootView: NavigationTestSwiftUIScreen1(
            instanceID: UUID().uuidString, origin: "App Root")
    )
}

@MainActor
func makeNavigationTestUIKitRootViewController() -> UIViewController {
    RouteStackNavigationController(
        rootViewController: NavigationTestUIKitViewController1(
            instanceID: UUID().uuidString,
            origin: "App Root"
        )
    )
}

struct NavigationBarBridge: UIViewControllerRepresentable {
    @EnvironmentObject var routeStack: RouteStack
    let hidden: Bool

    func makeUIViewController(context: Context) -> Controller {
        let uiViewController = Controller(hidden: hidden, routeStack: routeStack)
        uiViewController.hidden = hidden
        uiViewController.apply()
        return uiViewController
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {
        uiViewController.apply()
    }

    final class Controller: UIViewController {
        var hidden: Bool
        let newRouteStack: RouteStack

        init(hidden: Bool, routeStack: RouteStack) {
            self.hidden = hidden
            self.newRouteStack = routeStack
            super.init(nibName: nil, bundle: nil)
            view.isHidden = true
        }

        @MainActor deinit {
            newRouteStack.navigationController?.setNavigationBarHidden(false, animated: false)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func apply() {
            newRouteStack.navigationController?.setNavigationBarHidden(hidden, animated: false)
        }
    }
}
// MARK: - Shared Models

enum NavigationTestScreenKind: String, CaseIterable, Identifiable {
    case swiftUI1
    case swiftUI2
    case uiKit1
    case uiKit2

    var id: String { rawValue }

    var title: String {
        switch self {
        case .swiftUI1: return "SwiftUI Screen 1"
        case .swiftUI2: return "SwiftUI Screen 2"
        case .uiKit1: return "UIKit ViewController 1"
        case .uiKit2: return "UIKit ViewController 2"
        }
    }
}

public enum NavigationTestSwiftUI1Route: Hashable, CustomStringConvertible {
    case swiftUI1(instanceID: String, origin: String)
    case swiftUI2(instanceID: String, origin: String)

    public var description: String {
        switch self {
        case let .swiftUI1(instanceID, origin):
            return "SwiftUI1Route.swiftUI1 | id: \(instanceID) | origin: \(origin)"
        case let .swiftUI2(instanceID, origin):
            return "SwiftUI1Route.swiftUI2 | id: \(instanceID) | origin: \(origin)"
        }
    }
}

public enum NavigationTestSwiftUI2Route: Hashable, CustomStringConvertible {
    case swiftUI1(instanceID: String, origin: String)
    case swiftUI2(instanceID: String, origin: String)

    public var description: String {
        switch self {
        case let .swiftUI1(instanceID, origin):
            return "SwiftUI2Route.swiftUI1 | id: \(instanceID) | origin: \(origin)"
        case let .swiftUI2(instanceID, origin):
            return "SwiftUI2Route.swiftUI2 | id: \(instanceID) | origin: \(origin)"
        }
    }
}

// MARK: - Shared Helpers

@MainActor
private func presentNewNavigationController(from presenter: UIViewController?, root: NavigationTestScreenKind) {
    guard let presenter else { return }

    let navigationController: UINavigationController

    switch root {
    case .swiftUI1:
        navigationController = RouteStackNavigationController(
            rootView: NavigationTestSwiftUIScreen1(
                instanceID: UUID().uuidString,
                origin: "New UINavigationController Root"
            ),
            routeStack: RouteStack()
        )

    case .swiftUI2:
        navigationController = RouteStackNavigationController(
            rootView: NavigationTestSwiftUIScreen2(
                instanceID: UUID().uuidString,
                origin: "New UINavigationController Root"
            ),
            routeStack: RouteStack()
        )

    case .uiKit1:
        navigationController = RouteStackNavigationController(
            rootViewController: NavigationTestUIKitViewController1(
                instanceID: UUID().uuidString,
                origin: "New UINavigationController Root"
            ),
            routeStack: RouteStack()
        )

    case .uiKit2:
        navigationController = RouteStackNavigationController(
            rootViewController: NavigationTestUIKitViewController2(
                instanceID: UUID().uuidString,
                origin: "New UINavigationController Root"
            ),
            routeStack: RouteStack()
        )
    }

    navigationController.modalPresentationStyle = .fullScreen
    presenter.present(navigationController, animated: true)
}

@MainActor
private func navigationHierarchyText(routeStack: RouteStack?) -> String {
    guard let stack = routeStack?.navigationController?.viewControllers, !stack.isEmpty else {
        return "<empty>"
    }

    return stack.enumerated().map { index, viewController in
        let title = viewController.title?.isEmpty == false ? viewController.title! : "no-title"
        let type = String(describing: type(of: viewController))
        return "\(index). \(title) [\(type)]"
    }
    .joined(separator: "\n")
}


// MARK: - Shared SwiftUI Debug Card

struct NavigationTestDebugCard: View {
    let screenName: String
    let screenType: String
    let instanceID: String
    let origin: String
    let hierarchy: String
    let navigationPathString: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(screenName)
                .font(.title2.bold())

            Text("Type: \(screenType)")
            Text("Instance ID: \(instanceID)")
            Text("Origin: \(origin)")

            Divider()

            Text("Hierarchy")
                .font(.headline)

            Text(hierarchy)
                .font(.system(.footnote, design: .monospaced))

            Text("NavigationPath")
                .font(.headline)

            Text(navigationPathString)
                .font(.system(.footnote, design: .monospaced))

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - SwiftUI Flow Root

struct NavigationTestSwiftUIFlowRoot: View {
    @EnvironmentObject var routeStack: RouteStack

    let initialScreen: NavigationTestScreenKind
    let origin: String

    var body: some View {
        NavigationStack(path: routeStack.pathBinding) {
            rootView
                .navigationDestination(for: NavigationTestSwiftUI1Route.self) { route in
                    switch route {
                    case let .swiftUI1(instanceID, origin):
                        NavigationTestSwiftUIScreen1(
                            instanceID: instanceID,
                            origin: origin
                        )

                    case let .swiftUI2(instanceID, origin):
                        NavigationTestSwiftUIScreen2(
                            instanceID: instanceID,
                            origin: origin
                        )
                    }
                }
                .navigationDestination(for: NavigationTestSwiftUI2Route.self) { route in
                    switch route {
                    case let .swiftUI1(instanceID, origin):
                        NavigationTestSwiftUIScreen1(
                            instanceID: instanceID,
                            origin: origin
                        )

                    case let .swiftUI2(instanceID, origin):
                        NavigationTestSwiftUIScreen2(
                            instanceID: instanceID,
                            origin: origin
                        )
                    }
                }
        }
        .toolbar(.hidden, for: .navigationBar)
//        .navigationBarHidden(true)
//        .statusBarHidden()
    }

    @ViewBuilder
    private var rootView: some View {
        switch initialScreen {
        case .swiftUI1:
            NavigationTestSwiftUIScreen1(
                instanceID: UUID().uuidString,
                origin: origin
            )

        case .swiftUI2:
            NavigationTestSwiftUIScreen2(
                instanceID: UUID().uuidString,
                origin: origin
            )

        default:
            NavigationTestSwiftUIScreen1(
                instanceID: UUID().uuidString,
                origin: origin
            )
        }
    }
}

// MARK: - SwiftUI Screen 1

public struct NavigationTestSwiftUIScreen1: View {
    @EnvironmentObject private var routeStack: RouteStack

    let instanceID: String
    let origin: String

    public init(instanceID: String, origin: String) {
        self.instanceID = instanceID
        self.origin = origin
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationTestDebugCard(
                    screenName: "SwiftUI Screen 1",
                    screenType: "SwiftUI View",
                    instanceID: instanceID,
                    origin: origin,
                    hierarchy: navigationHierarchyText(routeStack: routeStack),
                    navigationPathString: routeStack.getPathString()
                )

                swiftUILocalNavigationSection
                routeStackPushCurrentNavigationSection
                newNavigationControllerSection
                stackActionSection
            }
            .padding()
        }
        .navigationTitle("SwiftUI Screen 1")
        .navigationBarTitleDisplayMode(.inline)
        .hybridNavigationDestination(for: NavigationTestSwiftUI1Route.self) { route in
            switch route {
            case let .swiftUI1(instanceID, origin):
                NavigationTestSwiftUIScreen1(
                    instanceID: instanceID,
                    origin: origin
                )

            case let .swiftUI2(instanceID, origin):
                NavigationTestSwiftUIScreen2(
                    instanceID: instanceID,
                    origin: origin
                )
            }
        }
        .hybridNavigationDestination(for: NavigationTestSwiftUI2Route.self) { route in
            switch route {
            case let .swiftUI1(instanceID, origin):
                NavigationTestSwiftUIScreen1(
                    instanceID: instanceID,
                    origin: origin
                )

            case let .swiftUI2(instanceID, origin):
                NavigationTestSwiftUIScreen2(
                    instanceID: instanceID,
                    origin: origin
                )
            }
        }
        .registerRouteStackScreenType(routeStack: routeStack, viewType: Self.self)
    }

    private var swiftUILocalNavigationSection: some View {
        GroupBox("Native SwiftUI NavigationPath / navigationDestination") {
            VStack(spacing: 10) {
                Button("Path -> SwiftUI Screen 1") {
                    let route = NavigationTestSwiftUI1Route.swiftUI1(
                        instanceID: UUID().uuidString,
                        origin: "NavigationPath from SwiftUI Screen 1"
                    )
                    routeStack.append(route)
                }

                Button("Path -> SwiftUI Screen 2") {
                    let route = NavigationTestSwiftUI1Route.swiftUI2(
                        instanceID: UUID().uuidString,
                        origin: "NavigationPath from SwiftUI Screen 1"
                    )
                    routeStack.append(route)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var routeStackPushCurrentNavigationSection: some View {
        GroupBox("RouteStack Push In Current UINavigationController") {
            VStack(spacing: 10) {
                Button("RouteStack -> SwiftUI Screen 1") {
                    routeStack.push(
                        NavigationTestSwiftUIScreen1(
                            instanceID: UUID().uuidString,
                            origin: "RouteStack push from SwiftUI Screen 1"
                        )
                    )
                }

                Button("RouteStack -> SwiftUI Screen 2") {
                    routeStack.push(
                        NavigationTestSwiftUIScreen2(
                            instanceID: UUID().uuidString,
                            origin: "RouteStack push from SwiftUI Screen 1"
                        )
                    )
                }

                Button("RouteStack -> UIKit ViewController 1") {
                    routeStack.push(
                        NavigationTestUIKitViewController1(
                            instanceID: UUID().uuidString,
                            origin: "RouteStack push from SwiftUI Screen 1"
                        )
                    )
                }

                Button("RouteStack -> UIKit ViewController 2") {
                    routeStack.push(
                        NavigationTestUIKitViewController2(
                            instanceID: UUID().uuidString,
                            origin: "RouteStack push from SwiftUI Screen 1"
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var newNavigationControllerSection: some View {
        GroupBox("Present New UINavigationController With New RouteStack") {
            VStack(spacing: 10) {
                Button("New Nav -> SwiftUI Screen 1") {
                    presentNewNavigationController(
                        from: routeStack.navigationController?.topViewController,
                        root: .swiftUI1
                    )
                }

                Button("New Nav -> SwiftUI Screen 2") {
                    presentNewNavigationController(
                        from: routeStack.navigationController?.topViewController,
                        root: .swiftUI2
                    )
                }

                Button("New Nav -> UIKit ViewController 1") {
                    presentNewNavigationController(
                        from: routeStack.navigationController?.topViewController,
                        root: .uiKit1
                    )
                }

                Button("New Nav -> UIKit ViewController 2") {
                    presentNewNavigationController(
                        from: routeStack.navigationController?.topViewController,
                        root: .uiKit2
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var stackActionSection: some View {
        GroupBox("Stack Actions") {
            VStack(spacing: 10) {
                Button("Pop") {
                    routeStack.pop()
                }

                Button("Pop To Root") {
                    routeStack.popToRoot()
                }

                Button("Pop To Hosted SwiftUI Screen 1") {
                    routeStack.pop(to: NavigationTestSwiftUIScreen1.self)
                }

                Button("Pop To Hosted SwiftUI Screen 2") {
                    routeStack.pop(to: NavigationTestSwiftUIScreen2.self)
                }

                Button("Pop To UIKit ViewController 1") {
                    routeStack.pop(to: NavigationTestUIKitViewController1.self)
                }

                Button("Pop To UIKit ViewController 2") {
                    routeStack.pop(to: NavigationTestUIKitViewController2.self)
                }

                Button("Dismiss Presented Navigation Controller") {
                    routeStack.navigationController?.dismiss(animated: true)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - SwiftUI Screen 2

public struct NavigationTestSwiftUIScreen2: View {
    @EnvironmentObject private var routeStack: RouteStack

    let instanceID: String
    let origin: String

    public init(instanceID: String, origin: String) {
        self.instanceID = instanceID
        self.origin = origin
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationTestDebugCard(
                    screenName: "SwiftUI Screen 2",
                    screenType: "SwiftUI View",
                    instanceID: instanceID,
                    origin: origin,
                    hierarchy: navigationHierarchyText(routeStack: routeStack),
                    navigationPathString: routeStack.getPathString()
                )
                
                swiftUILocalNavigationSection
                routeStackPushCurrentNavigationSection
                newNavigationControllerSection
                stackActionSection
            }
            .padding()
        }
        .navigationTitle("SwiftUI Screen 2")
        .navigationBarTitleDisplayMode(.inline)
        .registerRouteStackScreenType(routeStack: routeStack, viewType: Self.self)
    }

    private var swiftUILocalNavigationSection: some View {
        GroupBox("Native SwiftUI NavigationPath / navigationDestination") {
            VStack(spacing: 10) {
                Button("Path -> SwiftUI Screen 1") {
                    let route = NavigationTestSwiftUI2Route.swiftUI1(
                        instanceID: UUID().uuidString,
                        origin: "NavigationPath from SwiftUI Screen 2"
                    )
                    routeStack.append(route)
                }

                Button("Path -> SwiftUI Screen 2") {
                    let route = NavigationTestSwiftUI2Route.swiftUI2(
                        instanceID: UUID().uuidString,
                        origin: "NavigationPath from SwiftUI Screen 2"
                    )
                    routeStack.append(route)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var routeStackPushCurrentNavigationSection: some View {
        GroupBox("RouteStack Push In Current UINavigationController") {
            VStack(spacing: 10) {
                Button("RouteStack -> SwiftUI Screen 1") {
                    routeStack.push(
                        NavigationTestSwiftUIScreen1(
                            instanceID: UUID().uuidString,
                            origin: "RouteStack push from SwiftUI Screen 2"
                        )
                    )
                }

                Button("RouteStack -> SwiftUI Screen 2") {
                    routeStack.push(
                        NavigationTestSwiftUIScreen2(
                            instanceID: UUID().uuidString,
                            origin: "RouteStack push from SwiftUI Screen 2"
                        )
                    )
                }

                Button("RouteStack -> UIKit ViewController 1") {
                    routeStack.push(
                        NavigationTestUIKitViewController1(
                            instanceID: UUID().uuidString,
                            origin: "RouteStack push from SwiftUI Screen 2"
                        )
                    )
                }

                Button("RouteStack -> UIKit ViewController 2") {
                    routeStack.push(
                        NavigationTestUIKitViewController2(
                            instanceID: UUID().uuidString,
                            origin: "RouteStack push from SwiftUI Screen 2"
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var newNavigationControllerSection: some View {
        GroupBox("Present New UINavigationController With New RouteStack") {
            VStack(spacing: 10) {
                Button("New Nav -> SwiftUI Screen 1") {
                    presentNewNavigationController(
                        from: routeStack.navigationController?.topViewController,
                        root: .swiftUI1
                    )
                }

                Button("New Nav -> SwiftUI Screen 2") {
                    presentNewNavigationController(
                        from: routeStack.navigationController?.topViewController,
                        root: .swiftUI2
                    )
                }

                Button("New Nav -> UIKit ViewController 1") {
                    presentNewNavigationController(
                        from: routeStack.navigationController?.topViewController,
                        root: .uiKit1
                    )
                }

                Button("New Nav -> UIKit ViewController 2") {
                    presentNewNavigationController(
                        from: routeStack.navigationController?.topViewController,
                        root: .uiKit2
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var stackActionSection: some View {
        GroupBox("Stack Actions") {
            VStack(spacing: 10) {
                Button("Pop") {
                    routeStack.pop()
                }

                Button("Pop To Root") {
                    routeStack.popToRoot()
                }

                Button("Pop To Hosted SwiftUI Screen 1") {
                    routeStack.pop(to: NavigationTestSwiftUIScreen1.self)
                }

                Button("Pop To Hosted SwiftUI Screen 2") {
                    routeStack.pop(to: NavigationTestSwiftUIScreen2.self)
                }

                Button("Pop To UIKit ViewController 1") {
                    routeStack.pop(to: NavigationTestUIKitViewController1.self)
                }

                Button("Pop To UIKit ViewController 2") {
                    routeStack.pop(to: NavigationTestUIKitViewController2.self)
                }

                Button("Dismiss Presented Navigation Controller") {
                    routeStack.navigationController?.dismiss(animated: true)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}


// MARK: - UIKit Base Screen

@MainActor
class NavigationTestUIKitBaseViewController: UIViewController {
    let instanceID: String
    let origin: String
    let screenName: String

    private let infoLabel = UILabel()
    private let stackView = UIStackView()

    init(screenName: String, instanceID: String, origin: String) {
        self.screenName = screenName
        self.instanceID = instanceID
        self.origin = origin
        super.init(nibName: nil, bundle: nil)
        self.title = screenName
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        setupButtons()
        refreshInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshInfo()
    }

    func setupButtons() { }

    private func buildUI() {
        infoLabel.numberOfLines = 0
        infoLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)

        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let content = UIStackView(arrangedSubviews: [infoLabel, stackView])
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    func addSection(title: String, buttons: [UIButton]) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        let sectionStack = UIStackView(arrangedSubviews: [titleLabel] + buttons)
        sectionStack.axis = .vertical
        sectionStack.spacing = 10

        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        sectionStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sectionStack)

        NSLayoutConstraint.activate([
            sectionStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            sectionStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            sectionStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            sectionStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        stackView.addArrangedSubview(container)
    }

    func makeButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        button.configuration = configuration
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func refreshInfo() {
        infoLabel.text = """
        \(screenName)
        Type: UIKit UIViewController
        Instance ID: \(instanceID)
        Origin: \(origin)

        Hierarchy:
        \(navigationHierarchyText(routeStack: routeStack))
        """
    }
}

// MARK: - UIKit ViewController 1

@MainActor
final class NavigationTestUIKitViewController1: NavigationTestUIKitBaseViewController {
    init(instanceID: String, origin: String) {
        super.init(screenName: "UIKit ViewController 1", instanceID: instanceID, origin: origin)
    }

    override func setupButtons() {
        addSection(
            title: "RouteStack Push In Current UINavigationController",
            buttons: [
                makeButton("RouteStack -> Hosted SwiftUI Screen 1", action: #selector(openSwiftUI1)),
                makeButton("RouteStack -> Hosted SwiftUI Screen 2", action: #selector(openSwiftUI2)),
                makeButton("RouteStack -> UIKit ViewController 1", action: #selector(openUIKit1)),
                makeButton("RouteStack -> UIKit ViewController 2", action: #selector(openUIKit2))
            ]
        )

        addSection(
            title: "Present New UINavigationController With New RouteStack",
            buttons: [
                makeButton("New Nav -> SwiftUI Screen 1", action: #selector(openNewNavSwiftUI1)),
                makeButton("New Nav -> SwiftUI Screen 2", action: #selector(openNewNavSwiftUI2)),
                makeButton("New Nav -> UIKit ViewController 1", action: #selector(openNewNavUIKit1)),
                makeButton("New Nav -> UIKit ViewController 2", action: #selector(openNewNavUIKit2))
            ]
        )

        addSection(
            title: "Stack Actions",
            buttons: [
                makeButton("Pop", action: #selector(popCurrent)),
                makeButton("Pop To Root", action: #selector(popToRootCurrent)),
                makeButton("Pop To Hosted SwiftUI Screen 1", action: #selector(popToSwiftUI1)),
                makeButton("Pop To Hosted SwiftUI Screen 2", action: #selector(popToSwiftUI2)),
                makeButton("Pop To UIKit ViewController 1", action: #selector(popToUIKit1)),
                makeButton("Pop To UIKit ViewController 2", action: #selector(popToUIKit2)),
                makeButton("Dismiss Presented Navigation Controller", action: #selector(dismissPresented))
            ]
        )
    }

    @objc private func openSwiftUI1() {
        routeStack?.push(
            NavigationTestSwiftUIScreen1(
                instanceID: UUID().uuidString,
                origin: "RouteStack push from UIKit ViewController 1"
            )
        )
    }

    @objc private func openSwiftUI2() {
        routeStack?.push(
            NavigationTestSwiftUIScreen2(
                instanceID: UUID().uuidString,
                origin: "RouteStack push from UIKit ViewController 1"
            )
        )
    }

    @objc private func openUIKit1() {
        routeStack?.push(
            NavigationTestUIKitViewController1(
                instanceID: UUID().uuidString,
                origin: "RouteStack push from UIKit ViewController 1"
            )
        )
    }

    @objc private func openUIKit2() {
        routeStack?.push(
            NavigationTestUIKitViewController2(
                instanceID: UUID().uuidString,
                origin: "RouteStack push from UIKit ViewController 1"
            )
        )
    }

    @objc private func openNewNavSwiftUI1() {
        presentNewNavigationController(from: self, root: .swiftUI1)
    }

    @objc private func openNewNavSwiftUI2() {
        presentNewNavigationController(from: self, root: .swiftUI2)
    }

    @objc private func openNewNavUIKit1() {
        presentNewNavigationController(from: self, root: .uiKit1)
    }

    @objc private func openNewNavUIKit2() {
        presentNewNavigationController(from: self, root: .uiKit2)
    }

    @objc private func popCurrent() {
        routeStack?.pop()
    }

    @objc private func popToRootCurrent() {
        routeStack?.popToRoot()
    }

    @objc private func popToSwiftUI1() {
        routeStack?.pop(to: NavigationTestSwiftUIScreen1.self)
    }

    @objc private func popToSwiftUI2() {
        routeStack?.pop(to: NavigationTestSwiftUIScreen2.self)
    }

    @objc private func popToUIKit1() {
        routeStack?.pop(to: NavigationTestUIKitViewController1.self)
    }

    @objc private func popToUIKit2() {
        routeStack?.pop(to: NavigationTestUIKitViewController2.self)
    }

    @objc private func dismissPresented() {
        dismiss(animated: true)
    }
}

// MARK: - UIKit ViewController 2

@MainActor
final class NavigationTestUIKitViewController2: NavigationTestUIKitBaseViewController {
    init(instanceID: String, origin: String) {
        super.init(screenName: "UIKit ViewController 2", instanceID: instanceID, origin: origin)
    }

    override func setupButtons() {
        addSection(
            title: "RouteStack Push In Current UINavigationController",
            buttons: [
                makeButton("RouteStack -> Hosted SwiftUI Screen 1", action: #selector(openSwiftUI1)),
                makeButton("RouteStack -> Hosted SwiftUI Screen 2", action: #selector(openSwiftUI2)),
                makeButton("RouteStack -> UIKit ViewController 1", action: #selector(openUIKit1)),
                makeButton("RouteStack -> UIKit ViewController 2", action: #selector(openUIKit2))
            ]
        )

        addSection(
            title: "Present New UINavigationController With New RouteStack",
            buttons: [
                makeButton("New Nav -> SwiftUI Screen 1", action: #selector(openNewNavSwiftUI1)),
                makeButton("New Nav -> SwiftUI Screen 2", action: #selector(openNewNavSwiftUI2)),
                makeButton("New Nav -> UIKit ViewController 1", action: #selector(openNewNavUIKit1)),
                makeButton("New Nav -> UIKit ViewController 2", action: #selector(openNewNavUIKit2))
            ]
        )

        addSection(
            title: "Stack Actions",
            buttons: [
                makeButton("Pop", action: #selector(popCurrent)),
                makeButton("Pop To Root", action: #selector(popToRootCurrent)),
                makeButton("Pop To Hosted SwiftUI Screen 1", action: #selector(popToSwiftUI1)),
                makeButton("Pop To Hosted SwiftUI Screen 2", action: #selector(popToSwiftUI2)),
                makeButton("Pop To UIKit ViewController 1", action: #selector(popToUIKit1)),
                makeButton("Pop To UIKit ViewController 2", action: #selector(popToUIKit2)),
                makeButton("Dismiss Presented Navigation Controller", action: #selector(dismissPresented))
            ]
        )
    }

    @objc private func openSwiftUI1() {
        routeStack?.push(
            NavigationTestSwiftUIScreen1(
                instanceID: UUID().uuidString,
                origin: "RouteStack push from UIKit ViewController 2"
            )
        )
    }

    @objc private func openSwiftUI2() {
        routeStack?.push(
            NavigationTestSwiftUIScreen2(
                instanceID: UUID().uuidString,
                origin: "RouteStack push from UIKit ViewController 2"
            )
        )
    }

    @objc private func openUIKit1() {
        routeStack?.push(
            NavigationTestUIKitViewController1(
                instanceID: UUID().uuidString,
                origin: "RouteStack push from UIKit ViewController 2"
            )
        )
    }

    @objc private func openUIKit2() {
        routeStack?.push(
            NavigationTestUIKitViewController2(
                instanceID: UUID().uuidString,
                origin: "RouteStack push from UIKit ViewController 2"
            )
        )
    }

    @objc private func openNewNavSwiftUI1() {
        presentNewNavigationController(from: self, root: .swiftUI1)
    }

    @objc private func openNewNavSwiftUI2() {
        presentNewNavigationController(from: self, root: .swiftUI2)
    }

    @objc private func openNewNavUIKit1() {
        presentNewNavigationController(from: self, root: .uiKit1)
    }

    @objc private func openNewNavUIKit2() {
        presentNewNavigationController(from: self, root: .uiKit2)
    }

    @objc private func popCurrent() {
        routeStack?.pop()
    }

    @objc private func popToRootCurrent() {
        routeStack?.popToRoot()
    }

    @objc private func popToSwiftUI1() {
        routeStack?.pop(to: NavigationTestSwiftUIScreen1.self)
    }

    @objc private func popToSwiftUI2() {
        routeStack?.pop(to: NavigationTestSwiftUIScreen2.self)
    }

    @objc private func popToUIKit1() {
        routeStack?.pop(to: NavigationTestUIKitViewController1.self)
    }

    @objc private func popToUIKit2() {
        routeStack?.pop(to: NavigationTestUIKitViewController2.self)
    }

    @objc private func dismissPresented() {
        dismiss(animated: true)
    }
}

// MARK: - Optional SwiftUI Preview Host

struct NavigationTestPreviewRoot: View {
    var body: some View {
        NavigationTestSwiftUIFlowRoot(
            initialScreen: .swiftUI1,
            origin: "SwiftUI Preview Root"
        )
    }
}

