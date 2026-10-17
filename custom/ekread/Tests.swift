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
        argTests()
        outputTests()
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

    static func args(_ a: [String]) throws -> Command { try parseArgs(a) }

    static func argTests() {
        check((try? args([])) == .help, "parseArgs empty is help")
        for h in ["--help", "-h", "help"] {
            check((try? args([h])) == .help, "parseArgs \(h) is help")
        }
        check((try? args(["calendars"])) == .calendars, "parseArgs calendars")
        check((try? args(["events"])) == .events(from: nil, to: nil, calendars: []), "parseArgs events defaults")
        check((try? args(["events", "--from", "today", "--calendar", "A", "--calendar", "B"]))
              == .events(from: "today", to: nil, calendars: ["A", "B"]), "parseArgs events repeated --calendar")
        check((try? args(["events", "--to", "+3d"])) == .events(from: nil, to: "+3d", calendars: []), "parseArgs events --to")
        check((try? args(["reminders"])) == .reminders(lists: [], dueBefore: nil, includeCompleted: false, completedSince: nil),
              "parseArgs reminders defaults")
        check((try? args(["reminders", "--include-completed", "--list", "X", "--due-before", "tomorrow"]))
              == .reminders(lists: ["X"], dueBefore: "tomorrow", includeCompleted: true, completedSince: nil),
              "parseArgs reminders options")
        check((try? args(["reminders", "--completed-since", "2026-10-12"]))
              == .reminders(lists: [], dueBefore: nil, includeCompleted: true, completedSince: "2026-10-12"),
              "parseArgs reminders --completed-since implies --include-completed")
        throwsCode(1, "--completed-since needs value") { _ = try args(["reminders", "--completed-since"]) }
        throwsCode(1, "parseArgs rejects unknown command") { _ = try args(["foo"]) }
        throwsCode(1, "parseArgs rejects unknown option") { _ = try args(["events", "--bogus"]) }
        throwsCode(1, "parseArgs rejects missing value") { _ = try args(["events", "--from"]) }
        throwsCode(1, "parseArgs rejects extra argument") { _ = try args(["calendars", "x"]) }
        throwsCode(1, "parseArgs rejects --list on events") { _ = try args(["events", "--list", "X"]) }

        let names = ["Privat", "Arbeit", "Privat"]
        check((try? selectByName(names, names: ["Privat"], kind: "Kalender") { $0 })?.count == 2,
              "selectByName keeps all same-named calendars")
        check((try? selectByName(names, names: [], kind: "Kalender") { $0 })?.count == 3, "selectByName empty selects all")
        throwsCode(1, "selectByName rejects unknown name") {
            _ = try selectByName(names, names: ["Fehlt"], kind: "Kalender") { $0 }
        }
    }

    static func outputTests() {
        let expected: [(Int, String)] = [(0, "none"), (1, "high"), (4, "high"), (5, "medium"), (6, "low"), (9, "low")]
        for (p, label) in expected {
            check(priorityLabel(p) == label, "priorityLabel \(p) is \(label)")
        }

        let tz = TimeZone(identifier: "Europe/Berlin")!
        let ev = EventOut(title: "Zahnarzt", start: at("2026-10-12T09:00:00+02:00"), end: at("2026-10-12T10:00:00+02:00"),
                          allDay: false, calendar: "Privat", location: nil, notes: nil, url: nil, recurring: false)
        let json = (try? encodeJSON([ev], timeZone: tz)) ?? ""
        check(json.contains("\"location\" : null"), "encodeJSON writes null for missing location")
        check(json.contains("\"all_day\" : false"), "encodeJSON uses all_day key")
        check(json.contains("\"start\" : \"2026-10-12T09:00:00+02:00\""), "encodeJSON writes ISO date with offset")
        check((try? encodeJSON([EventOut](), timeZone: tz)) == "[\n\n]" || (try? encodeJSON([EventOut](), timeZone: tz)) == "[]",
              "encodeJSON empty is []")

        let rem = ReminderOut(title: "Müll", list: "Haushalt", due: nil, priority: "none", notes: nil, completed: false, completedAt: nil)
        let rjson = (try? encodeJSON([rem], timeZone: tz)) ?? ""
        check(rjson.contains("\"due\" : null"), "encodeJSON writes null for missing due")

        let a = ReminderOut(title: "a", list: "L", due: nil, priority: "none", notes: nil, completed: false, completedAt: nil)
        let b = ReminderOut(title: "b", list: "L", due: at("2026-10-13T00:00:00+02:00"), priority: "none", notes: nil, completed: false, completedAt: nil)
        let c = ReminderOut(title: "c", list: "L", due: at("2026-10-12T00:00:00+02:00"), priority: "none", notes: nil, completed: false, completedAt: nil)
        check(sortReminders([a, b, c]).map(\.title) == ["c", "b", "a"], "sortReminders by due, undated last")
        check(rjson.contains("\"completed_at\" : null"), "encodeJSON writes null for missing completed_at")

        func done(_ t: String, _ at: Date?, completed: Bool = true) -> ReminderOut {
            ReminderOut(title: t, list: "L", due: nil, priority: "none", notes: nil, completed: completed, completedAt: at)
        }
        let since = at("2026-10-12T00:00:00+02:00")
        let kept = filterCompletedSince([done("edge", since), done("before", at("2026-10-11T23:59:00+02:00"))], since: since)
        check(kept.map(\.title) == ["edge"], "filterCompletedSince keeps since instant, drops earlier")
        check(filterCompletedSince([done("nil", nil)], since: since).isEmpty, "filterCompletedSince drops nil")
        check(filterCompletedSince([done("open", since, completed: false)], since: since).isEmpty,
              "filterCompletedSince drops open reminders")
        let cjson = (try? encodeJSON([done("x", at("2026-10-14T18:20:00+02:00"))], timeZone: tz)) ?? ""
        check(cjson.contains("\"completed_at\" : \"2026-10-14T18:20:00+02:00\""), "encodeJSON writes completed_at as ISO date")

        check((try? fetchedOrError([1, 2], kind: "Erinnerungen")) == [1, 2], "fetchedOrError passes results")
        check((try? fetchedOrError([Int](), kind: "Erinnerungen")) == [], "fetchedOrError keeps empty result")
        throwsCode(1, "fetchedOrError rejects failed fetch") { _ = try fetchedOrError([Int]?.none, kind: "Erinnerungen") }

        check(exitCode(fromWaitStatus: 0) == 0, "exitCode normal exit 0")
        check(exitCode(fromWaitStatus: 2 << 8) == 2, "exitCode normal exit 2")
        check(exitCode(fromWaitStatus: 15) == 143, "exitCode killed by SIGTERM is 143")

        check(helpText.contains("events") && helpText.contains("reminders") && helpText.contains("calendars"),
              "helpText lists commands")
    }
}
