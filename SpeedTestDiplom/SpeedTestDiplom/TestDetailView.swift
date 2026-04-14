import SwiftUI
import CoreData

struct TestDetailView: View {
    @Environment(\.dismiss) private var dismiss
    var result: TestResult
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(result.date?.formatted(date: .long, time: .standard) ?? "Unknown date")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top)

                HStack(alignment: .top, spacing: 12) {
                    MetricCard(
                        title: "Download",
                        valueText: formattedSpeed(result.downloadSpeed, unit: result.unit),
                        systemImage: "arrow.down.circle",
                        color: .blue
                    )

                    MetricCard(
                        title: "Upload",
                        valueText: formattedSpeed(result.uploadSpeed, unit: result.unit),
                        systemImage: "arrow.up.circle",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                HStack(spacing: 12){
                    MetricCard(
                        title: "Ping",
                        valueText: formattedPing(result.ping),
                        systemImage: "waveform.path.ecg",
                        color: .orange,
                        subtitle: AnyView(pingSubtitle())
                    )
                }
                .padding(.horizontal)

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: networkIcon())
                                .font(.system(size: 22))
                                .foregroundColor(.accentColor)
                            Text("Network")
                                .font(.headline)
                        }

                        if let type = result.networkType, !type.isEmpty {
                            InfoRow(left: "Type", right: type)
                        }

                        if let ip = result.ipAddress, !ip.isEmpty {
                            InfoRow(left: "IP", right: ip)
                        }

                        if let isp = result.ispName, !isp.isEmpty {
                            InfoRow(left: "ISP", right: isp)
                        }
                    }
                }
                .padding(.horizontal)

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: "location.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.accentColor)
                            Text("Location")
                                .font(.headline)
                        }

                        if let city = result.city, !city.isEmpty {
                            InfoRow(left: "City", right: city)
                        }

                        if let lat = optionalDouble(result.latitude), let lon = optionalDouble(result.longitude) {
                            InfoRow(left: "Coordinates", right: String(format: "%.5f, %.5f", lat, lon))
                        }
                    }
                }
                .padding(.horizontal)

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 22))
                                .foregroundColor(.accentColor)
                            Text("Server")
                                .font(.headline)
                        }

                        if let city = result.serverCity, !city.isEmpty {
                            InfoRow(left: "City", right: city)
                        }

                        if let country = result.serverCountry, !country.isEmpty {
                            InfoRow(left: "Country", right: country)
                        }

                        if let host = result.serverHost, !host.isEmpty {
                            InfoRow(left: "Host", right: host)
                        }
                    }
                }
                .padding(.horizontal)

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 22))
                                .foregroundColor(.accentColor)
                            Text("Data Used")
                                .font(.headline)
                        }

                        if let dl = optionalDouble(result.downloadedMb) {
                            InfoRow(left: "Downloaded", right: String(format: "%.2f MB", dl))
                        }
                        if let ul = optionalDouble(result.uploadedMb) {
                            InfoRow(left: "Uploaded", right: String(format: "%.2f MB", ul))
                        }

                        if let dl = optionalDouble(result.downloadedMb), let ul = optionalDouble(result.uploadedMb) {
                            InfoRow(left: "Total", right: String(format: "%.2f MB", dl + ul))
                        }
                    }
                }
                .padding(.horizontal)
                
                Button(action:{
                    showDeleteAlert = true
                }) {
                    Label("Delete Result", systemImage: "trash")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.bottom)
        }
        .navigationTitle("Test Details")
        .alert("Delete Result?", isPresented: $showDeleteAlert){
            Button("Delete", role: .destructive){
                deleteThisResult()
            }
            Button("Cancel", role: .cancel){}
        } message: {
            Text("Are you sure you want to delete this test result? This action cannot be undone.")
        }
    }
    
    private func deleteThisResult() {
        StorageManager.shared.delete(result: result)
        dismiss()
    }

    @ViewBuilder
    private func pingSubtitle() -> some View {
        HStack(spacing: 12) {
            if let jitter = optionalDouble(result.jitter) {
                Text("Jitter: \(String(format: "%.0f", jitter)) ms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let pl = optionalDouble(result.packetLoss) {
                Text("Packet loss: \(String(format: "%.1f", pl))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func networkIcon() -> String {
        let type = result.networkType?.lowercased() ?? ""
        if type.contains("wi") { return "wifi" }
        if type.contains("4g") || type.contains("lte") { return "antenna.radiowaves.left.and.right" }
        if type.contains("5g") { return "antenna.radiowaves.left.and.right" }
        return "network"
    }

    private func formattedSpeed(_ value: Double, unit: String?) -> String {
        let u = unit ?? "Mbps"
        return String(format: "%.2f %@", value, u)
    }

    private func formattedPing(_ value: Double) -> String {
        return String(format: "%.0f ms", value)
    }

    private func optionalDouble(_ number: Double?) -> Double? {
        return number == nil ? nil : number
    }
}

// MARK: - Reusable components

private struct MetricCard: View {
    let title: String
    let valueText: String
    let systemImage: String
    let color: Color
    var subtitle: AnyView? = nil

    init(title: String, valueText: String, systemImage: String, color: Color, subtitle: AnyView? = nil) {
        self.title = title
        self.valueText = valueText
        self.systemImage = systemImage
        self.color = color
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundColor(color)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(valueText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)

            if let subtitle = subtitle {
                subtitle
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct InfoRow: View {
    let left: String
    let right: String
    var body: some View {
        HStack {
            Text(left)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(right)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview
struct TestDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let sample = TestResult(context: context)
        sample.downloadSpeed = 98.4
        sample.uploadSpeed = 47.2
        sample.ping = 23
        sample.jitter = 4.2
        sample.packetLoss = 0.5
        sample.unit = "Mbps"
        sample.serverName = "SpeedChecker Warsaw"
        sample.serverCity = "Warsaw"
        sample.serverCountry = "PL"
        sample.serverHost = "warsaw.speedchecker.net"
        sample.date = Date()
        sample.networkType = "WiFi"
        sample.ipAddress = "93.184.216.34"
        sample.ispName = "UPC Polska"
        sample.latitude = 52.2297
        sample.longitude = 21.0122
        sample.city = "Warsaw"
        sample.downloadedMb = 5.2
        sample.uploadedMb = 1.1

        return NavigationStack {
            TestDetailView(result: sample)
        }
        .environment(\.managedObjectContext, context)
    }
}
