import Foundation
import SwiftUI

@MainActor
final class MonitorStore: ObservableObject {
    @Published var target = SNMPTarget()
    @Published var refreshInterval: Double = 10
    @Published var isPolling = false
    @Published var isLoading = false
    @Published var status = "Pret"
    @Published var lastRefresh: Date?
    @Published var samples: [String: MetricSample] = [:]
    @Published var diskRows: [TableRow] = []
    @Published var networkRows: [TableRow] = []
    @Published var processRows: [TableRow] = []
    @Published var storageRows: [TableRow] = []
    @Published var history: [String: [MetricSample]] = [:]

    private let client = SNMPClient()
    private var pollingTask: Task<Void, Never>?

    deinit {
        pollingTask?.cancel()
    }

    func refreshOnce() {
        Task {
            await refresh()
        }
    }

    func togglePolling() {
        isPolling ? stopPolling() : startPolling()
    }

    func startPolling() {
        guard !isPolling else { return }
        isPolling = true
        status = "Surveillance active"
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                guard let interval = self?.refreshInterval else { break }
                let nanoseconds = UInt64(interval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
            }
        }
    }

    func stopPolling() {
        isPolling = false
        pollingTask?.cancel()
        pollingTask = nil
        status = "Surveillance arretee"
    }

    func sample(named name: String) -> MetricSample? {
        samples.values.first { $0.metric.name == name }
    }

    func samples(for category: MetricCategory) -> [MetricSample] {
        MetricCatalog.scalarMetrics
            .filter { $0.category == category }
            .compactMap { samples[$0.id] }
    }

    private func refresh() async {
        guard !isLoading else { return }

        guard !target.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = "Adresse cible manquante"
            return
        }

        isLoading = true
        status = "Interrogation SNMP..."
        let currentTarget = target

        do {
            let fetchedSamples = try await fetchScalars(target: currentTarget)
            let fetchedDiskRows = try await fetchTable(columns: MetricCatalog.diskColumns, target: currentTarget)
            let fetchedNetworkRows = try await fetchTable(columns: MetricCatalog.networkColumns, target: currentTarget)
            let fetchedProcessRows = try await fetchTable(columns: MetricCatalog.processColumns, target: currentTarget)
            let fetchedStorageRows = try await fetchTable(columns: MetricCatalog.storageColumns, target: currentTarget)

            for sample in fetchedSamples {
                samples[sample.metric.id] = sample
                history[sample.metric.id, default: []].append(sample)
                if history[sample.metric.id, default: []].count > 60 {
                    history[sample.metric.id]?.removeFirst()
                }
            }
            diskRows = fetchedDiskRows.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
            networkRows = fetchedNetworkRows.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
            processRows = fetchedProcessRows.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
            storageRows = fetchedStorageRows.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
            lastRefresh = Date()
            status = "Derniere collecte OK"
        } catch {
            status = error.localizedDescription
        }

        isLoading = false
    }

    private func fetchScalars(target: SNMPTarget) async throws -> [MetricSample] {
        var fetched: [MetricSample] = []
        for metric in MetricCatalog.scalarMetrics {
            do {
                fetched.append(try await client.get(metric: metric, target: target))
            } catch {
                let sample = MetricSample(metric: metric, value: "N/A", rawLine: error.localizedDescription, date: Date())
                fetched.append(sample)
            }
        }
        return fetched
    }

    private func fetchTable(columns: [(key: String, title: String, oid: String)], target: SNMPTarget) async throws -> [TableRow] {
        var rows: [String: TableRow] = [:]
        for column in columns {
            let values = try await client.walk(baseOID: column.oid, target: target)
            for (index, value) in values {
                var row = rows[index] ?? TableRow(id: index, values: [:])
                row.values[column.key] = value
                rows[index] = row
            }
        }
        return Array(rows.values)
    }
}
