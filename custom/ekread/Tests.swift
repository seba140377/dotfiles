import Foundation

// Plain test runner (no XCTest): build and run via test.sh.
@main
struct Tests {
    static var failures = 0
    static var count = 0

    static func check(_ cond: Bool, _ name: String) {
        count += 1
        if cond {
            print("ok   \(name)")
        } else {
            failures += 1
            print("FAIL \(name)")
        }
    }

    static func throwsCode(_ code: Int32, _ name: String, _ body: () throws -> Void) {
        do {
            try body()
            check(false, "\(name) (no error)")
        } catch let e as CLIError {
            check(e.code == code && !e.message.isEmpty, name)
        } catch {
            check(false, "\(name) (unexpected \(error))")
        }
    }

    static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return c
    }()

    static func at(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    // 2026-10-11T15:00 local
    static let now = at("2026-10-11T15:00:00+02:00")

    static func day(_ s: String) throws -> Date {
        try parseDay(s, now: now, calendar: cal)
    }

    static func window(_ from: String?, _ to: String?) throws -> (start: Date, end: Date) {
        try dayWindow(from: from, to: to, now: now, calendar: cal)
    }

    static func main() {
        dateTests()
        print("\(count - failures)/\(count) passed")
        exit(failures == 0 ? 0 : 1)
    }

    static func dateTests() {
        check((try? day("2026-10-12")) == at("2026-10-12T00:00:00+02:00"), "parseDay ISO")
        check((try? day("today")) == at("2026-10-11T00:00:00+02:00"), "parseDay today")
        check((try? day("tomorrow")) == at("2026-10-12T00:00:00+02:00"), "parseDay tomorrow")
        check((try? day("+0d")) == at("2026-10-11T00:00:00+02:00"), "parseDay +0d")
        check((try? day("+7d")) == at("2026-10-18T00:00:00+02:00"), "parseDay +7d")
        for bad in ["2026-02-30", "2026-13-01", "morgen", "+d", "-1d", "+1.5d", "++1d", "+-1d", ""] {
            throwsCode(1, "parseDay rejects '\(bad)'") { _ = try day(bad) }
        }

        let w0 = try? window(nil, nil)
        check(w0?.start == at("2026-10-11T00:00:00+02:00") && w0?.end == at("2026-10-12T00:00:00+02:00"),
              "dayWindow default is today")
        let dst = try? window("2026-10-25", nil)
        check(dst?.start == at("2026-10-25T00:00:00+02:00") && dst?.end == at("2026-10-26T00:00:00+01:00"),
              "dayWindow --from only spans one calendar day")
        check(dst.map { $0.end.timeIntervalSince($0.start) } == 90000, "dayWindow DST day is 25h")
        let toOnly = try? window(nil, "+3d")
        check(toOnly?.start == at("2026-10-11T00:00:00+02:00") && toOnly?.end == at("2026-10-14T00:00:00+02:00"),
              "dayWindow --to only starts today")
        throwsCode(1, "dayWindow rejects to == from") { _ = try window("2026-10-12", "2026-10-12") }
        throwsCode(1, "dayWindow rejects to < from") { _ = try window("2026-10-12", "2026-10-11") }
    }
}
