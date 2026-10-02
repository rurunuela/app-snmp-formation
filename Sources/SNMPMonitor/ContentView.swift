import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: MonitorStore
    @State private var selection: MetricCategory? = .system

    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TargetBar()
                    SummaryView()
                    DetailSection(category: selection ?? .system)
                }
                .padding(20)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

private struct Sidebar: View {
    @Binding var selection: MetricCategory?

    var body: some View {
        List(MetricCategory.allCases, selection: $selection) { category in
            Label(category.rawValue, systemImage: icon(for: category))
                .tag(category)
        }
        .navigationTitle("SNMP Linux")
        .listStyle(.sidebar)
    }

    private func icon(for category: MetricCategory) -> String {
        switch category {
        case .system: return "server.rack"
        case .load: return "waveform.path.ecg"
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .swap: return "arrow.left.arrow.right"
        case .disks: return "internaldrive"
        case .network: return "network"
        case .processes: return "terminal"
        case .hostResources: return "externaldrive"
        }
    }
}

private struct TargetBar: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Cible Net-SNMP")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                if store.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(store.status)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                GridRow {
                    TextField("IP ou hostname", text: hostBinding)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 220)
                    TextField("Communaute", text: communityBinding)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                    Stepper("Intervalle \(Int(store.refreshInterval))s", value: $store.refreshInterval, in: 2...120, step: 1)
                        .frame(width: 170, alignment: .leading)
                    Button {
                        store.refreshOnce()
                    } label: {
                        Label("Rafraichir", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        store.togglePolling()
                    } label: {
                        Label(store.isPolling ? "Stop" : "Auto", systemImage: store.isPolling ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack(spacing: 12) {
                Label("SNMP v2c", systemImage: "checkmark.seal")
                Label("Communaute: \(store.target.community)", systemImage: "key")
                if let lastRefresh = store.lastRefresh {
                    Label(lastRefresh.formatted(date: .omitted, time: .standard), systemImage: "clock")
                }
            }
            .foregroundStyle(.secondary)
            .font(.callout)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var hostBinding: Binding<String> {
        Binding(
            get: { store.target.host },
            set: { store.target.host = $0 }
        )
    }

    private var communityBinding: Binding<String> {
        Binding(
            get: { store.target.community },
            set: { store.target.community = $0 }
        )
    }
}

private struct SummaryView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                SummaryCard(title: "Load", primary: store.sample(named: "Load 1 min")?.displayValue ?? "-", secondary: "1 min")
                SummaryCard(title: "Load 5 min", primary: store.sample(named: "Load 5 min")?.displayValue ?? "-", secondary: "tendance")
                SummaryCard(title: "Utilisateurs", primary: store.sample(named: "Utilisateurs")?.displayValue ?? "-", secondary: "sessions")
                SummaryCard(title: "Processus", primary: store.sample(named: "Nombre de processus")?.displayValue ?? "-", secondary: "actifs")
            }
            GridRow {
                MemoryCard(title: "RAM", total: store.sample(named: "RAM totale")?.value, free: store.sample(named: "RAM disponible")?.value)
                MemoryCard(title: "Swap", total: store.sample(named: "Swap total")?.value, free: store.sample(named: "Swap disponible")?.value)
                SummaryCard(title: "Processus", primary: store.sample(named: "Nombre de processus")?.displayValue ?? "-", secondary: "actifs")
                SummaryCard(title: "Machine", primary: store.sample(named: "Nom machine")?.displayValue ?? "-", secondary: store.target.host)
            }
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let primary: String
    let secondary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(primary)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(secondary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct MemoryCard: View {
    let title: String
    let total: String?
    let free: String?

    private var usage: Double? {
        guard let total = Double(total ?? ""), let free = Double(free ?? ""), total > 0 else { return nil }
        return max(0, min(1, (total - free) / total))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(percentText)
                .font(.title2)
                .fontWeight(.semibold)
            ProgressView(value: usage ?? 0)
                .tint(progressColor)
            Text(detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var percentText: String {
        guard let usage else { return "-" }
        return "\(Int(usage * 100)) %"
    }

    private var detailText: String {
        guard let total, let free else { return "en attente de collecte" }
        return "total \(total) kB, libre \(free) kB"
    }

    private var progressColor: Color {
        guard let usage else { return .secondary }
        if usage > 0.9 { return .red }
        if usage > 0.75 { return .orange }
        return .green
    }
}

private struct DetailSection: View {
    @EnvironmentObject private var store: MonitorStore
    let category: MetricCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.rawValue)
                .font(.title2)
                .fontWeight(.semibold)

            switch category {
            case .disks:
                TableView(columns: MetricCatalog.diskColumns, rows: store.diskRows)
            case .network:
                TableView(columns: MetricCatalog.networkColumns, rows: store.networkRows)
            case .processes:
                TableView(columns: MetricCatalog.processColumns, rows: Array(store.processRows.prefix(250)))
            case .hostResources:
                VStack(alignment: .leading, spacing: 14) {
                    ScalarGrid(samples: store.samples(for: .hostResources))
                    TableView(columns: MetricCatalog.storageColumns, rows: store.storageRows)
                }
            default:
                ScalarGrid(samples: store.samples(for: category))
            }
        }
    }
}

private struct ScalarGrid: View {
    let samples: [MetricSample]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 12)], spacing: 12) {
            ForEach(samples) { sample in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(sample.metric.name)
                            .font(.headline)
                        Spacer()
                        Text(sample.date.formatted(date: .omitted, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(sample.displayValue)
                        .font(.title3)
                        .fontWeight(.medium)
                        .textSelection(.enabled)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                    Text(sample.metric.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(sample.metric.oid)
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
                .padding(14)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .overlay {
            if samples.isEmpty {
                EmptyStateView()
                    .frame(height: 220)
            }
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("Aucune donnee")
                .font(.headline)
            Text("Renseignez la cible puis lancez une collecte SNMP.")
                .foregroundStyle(.secondary)
        }
    }
}

private struct TableView: View {
    let columns: [(key: String, title: String, oid: String)]
    let rows: [TableRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView([.horizontal, .vertical]) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("#")
                            .fontWeight(.semibold)
                            .frame(width: 52, alignment: .leading)
                        ForEach(columns, id: \.key) { column in
                            Text(column.title)
                                .fontWeight(.semibold)
                                .frame(width: width(for: column.key), alignment: .leading)
                        }
                    }
                    Divider()
                        .gridCellColumns(columns.count + 1)
                    ForEach(rows) { row in
                        GridRow {
                            Text(row.id)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 52, alignment: .leading)
                            ForEach(columns, id: \.key) { column in
                                Text(row.values[column.key] ?? "-")
                                    .lineLimit(2)
                                    .textSelection(.enabled)
                                    .frame(width: width(for: column.key), alignment: .leading)
                            }
                        }
                    }
                }
                .padding(12)
            }
            .frame(minHeight: 320)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if rows.isEmpty {
                Text("Aucune ligne collectee. Verifiez la cible, la communaute SNMP et les vues exposees par snmpd.conf.")
                    .foregroundStyle(.secondary)
            } else {
                Text("\(rows.count) ligne(s)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func width(for key: String) -> CGFloat {
        switch key {
        case "args", "message", "path", "description": return 260
        case "mount", "device", "name": return 150
        default: return 110
        }
    }
}
