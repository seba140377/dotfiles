import Foundation

// Pure logic of ekread (no EventKit): argument and date parsing, selection,
// JSON output. Tested by Tests.swift.

struct CLIError: Error, Equatable {
    let message: String
    let code: Int32
}

/// Parses a day spec (`YYYY-MM-DD`, `today`, `tomorrow`, `+Nd`) to the start
/// of that day in `calendar`'s time zone.
func parseDay(_ s: String, now: Date, calendar: Calendar) throws -> Date {
    let today = calendar.startOfDay(for: now)
    var offset: Int?
    switch s {
    case "today": offset = 0
    case "tomorrow": offset = 1
    default:
        let digits = s.dropFirst().dropLast()
        if s.hasPrefix("+"), s.hasSuffix("d"), !digits.isEmpty,
           digits.allSatisfy({ $0.isASCII && $0.isNumber }),
           let n = Int(digits) {
            offset = n
        }
    }
    if let offset {
        guard let d = calendar.date(byAdding: .day, value: offset, to: today) else {
            throw CLIError(message: "Ungültiges Datum: \(s)", code: 1)
        }
        return d
    }

    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.calendar = calendar
    f.timeZone = calendar.timeZone
    f.dateFormat = "yyyy-MM-dd"
    f.isLenient = false
    // Round trip rejects overflow such as 2026-02-30.
    guard let d = f.date(from: s), f.string(from: d) == s else {
        throw CLIError(
            message: "Ungültiges Datum: '\(s)' (erwartet YYYY-MM-DD, today, tomorrow oder +Nd)",
            code: 1)
    }
    return calendar.startOfDay(for: d)
}

/// Time window for `events`: `from` defaults to today, `to` (exclusive) to
/// one calendar day after `from`.
func dayWindow(from: String?, to: String?, now: Date, calendar: Calendar) throws -> (start: Date, end: Date) {
    let start = try parseDay(from ?? "today", now: now, calendar: calendar)
    let end: Date
    if let to {
        end = try parseDay(to, now: now, calendar: calendar)
    } else {
        end = calendar.date(byAdding: .day, value: 1, to: start)!
    }
    guard end > start else {
        throw CLIError(message: "--to muss nach --from liegen", code: 1)
    }
    return (start, end)
}

// MARK: - Arguments

enum Command: Equatable {
    case help
    case calendars
    case events(from: String?, to: String?, calendars: [String])
    case reminders(lists: [String], dueBefore: String?, includeCompleted: Bool)
}

/// Parses the arguments after the program name. Empty means help.
func parseArgs(_ args: [String]) throws -> Command {
    guard let cmd = args.first else { return .help }
    var rest = Array(args.dropFirst())

    func usage(_ msg: String) -> CLIError {
        CLIError(message: "\(msg) (siehe ekread --help)", code: 1)
    }
    func value(for opt: String) throws -> String {
        guard !rest.isEmpty else { throw usage("Wert fehlt für \(opt)") }
        return rest.removeFirst()
    }

    switch cmd {
    case "--help", "-h", "help":
        return .help
    case "calendars":
        guard rest.isEmpty else { throw usage("Unerwartetes Argument: \(rest[0])") }
        return .calendars
    case "events":
        var from: String?, to: String?, cals: [String] = []
        while !rest.isEmpty {
            let opt = rest.removeFirst()
            switch opt {
            case "--from": from = try value(for: opt)
            case "--to": to = try value(for: opt)
            case "--calendar": cals.append(try value(for: opt))
            default: throw usage("Unbekannte Option für events: \(opt)")
            }
        }
        return .events(from: from, to: to, calendars: cals)
    case "reminders":
        var lists: [String] = [], due: String?, completed = false
        while !rest.isEmpty {
            let opt = rest.removeFirst()
            switch opt {
            case "--list": lists.append(try value(for: opt))
            case "--due-before": due = try value(for: opt)
            case "--include-completed": completed = true
            default: throw usage("Unbekannte Option für reminders: \(opt)")
            }
        }
        return .reminders(lists: lists, dueBefore: due, includeCompleted: completed)
    default:
        throw usage("Unbekannter Befehl: \(cmd)")
    }
}

