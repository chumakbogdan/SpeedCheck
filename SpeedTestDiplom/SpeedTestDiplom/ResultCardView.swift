import SwiftUI

struct ResultCardView: View {
    let result: TestResult
    
    var unitToDisplay: String {
        return result.unit ?? "Mbps"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(Color.blue.opacity(0.7))
                        Text("Download")
                            .font(.headline)
                            .foregroundColor(Color.blue.opacity(0.7))
                    }
                    Text("\(result.downloadSpeed, specifier: "%.2f") \(unitToDisplay)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.blue.opacity(0.7))
                }

                Spacer()

                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle")
                            .foregroundColor(Color.purple.opacity(0.7))
                        Text("Upload")
                            .font(.headline)
                            .foregroundColor(Color.purple.opacity(0.7))
                    }
                    Text("\(result.uploadSpeed, specifier: "%.2f") \(unitToDisplay)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.purple.opacity(0.7))
                }

                Spacer()

                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(Color.orange.opacity(0.7))
                        Text("Ping")
                            .font(.headline)
                            .foregroundColor(Color.orange.opacity(0.7))
                    }
                    Text("\(result.ping, specifier: "%.0f") ms")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.orange.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
        }
        .padding()
        .background(Color(.systemGray5))
        .clipShape(Capsule())
        .padding(.horizontal)
    }
}
