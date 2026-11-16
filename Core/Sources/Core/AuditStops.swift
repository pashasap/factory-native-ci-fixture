public struct AuditStop: Sendable, Equatable {
    public let id: String
    public let root: String
    public let title: String
    public let expectation: String
    public let flows: [String]
    public let defects: [String]

    public init(id: String, root: String, title: String, expectation: String, flows: [String], defects: [String]) {
        self.id = id
        self.root = root
        self.title = title
        self.expectation = expectation
        self.flows = flows
        self.defects = defects
    }
}

public enum AuditStops {
    public static let all: [AuditStop] = [
        AuditStop(id: "good", root: "fixture.good", title: "A labelled button", expectation: "One button that says Play.", flows: ["F-01"], defects: []),
        AuditStop(id: "silent", root: "fixture.silent", title: "A button with no spoken label", expectation: "One star button.", flows: [], defects: ["F-000001"]),
        AuditStop(id: "offscreen", root: "fixture.offscreen", title: "A button pushed past the right edge", expectation: "One button fully on screen.", flows: [], defects: []),
        AuditStop(id: "scrolled", root: "fixture.scrolled", title: "A long list", expectation: "A list of twenty rows that scrolls.", flows: ["F-02"], defects: []),
        AuditStop(id: "restless", root: "fixture.restless", title: "A screen that never stops moving", expectation: "One button and a circle.", flows: [], defects: []),
        AuditStop(id: "ghost", root: "fixture.ghost", title: "A stop the app does not open", expectation: "Never shown.", flows: [], defects: []),
    ]
}
