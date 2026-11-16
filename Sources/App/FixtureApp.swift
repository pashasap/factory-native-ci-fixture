import Core
import Foundation
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
        case "frozen":
            Text("Frozen")
                .accessibilityIdentifier("fixture.frozen")
                .onAppear { Thread.sleep(forTimeInterval: 900) }
        default:
            Text("No stop \(AuditStops.all.count)")
                .accessibilityIdentifier("fixture.none")
        }
    }
}
