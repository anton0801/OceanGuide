import Foundation

final class Resolver {
    
    static let main = Resolver()
    
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private let lock = NSLock()
    
    private var bootstrapped = false
    
    private init() {}
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        factories[String(describing: type)] = factory
    }
    
    func registerSingleton<T>(_ type: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }
        singletons[String(describing: type)] = instance
    }
    
    func resolve<T>(_ type: T.Type = T.self) -> T {
        ensureBootstrapped()
        
        lock.lock()
        let key = String(describing: type)
        
        // Сначала ищем singleton
        if let instance = singletons[key] as? T {
            lock.unlock()
            return instance
        }
        
        // Потом factory
        if let factory = factories[key] {
            lock.unlock()
            guard let instance = factory() as? T else {
                fatalError("\(OceanConstants.logBuoy) Factory for \(key) returned wrong type")
            }
            return instance
        }
        
        lock.unlock()
        fatalError("\(OceanConstants.logBuoy) No registration for \(key)")
    }
    
    private func ensureBootstrapped() {
        lock.lock()
        let needsBootstrap = !bootstrapped
        if needsBootstrap {
            bootstrapped = true
        }
        lock.unlock()
        
        guard needsBootstrap else { return }
        
        registerSingleton(AttributionMariner.self, instance: NetworkAttributionMariner())
        registerSingleton(DestinationMariner.self, instance: NetworkDestinationMariner())
        registerSingleton(VerificationMariner.self, instance: SupabaseVerificationMariner())
        registerSingleton(ConsentMariner.self, instance: NotificationConsentMariner())
        registerSingleton(SeabedRepository.self, instance: UserDefaultsSeabedRepository())
    }
    
    static func setupDefaults() {
        _ = main
        main.ensureBootstrapped()
    }
}
