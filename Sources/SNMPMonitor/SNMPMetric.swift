import Foundation

enum MetricCategory: String, CaseIterable, Identifiable {
    case system = "Systeme"
    case load = "Charge"
    case cpu = "CPU"
    case memory = "Memoire"
    case swap = "Swap"
    case disks = "Disques"
    case network = "Reseau"
    case processes = "Processus"
    case hostResources = "Stockage hote"

    var id: String { rawValue }
}

enum MetricKind: String {
    case scalar
    case table
}

struct SNMPMetric: Identifiable, Hashable {
    let id: String
    let category: MetricCategory
    let name: String
    let oid: String
    let detail: String
    let kind: MetricKind
    let unit: String?

    init(category: MetricCategory, name: String, oid: String, detail: String, kind: MetricKind = .scalar, unit: String? = nil) {
        self.id = oid
        self.category = category
        self.name = name
        self.oid = oid
        self.detail = detail
        self.kind = kind
        self.unit = unit
    }
}

struct MetricSample: Identifiable, Hashable {
    let id = UUID()
    let metric: SNMPMetric
    let value: String
    let rawLine: String
    let date: Date

    var displayValue: String {
        guard let unit = metric.unit, !value.isEmpty else { return value }
        return "\(value) \(unit)"
    }
}

struct TableRow: Identifiable, Hashable {
    let id: String
    var values: [String: String]
}

struct SNMPTarget: Equatable {
    var host: String = "192.168.64.2"
    var community: String = "training"
}

enum MetricCatalog {
    static let scalarMetrics: [SNMPMetric] = [
        .init(category: .system, name: "Description systeme", oid: ".1.3.6.1.2.1.1.1.0", detail: "OS, noyau et architecture"),
        .init(category: .system, name: "Uptime SNMP", oid: ".1.3.6.1.2.1.1.3.0", detail: "Temps depuis le demarrage de l'agent"),
        .init(category: .system, name: "Contact administrateur", oid: ".1.3.6.1.2.1.1.4.0", detail: "Contact configure dans snmpd.conf"),
        .init(category: .system, name: "Nom machine", oid: ".1.3.6.1.2.1.1.5.0", detail: "Hostname"),
        .init(category: .system, name: "Localisation", oid: ".1.3.6.1.2.1.1.6.0", detail: "Localisation configuree dans snmpd.conf"),
        .init(category: .hostResources, name: "Uptime hote", oid: ".1.3.6.1.2.1.25.1.1.0", detail: "Temps depuis le demarrage du systeme"),
        .init(category: .hostResources, name: "Date systeme", oid: ".1.3.6.1.2.1.25.1.2.0", detail: "Date et heure systeme"),
        .init(category: .hostResources, name: "Utilisateurs", oid: ".1.3.6.1.2.1.25.1.5.0", detail: "Nombre de sessions utilisateur"),
        .init(category: .processes, name: "Nombre de processus", oid: ".1.3.6.1.2.1.25.1.6.0", detail: "Processus actifs"),

        .init(category: .load, name: "Load 1 min", oid: ".1.3.6.1.4.1.2021.10.1.3.1", detail: "Charge moyenne sur 1 minute"),
        .init(category: .load, name: "Load 5 min", oid: ".1.3.6.1.4.1.2021.10.1.3.2", detail: "Charge moyenne sur 5 minutes"),
        .init(category: .load, name: "Load 15 min", oid: ".1.3.6.1.4.1.2021.10.1.3.3", detail: "Charge moyenne sur 15 minutes"),

        .init(category: .cpu, name: "CPU utilisateur", oid: ".1.3.6.1.4.1.2021.11.9.0", detail: "Pourcentage CPU en mode utilisateur", unit: "%"),
        .init(category: .cpu, name: "CPU systeme", oid: ".1.3.6.1.4.1.2021.11.10.0", detail: "Pourcentage CPU en mode noyau", unit: "%"),
        .init(category: .cpu, name: "CPU idle", oid: ".1.3.6.1.4.1.2021.11.11.0", detail: "Pourcentage CPU inactif", unit: "%"),
        .init(category: .cpu, name: "CPU raw user", oid: ".1.3.6.1.4.1.2021.11.50.0", detail: "Compteur brut du temps CPU utilisateur"),
        .init(category: .cpu, name: "CPU raw nice", oid: ".1.3.6.1.4.1.2021.11.51.0", detail: "Compteur brut du temps CPU nice"),
        .init(category: .cpu, name: "CPU raw system", oid: ".1.3.6.1.4.1.2021.11.52.0", detail: "Compteur brut du temps CPU systeme"),
        .init(category: .cpu, name: "CPU raw idle", oid: ".1.3.6.1.4.1.2021.11.53.0", detail: "Compteur brut du temps CPU idle"),
        .init(category: .cpu, name: "CPU raw iowait", oid: ".1.3.6.1.4.1.2021.11.54.0", detail: "Compteur brut du temps CPU en attente I/O"),
        .init(category: .cpu, name: "CPU raw interrupt", oid: ".1.3.6.1.4.1.2021.11.56.0", detail: "Compteur brut du temps CPU en interruptions"),
        .init(category: .cpu, name: "CPU raw softirq", oid: ".1.3.6.1.4.1.2021.11.61.0", detail: "Compteur brut du temps CPU en softirq"),
        .init(category: .cpu, name: "CPU raw steal", oid: ".1.3.6.1.4.1.2021.11.64.0", detail: "Compteur brut du temps CPU vole par l'hyperviseur"),

        .init(category: .memory, name: "RAM totale", oid: ".1.3.6.1.4.1.2021.4.5.0", detail: "Memoire RAM totale", unit: "kB"),
        .init(category: .memory, name: "RAM disponible", oid: ".1.3.6.1.4.1.2021.4.6.0", detail: "Memoire RAM disponible", unit: "kB"),
        .init(category: .memory, name: "RAM partagee", oid: ".1.3.6.1.4.1.2021.4.13.0", detail: "Memoire partagee", unit: "kB"),
        .init(category: .memory, name: "Memoire buffer", oid: ".1.3.6.1.4.1.2021.4.14.0", detail: "Memoire utilisee pour les buffers", unit: "kB"),
        .init(category: .memory, name: "Memoire cache", oid: ".1.3.6.1.4.1.2021.4.15.0", detail: "Cache disque", unit: "kB"),

        .init(category: .swap, name: "Swap total", oid: ".1.3.6.1.4.1.2021.4.3.0", detail: "Taille totale du swap", unit: "kB"),
        .init(category: .swap, name: "Swap disponible", oid: ".1.3.6.1.4.1.2021.4.4.0", detail: "Swap libre", unit: "kB"),
        .init(category: .swap, name: "Swap minimum", oid: ".1.3.6.1.4.1.2021.4.12.0", detail: "Seuil minimum configure", unit: "kB")
    ]

