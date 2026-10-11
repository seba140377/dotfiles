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
