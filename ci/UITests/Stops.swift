let auditStops: [(id: String, root: String)] = [
    (id: "good", root: "fixture.good"),
    (id: "silent", root: "fixture.silent"),
    (id: "offscreen", root: "fixture.offscreen"),
    (id: "scrolled", root: "fixture.scrolled"),
    (id: "frozen", root: "fixture.frozen"),
    (id: "sheet", root: "fixture.sheet"),
    (id: "locked", root: "fixture.locked"),
    (id: "trail", root: "fixture.trail"),
    (id: "home", root: "fixture.home"),
    (id: "home-locked", root: "fixture.home-locked"),
    (id: "ghost", root: "fixture.ghost"),
]

extension AuditStopsUITests {
    @MainActor func test_001_good() { visit("good", root: "fixture.good") }
    @MainActor func test_002_silent() { visit("silent", root: "fixture.silent") }
    @MainActor func test_003_offscreen() { visit("offscreen", root: "fixture.offscreen") }
    @MainActor func test_004_scrolled() { visit("scrolled", root: "fixture.scrolled") }
    @MainActor func test_005_frozen() { visit("frozen", root: "fixture.frozen") }
    @MainActor func test_006_sheet() { visit("sheet", root: "fixture.sheet") }
    @MainActor func test_007_locked() { visit("locked", root: "fixture.locked") }
    @MainActor func test_008_trail() { visit("trail", root: "fixture.trail") }
    @MainActor func test_009_home() { visit("home", root: "fixture.home") }
    @MainActor func test_010_home_locked() { visit("home-locked", root: "fixture.home-locked") }
    @MainActor func test_011_ghost() { visit("ghost", root: "fixture.ghost") }
}
