import Foundation
import SwiftSnmpKit

extension SnmpPduType: @retroactive @unchecked Sendable {}
extension SnmpVariableBinding: @retroactive @unchecked Sendable {}
extension AsnValue: @retroactive @unchecked Sendable {}
extension SnmpOid: @retroactive @unchecked Sendable {}

enum SNMPClientError: LocalizedError {
    case senderUnavailable
    case requestFailed(String)
    case invalidOutput(String)
    case walkLimitReached(String)

    var errorDescription: String? {
        switch self {
        case .senderUnavailable:
            return "Client SNMP natif indisponible."
        case .requestFailed(let message):
            return message
        case .invalidOutput(let line):
            return "Sortie SNMP non reconnue: \(line)"
        case .walkLimitReached(let oid):
            return "Parcours SNMP interrompu apres trop de reponses sous \(oid)"
        }
    }
}

actor SNMPClient {
    private let maxWalkIterations = 10_000

    func get(metric: SNMPMetric, target: SNMPTarget) async throws -> MetricSample {
        let variableBinding = try await send(command: .getRequest, target: target, oid: metric.oid)
        let value = try stringValue(from: variableBinding.value)
        return MetricSample(metric: metric, value: value, rawLine: variableBinding.description, date: Date())
    }

    func walk(baseOID: String, target: SNMPTarget) async throws -> [String: String] {
        let normalizedBaseOID = normalizeOID(baseOID)
        var values: [String: String] = [:]
        var nextOID = normalizedBaseOID

        for _ in 0..<maxWalkIterations {
            let variableBinding = try await send(command: .getNextRequest, target: target, oid: nextOID)
            let oid = normalizeOID(variableBinding.oid.description)

            guard oidIsInsideSubtree(oid, baseOID: normalizedBaseOID) else {
                return values
            }
            guard variableBinding.value != .endOfMibView else {
                return values
            }

            let index = oid.split(separator: ".").last.map(String.init) ?? oid
            values[index] = try stringValue(from: variableBinding.value)
            nextOID = oid
        }

        throw SNMPClientError.walkLimitReached(baseOID)
    }

    private func send(command: SnmpPduType, target: SNMPTarget, oid: String) async throws -> SnmpVariableBinding {
        guard let snmpSender = SnmpSender.shared else {
            throw SNMPClientError.senderUnavailable
        }

        let result = await snmpSender.send(
            host: target.host,
            command: command,
            community: target.community,
            oid: normalizeOID(oid)
        )

        switch result {
        case .success(let variableBinding):
            return variableBinding
        case .failure(let error):
            throw SNMPClientError.requestFailed(error.localizedDescription)
        }
    }

    private func stringValue(from value: AsnValue) throws -> String {
        switch value {
        case .integer(let value):
            return String(value)
        case .octetString(let data):
            return String(data: data, encoding: .utf8) ?? data.map { String(format: "%02x", $0) }.joined()
        case .oid(let oid):
            return oid.description
        case .null:
            return ""
        case .ia5(let value):
            return value
        case .ipv4(let value):
            return [
                (value & 0xff000000) >> 24,
                (value & 0x00ff0000) >> 16,
                (value & 0x0000ff00) >> 8,
                value & 0x000000ff
            ]
            .map(String.init)
            .joined(separator: ".")
        case .counter32(let value), .gauge32(let value), .timeticks(let value):
            return String(value)
        case .counter64(let value):
            return String(value)
        case .noSuchObject, .endOfMibView:
            throw SNMPClientError.invalidOutput(value.description)
        default:
            return value.description
        }
    }

    private func normalizeOID(_ oid: String) -> String {
        oid.trimmingCharacters(in: CharacterSet(charactersIn: ".").union(.whitespacesAndNewlines))
    }

    private func oidIsInsideSubtree(_ oid: String, baseOID: String) -> Bool {
        oid == baseOID || oid.hasPrefix("\(baseOID).")
    }
}