/// Filters `items` to those whose name is in `names`; empty `names` keeps all.
/// Same-named items are all kept; an unknown name is an error.
func selectByName<T>(_ items: [T], names: [String], kind: String, name: (T) -> String) throws -> [T] {
    guard !names.isEmpty else { return items }
    let known = Set(items.map(name))
    if let missing = names.first(where: { !known.contains($0) }) {
        throw CLIError(message: "Unbekannte(r) \(kind): \(missing)", code: 1)
    }
    let wanted = Set(names)
    return items.filter { wanted.contains(name($0)) }
}

/// EventKit reports a failed fetch as nil; never pass that off as "nothing found".
func fetchedOrError<T>(_ items: [T]?, kind: String) throws -> [T] {
    guard let items else {
        throw CLIError(message: "Abruf der \(kind) fehlgeschlagen", code: 1)
    }
    return items
}

/// Exit code for a waitpid status: the child's code, or 128 + signal.
func exitCode(fromWaitStatus status: Int32) -> Int32 {
    let signal = status & 0x7f
    return signal == 0 ? (status >> 8) & 0xff : 128 + signal
}

// MARK: - Output

/// EventKit priority (0 none, 1–4 high, 5 medium, 6–9 low) as a label.
func priorityLabel(_ p: Int) -> String {
    switch p {
    case 1...4: return "high"
    case 5: return "medium"
    case 6...9: return "low"
    default: return "none"
    }
}

struct CalendarOut: Encodable {
    let name: String
    let source: String
    let type: String
}

struct EventOut: Encodable {
    let title: String
    let start: Date
    let end: Date
    let allDay: Bool
    let calendar: String
    let location: String?
    let notes: String?
    let url: String?
    let recurring: Bool

    enum CodingKeys: String, CodingKey {
        case title, start, end, allDay = "all_day", calendar, location, notes, url, recurring
    }

    // Explicit encode so missing values become null instead of being omitted.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        try c.encode(start, forKey: .start)
        try c.encode(end, forKey: .end)
        try c.encode(allDay, forKey: .allDay)
        try c.encode(calendar, forKey: .calendar)
        try c.encode(location, forKey: .location)
        try c.encode(notes, forKey: .notes)
        try c.encode(url, forKey: .url)
        try c.encode(recurring, forKey: .recurring)
    }
}

struct ReminderOut: Encodable {
    let title: String
    let list: String
    let due: Date?
    let priority: String
    let notes: String?
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case title, list, due, priority, notes, completed
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        try c.encode(list, forKey: .list)
        try c.encode(due, forKey: .due)
        try c.encode(priority, forKey: .priority)
        try c.encode(notes, forKey: .notes)
        try c.encode(completed, forKey: .completed)
    }
}

/// Sorts by due date, undated reminders last, ties by title.
func sortReminders(_ r: [ReminderOut]) -> [ReminderOut] {
    r.sorted { a, b in
        switch (a.due, b.due) {
        case let (x?, y?) where x != y: return x < y
        case (nil, _?): return false
        case (_?, nil): return true
        default: return a.title < b.title
        }
    }
}

func encodeJSON<T: Encodable>(_ v: [T], timeZone: TimeZone) throws -> String {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime]
    iso.timeZone = timeZone
    let e = JSONEncoder()
    e.outputFormatting = [.sortedKeys, .withoutEscapingSlashes, .prettyPrinted]
    e.dateEncodingStrategy = .custom { date, encoder in
        var c = encoder.singleValueContainer()
        try c.encode(iso.string(from: date))
    }
    return String(decoding: try e.encode(v), as: UTF8.self)
}

let helpText = """
ekread – liest Kalender und Erinnerungen über EventKit (nur lesend), Ausgabe als JSON.

Befehle:
  ekread calendars
      Kalender und Erinnerungslisten (name, source, type).
  ekread events [--from D] [--to D] [--calendar NAME ...]
      Termine im Zeitfenster [from, to). Standard: heute 00:00 bis morgen 00:00.
      Nur --from: genau dieser Tag. Nur --to: ab heute.
  ekread reminders [--list NAME ...] [--due-before D] [--include-completed]
      Standard: alle offenen Erinnerungen, auch ohne Fälligkeit.
      --due-before: nur Erinnerungen mit Fälligkeit vor D.

D: YYYY-MM-DD, today, tomorrow oder +Nd (N Tage ab heute), jeweils 00:00 Ortszeit.
--calendar und --list sind wiederholbar und vergleichen den Namen exakt.

Exit-Codes: 0 Erfolg, 1 Bedienfehler, 2 Zugriff auf Kalender/Erinnerungen nicht freigegeben.
"""
