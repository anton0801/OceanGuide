import Foundation
import AppsFlyerLib

protocol InteractorOutput: AnyObject {
    func interactorRequestsNavigation(_ action: NavAction)
}

final class OceanInteractor {
    
    weak var output: InteractorOutput?
    
    private(set) var attribution: AttributionTide = .calm
    private(set) var destination: DestinationTide = .calm
    private(set) var consent: ConsentTide = .calm
    private var organicProcessed: Bool = false
    
    private var sequenceCompleted: Bool = false
    
    private let repo: SeabedRepository
    private let verifier: VerificationMariner
    private let attributor: AttributionMariner
    private let destinator: DestinationMariner
    private let consenter: ConsentMariner
    
    init() {
        self.repo = Resolver.main.resolve()
        self.verifier = Resolver.main.resolve()
        self.attributor = Resolver.main.resolve()
        self.destinator = Resolver.main.resolve()
        self.consenter = Resolver.main.resolve()
    }
    
    func bootUp() {
        let reading = repo.recall()
        attribution = AttributionTide(samples: reading.samples, courses: reading.courses)
        destination = DestinationTide(
            anchor: reading.anchor,
            current: reading.current,
            pristine: reading.pristine,
            sealed: false
        )
        consent = ConsentTide(
            conferred: reading.conferred,
            dismissed: reading.dismissed,
            summonedAt: reading.summonedAt
        )
    }
    
    func absorbAttribution(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        attribution.samples = mapped
        repo.anchor(samples: mapped)
    }
    
    func absorbCourses(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        attribution.courses = mapped
        repo.anchor(courses: mapped)
    }
    
    func navigate() async {
        guard !sequenceCompleted else { return }
        
        if let tempURL = UserDefaults.standard.string(forKey: SeabedKey.pushURL),
           !tempURL.isEmpty {
            anchorDestination(url: tempURL)
            return
        }
        
        guard attribution.saturated else {
            return
        }
        
        do {
            try await verifier.verify()
        } catch {
            sequenceCompleted = true
            output?.interactorRequestsNavigation(.voyageToMain)
            return
        }
        
        if attribution.organicCurrent && destination.pristine && !organicProcessed {
            organicProcessed = true
            await performOrganicCast()
        }
        
        do {
            let url = try await destinator.chart(seed: attribution.samples.mapValues { $0 as Any })
            anchorDestination(url: url)
        } catch {
            sequenceCompleted = true
            output?.interactorRequestsNavigation(.voyageToMain)
        }
    }
    
    func confirmConsent() async {
        var localConsent = consent
        
        do {
            let granted = try await consenter.summon()
            
            if granted {
                localConsent.conferred = true
                localConsent.dismissed = false
                localConsent.summonedAt = Date()
                consenter.enlist()
            } else {
                localConsent.conferred = false
                localConsent.dismissed = true
                localConsent.summonedAt = Date()
            }
        } catch {
            localConsent.conferred = false
            localConsent.dismissed = true
            localConsent.summonedAt = Date()
        }
        
        consent = localConsent
        repo.anchor(consent: localConsent)
        
        output?.interactorRequestsNavigation(.voyageToWeb)
    }
    
    func deferConsent() {
        consent.summonedAt = Date()
        repo.anchor(consent: consent)
        output?.interactorRequestsNavigation(.voyageToWeb)
    }
    
    func reportTimeout() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
    
    private func performOrganicCast() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !destination.sealed else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await attributor.cast(deviceID: deviceID)
            
            for (k, v) in attribution.courses {
                if fetched[k] == nil {
                    fetched[k] = v
                }
            }
            
            let mapped = fetched.mapValues { "\($0)" }
            attribution.samples = mapped
            repo.anchor(samples: mapped)
        } catch {
        }
    }
    
    private func anchorDestination(url: String) {
        let needsConsent = consent.navigable
        
        destination.anchor = url
        destination.current = "Active"
        destination.pristine = false
        destination.sealed = true
        
        repo.anchor(anchor: url, current: "Active")
        repo.markVoyaged()
        
        UserDefaults.standard.removeObject(forKey: SeabedKey.pushURL)
        
        sequenceCompleted = true
        
        if needsConsent {
            output?.interactorRequestsNavigation(.raiseConsent)
        } else {
            output?.interactorRequestsNavigation(.voyageToWeb)
        }
    }
}