    static let diskColumns: [(key: String, title: String, oid: String)] = [
        ("mount", "Montage", ".1.3.6.1.4.1.2021.9.1.2"),
        ("device", "Peripherique", ".1.3.6.1.4.1.2021.9.1.3"),
        ("total", "Total", ".1.3.6.1.4.1.2021.9.1.6"),
        ("available", "Libre", ".1.3.6.1.4.1.2021.9.1.7"),
        ("used", "Utilise", ".1.3.6.1.4.1.2021.9.1.8"),
        ("usedPercent", "% disque", ".1.3.6.1.4.1.2021.9.1.9"),
        ("inodePercent", "% inodes", ".1.3.6.1.4.1.2021.9.1.10"),
        ("error", "Erreur", ".1.3.6.1.4.1.2021.9.1.100"),
        ("message", "Message", ".1.3.6.1.4.1.2021.9.1.101")
    ]

    static let networkColumns: [(key: String, title: String, oid: String)] = [
        ("name", "Interface", ".1.3.6.1.2.1.2.2.1.2"),
        ("type", "Type", ".1.3.6.1.2.1.2.2.1.3"),
        ("mtu", "MTU", ".1.3.6.1.2.1.2.2.1.4"),
        ("speed", "Debit declare", ".1.3.6.1.2.1.2.2.1.5"),
        ("admin", "Admin", ".1.3.6.1.2.1.2.2.1.7"),
        ("oper", "Oper", ".1.3.6.1.2.1.2.2.1.8"),
        ("rx", "Octets RX", ".1.3.6.1.2.1.2.2.1.10"),
        ("tx", "Octets TX", ".1.3.6.1.2.1.2.2.1.16"),
        ("rxErrors", "Erreurs RX", ".1.3.6.1.2.1.2.2.1.14"),
        ("txErrors", "Erreurs TX", ".1.3.6.1.2.1.2.2.1.20"),
        ("rxDrops", "Drops RX", ".1.3.6.1.2.1.2.2.1.13"),
        ("txDrops", "Drops TX", ".1.3.6.1.2.1.2.2.1.19")
    ]

    static let processColumns: [(key: String, title: String, oid: String)] = [
        ("name", "Processus", ".1.3.6.1.2.1.25.4.2.1.2"),
        ("pid", "PID", ".1.3.6.1.2.1.25.4.2.1.3"),
        ("path", "Chemin", ".1.3.6.1.2.1.25.4.2.1.4"),
        ("args", "Arguments", ".1.3.6.1.2.1.25.4.2.1.5"),
        ("state", "Etat", ".1.3.6.1.2.1.25.4.2.1.7")
    ]

    static let storageColumns: [(key: String, title: String, oid: String)] = [
        ("type", "Type", ".1.3.6.1.2.1.25.2.3.1.2"),
        ("description", "Description", ".1.3.6.1.2.1.25.2.3.1.3"),
        ("allocation", "Unite", ".1.3.6.1.2.1.25.2.3.1.4"),
        ("size", "Taille", ".1.3.6.1.2.1.25.2.3.1.5"),
        ("used", "Utilise", ".1.3.6.1.2.1.25.2.3.1.6"),
        ("errors", "Erreurs", ".1.3.6.1.2.1.25.2.3.1.7")
    ]
}
