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

/// The screen a locked level falls back to when saved progress is ignored.
struct TrailView: View {
    var body: some View {
        VStack(spacing: 24) {
            Button("Level one") {}
            Button("Level two") {}
            Button("Settings") {}
        }
    }
}

/// A screen whose `root` identifier sits on the view that renders it (on its title), as the conventions ask.
struct HomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Home").accessibilityIdentifier("fixture.home")
            Button("Home level one") {}
            Button("Home level two") {}
            Button("Home settings") {}
        }
    }
}

struct SheetView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("A sheet").accessibilityIdentifier("fixture.sheet")
            Button("Close sheet") {}
        }
        .padding()
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
        case "sheet":
            Text("Behind the sheet")
                .sheet(isPresented: .constant(true)) { SheetView() }
        case "locked":
            // the stop tries to open a locked level, the audit launch does not unlock it, and the app shows the trail:
            // the root identifier sits on the outer wrapper, so the root check passes on the wrong screen
            TrailView()
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("fixture.locked")
        case "trail":
            TrailView()
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("fixture.trail")
        case "home":
            HomeView()
        case "home-locked":
            // tries to open a locked level and falls back to the home screen: the fallback carries the home screen's
            // own root, so the home stop is right and this one is the wrong one
            HomeView()
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("fixture.home-locked")
        default:
            Text("No stop \(AuditStops.all.count)")
                .accessibilityIdentifier("fixture.none")
        }
    }
}
