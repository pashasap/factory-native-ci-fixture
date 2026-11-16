import Core
import SwiftUI

@main
struct FixtureApp: App {
    private let stop = UserDefaults.standard.string(forKey: "auditStop") ?? ""

    var body: some Scene {
        WindowGroup {
            StopView(stop: stop)
        }
    }
}

struct StopView: View {
    let stop: String

    var body: some View {
        switch stop {
        case "good":
            Button("Play") {}
                .accessibilityIdentifier("fixture.good")
        case "silent":
            Button {} label: { Image(systemName: "star.fill") }
                .accessibilityLabel(Text(""))
                .accessibilityIdentifier("fixture.silent")
        case "offscreen":
            Button("Far away") {}
                .accessibilityIdentifier("fixture.offscreen")
                .offset(x: 320)
        case "scrolled":
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(0..<20, id: \.self) { index in
                        Button("Row \(index)") {}
                            .frame(height: 80)
                    }
                }
            }
            .accessibilityIdentifier("fixture.scrolled")
        case "restless":
            RestlessView()
                .accessibilityIdentifier("fixture.restless")
        default:
            Text("No stop \(AuditStops.all.count)")
                .accessibilityIdentifier("fixture.none")
        }
    }
}

struct RestlessView: View {
    @State private var grown = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.2)) { context in
            VStack(spacing: 24) {
                Button("Tick \(Int(context.date.timeIntervalSince1970 * 5) % 1000)") {}
                Circle()
                    .frame(width: 40, height: 40)
                    .scaleEffect(grown ? 1.4 : 0.6)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.5).repeatForever()) { grown = true }
        }
    }
}
