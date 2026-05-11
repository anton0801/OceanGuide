import Foundation

protocol SeabedRepository {
    func anchor(samples: [String: String])
    func anchor(courses: [String: String])
    func anchor(anchor: String, current: String)
    func anchor(consent: ConsentTide)
    func markVoyaged()
    func recall() -> SeabedReading
}

protocol VerificationMariner {
    func verify() async throws
}

protocol AttributionMariner {
    func cast(deviceID: String) async throws -> [String: Any]
}

protocol DestinationMariner {
    func chart(seed: [String: Any]) async throws -> String
}

protocol ConsentMariner {
    func summon() async throws -> Bool
    func enlist()
}

extension AttributionTide {
    func persist(via repo: SeabedRepository) {
        repo.anchor(samples: samples)
        repo.anchor(courses: courses)
    }
}

extension DestinationTide {
    func persist(via repo: SeabedRepository) {
        guard let anchor = anchor, let current = current else { return }
        repo.anchor(anchor: anchor, current: current)
    }
}

extension ConsentTide {
    func persist(via repo: SeabedRepository) {
        repo.anchor(consent: self)
    }
}

final class UserDefaultsSeabedRepository: SeabedRepository {
    
    private let tidesStore: UserDefaults
    private let homeStore: UserDefaults
    
    init() {
        self.tidesStore = UserDefaults(suiteName: OceanConstants.suiteTides)!
        self.homeStore = UserDefaults.standard
    }
    
    // MARK: - Anchor (write)
    
    func anchor(samples: [String: String]) {
        guard let encoded = encode(samples) else { return }
        tidesStore.set(encoded, forKey: SeabedKey.samples)
    }
    
    func anchor(courses: [String: String]) {
        guard let encoded = encode(courses) else { return }
        let veiled = veil(encoded)
        tidesStore.set(veiled, forKey: SeabedKey.courses)
    }
    
    func anchor(anchor: String, current: String) {
        tidesStore.set(anchor, forKey: SeabedKey.anchor)
        homeStore.set(anchor, forKey: SeabedKey.anchor)
        tidesStore.set(current, forKey: SeabedKey.current)
    }
    
    func anchor(consent: ConsentTide) {
        tidesStore.set(consent.conferred, forKey: SeabedKey.conferred)
        tidesStore.set(consent.dismissed, forKey: SeabedKey.dismissed)
        if let when = consent.summonedAt {
            let ms = when.timeIntervalSince1970 * 1000
            tidesStore.set(ms, forKey: SeabedKey.summoned)
        }
    }
    
    func markVoyaged() {
        tidesStore.set(true, forKey: SeabedKey.voyaged)
    }
    
    // MARK: - Recall (read)
    
    func recall() -> SeabedReading {
        let samplesRaw = tidesStore.string(forKey: SeabedKey.samples) ?? ""
        let samples = decode(samplesRaw) ?? [:]
        
        let coursesVeiled = tidesStore.string(forKey: SeabedKey.courses) ?? ""
        let coursesRaw = unveil(coursesVeiled) ?? ""
        let courses = decode(coursesRaw) ?? [:]
        
        let anchor = tidesStore.string(forKey: SeabedKey.anchor)
        let current = tidesStore.string(forKey: SeabedKey.current)
        let voyaged = tidesStore.bool(forKey: SeabedKey.voyaged)
        
        let conferred = tidesStore.bool(forKey: SeabedKey.conferred)
        let dismissed = tidesStore.bool(forKey: SeabedKey.dismissed)
        let summonedMs = tidesStore.double(forKey: SeabedKey.summoned)
        let summonedAt = summonedMs > 0 ? Date(timeIntervalSince1970: summonedMs / 1000) : nil
        
        return SeabedReading(
            samples: samples,
            courses: courses,
            anchor: anchor,
            current: current,
            pristine: !voyaged,
            conferred: conferred,
            dismissed: dismissed,
            summonedAt: summonedAt
        )
    }
    
    // MARK: - Encode / Decode
    
    private func encode(_ dict: [String: String]) -> String? {
        let anyDict = dict.mapValues { $0 as Any }
        guard let data = try? JSONSerialization.data(withJSONObject: anyDict),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
    
    private func decode(_ text: String) -> [String: String]? {
        guard let data = text.data(using: .utf8),
              let any = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return any.mapValues { "\($0)" }
    }
    
    // MARK: - Veiling
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "=", with: "(")
            .replacingOccurrences(of: "+", with: ")")
    }
    
    private func unveil(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "(", with: "=")
            .replacingOccurrences(of: ")", with: "+")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }
}
