import Foundation
import Combine

@MainActor
final class OceanPresenter: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let interactor: OceanInteractor
    private let coordinator: OceanCoordinator
    
    private var deadlineTask: Task<Void, Never>?
    private var uiLocked: Bool = false
    
    init() {
        let interactor = OceanInteractor()
        let coordinator = OceanCoordinator()
        
        self.interactor = interactor
        self.coordinator = coordinator
        
        interactor.output = coordinator
        coordinator.routes = { [weak self] action in
            self?.handleNavigationAction(action)
        }
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    func wakeUp() {
        Task {
            interactor.bootUp()
            armDeadline()
        }
    }
    
    func feedAttribution(_ data: [String: Any]) {
        Task {
            interactor.absorbAttribution(data)
            await interactor.navigate()
        }
    }
    
    func feedCourses(_ data: [String: Any]) {
        Task {
            interactor.absorbCourses(data)
        }
    }
    
    func confirmConsent() {
        Task {
            await interactor.confirmConsent()
            showPermissionPrompt = false
        }
    }
    
    func skipConsent() {
        interactor.deferConsent()
        showPermissionPrompt = false
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleNavigationAction(_ action: NavAction) {
        guard !uiLocked else {
            return
        }
        
        switch action {
        case .wait:
            break
        case .raiseConsent:
            showPermissionPrompt = true
        case .voyageToWeb:
            navigateToWeb = true
        case .voyageToMain:
            navigateToMain = true
        case .offlineAlert:
            showOfflineView = true
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.interactor.reportTimeout()
            if shouldFire {
                self.handleNavigationAction(.voyageToMain)
            }
        }
    }
}

final class OceanCoordinator: InteractorOutput {
    
    var routes: ((NavAction) -> Void)?
    
    func interactorRequestsNavigation(_ action: NavAction) {
        DispatchQueue.main.async { [weak self] in
            self?.routes?(action)
        }
    }
}
