import XCTest

// XCUITest waits, with no public limit, for the app to become idle before every query. An app that never becomes idle
// would cost minutes per stop and starve the stops after it, so the wait is switched off in this test bundle only.
private let quiescenceOff: Void = {
    guard let cls = NSClassFromString("XCUIApplicationProcess") else { print("AUDIT quiescence class missing"); return }
    var count: UInt32 = 0
    guard let methods = class_copyMethodList(cls, &count) else { return }
    var names: [String] = []
    for i in 0..<Int(count) {
        let name = NSStringFromSelector(method_getName(methods[i]))
        guard name.hasPrefix("waitForQuiescenceIncludingAnimationsIdle") else { continue }
        let colons = name.filter { $0 == ":" }.count
        if colons == 1 {
            let block: @convention(block) (AnyObject, Bool) -> Void = { _, _ in }
            method_setImplementation(methods[i], imp_implementationWithBlock(block))
            names.append(name)
        } else if colons == 2 {
            let block: @convention(block) (AnyObject, Bool, Bool) -> Void = { _, _, _ in }
            method_setImplementation(methods[i], imp_implementationWithBlock(block))
            names.append(name)
        }
    }
    free(methods)
    print("AUDIT quiescence off \(names)")
}()

final class AuditStopsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
        _ = quiescenceOff
    }

    @MainActor
    func testStops() throws {
        let out = URL(fileURLWithPath: "/tmp/audit-stops")
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        XCUIDevice.shared.orientation = .portrait
        for stop in auditStops {
            print("AUDIT begin \(stop.id)")
            let app = XCUIApplication()
            app.launchArguments = ["-auditStop", stop.id]
            app.launch()
            let root = app.descendants(matching: .any).matching(identifier: stop.root).firstMatch
            let seen = root.waitForExistence(timeout: 10)
            if seen { usleep(1_200_000) }
            var tree = "error"
            do {
                let snapshot = try app.snapshot()
                let data = try JSONSerialization.data(withJSONObject: node(snapshot), options: [.sortedKeys])
                try data.write(to: out.appendingPathComponent(stop.id + ".json"))
                tree = "written"
            } catch {
                tree = "error \(error.localizedDescription)"
            }
            let png = XCUIScreen.main.screenshot().pngRepresentation
            try? png.write(to: out.appendingPathComponent(stop.id + ".png"))
            print("AUDIT stop \(stop.id) root=\(seen ? "present" : "absent") tree=\(tree) png=\(png.count)")
            app.terminate()
        }
        print("AUDIT DONE \(auditStops.count)")
    }

    private func node(_ s: XCUIElementSnapshot) -> [String: Any] {
        [
            "type": Int(s.elementType.rawValue),
            "identifier": s.identifier,
            "label": s.label,
            "value": (s.value as? String) ?? "",
            "enabled": s.isEnabled,
            "frame": [Double(s.frame.minX), Double(s.frame.minY), Double(s.frame.width), Double(s.frame.height)],
            "children": s.children.map { node($0) },
        ]
    }
}
