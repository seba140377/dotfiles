import EventKit
import Foundation

// ekread entry point: EventKit access and output. Read-only by construction:
// nothing here calls save/remove/commit on the event store.

let store = EKEventStore()
let calendar = Calendar.current

func fail(_ e: CLIError) -> Never {
    FileHandle.standardError.write(Data((e.message + "\n").utf8))
    exit(e.code)
}

@MainActor func noAccess(_ type: EKEntityType) -> CLIError {
    let what = type == .event ? "Kalender" : "Erinnerungen"
    return CLIError(
        message: "Kein Zugriff auf \(what). Freigeben unter Systemeinstellungen → Datenschutz & Sicherheit → \(what) für „ekread“ (Vollzugriff). Nach einem Neubau von ekread ist die Freigabe erneut nötig.",
        code: 2)
}

/// True if full access is granted, asking once if not yet determined.
@MainActor func hasAccess(_ type: EKEntityType) async -> Bool {
    switch EKEventStore.authorizationStatus(for: type) {
    case .fullAccess:
        return true
    case .notDetermined:
        let granted = try? await (type == .event
            ? store.requestFullAccessToEvents()
            : store.requestFullAccessToReminders())
        return granted ?? false
    default:
        return false
    }
}

@MainActor func requireAccess(_ type: EKEntityType) async throws {
    guard await hasAccess(type) else { throw noAccess(type) }
}

@MainActor func output<T: Encodable>(_ v: [T]) throws {
    print(try encodeJSON(v, timeZone: calendar.timeZone))
}

@MainActor func listCalendars() async throws {
    var out: [CalendarOut] = []
    var granted = false
    for (type, label) in [(EKEntityType.event, "events"), (.reminder, "reminders")] {
        guard await hasAccess(type) else {
            FileHandle.standardError.write(Data((noAccess(type).message + "\n").utf8))
            continue
        }
        granted = true
        out += store.calendars(for: type)
            .map { CalendarOut(name: $0.title, source: $0.source.title, type: label) }
            .sorted { ($0.source, $0.name) < ($1.source, $1.name) }
    }
    guard granted else { exit(2) }
    try output(out)
}

@MainActor func listEvents(from: String?, to: String?, names: [String]) async throws {
    let window = try dayWindow(from: from, to: to, now: Date(), calendar: calendar)
    try await requireAccess(.event)
    let cals = try selectByName(store.calendars(for: .event), names: names, kind: "Kalender") { $0.title }
    let pred = store.predicateForEvents(withStart: window.start, end: window.end, calendars: names.isEmpty ? nil : cals)
    let events = store.events(matching: pred)
        .sorted { $0.startDate < $1.startDate }
        .map {
            EventOut(
                title: $0.title ?? "", start: $0.startDate, end: $0.endDate, allDay: $0.isAllDay,
                calendar: $0.calendar.title, location: $0.location, notes: $0.notes,
                url: $0.url?.absoluteString, recurring: $0.hasRecurrenceRules)
        }
    try output(events)
}

@MainActor func listReminders(lists: [String], dueBefore: String?, includeCompleted: Bool) async throws {
    let before = try dueBefore.map { try parseDay($0, now: Date(), calendar: calendar) }
    try await requireAccess(.reminder)
    let cals = try selectByName(store.calendars(for: .reminder), names: lists, kind: "Liste") { $0.title }
    let scope = lists.isEmpty ? nil : cals
    let pred = includeCompleted
        ? store.predicateForReminders(in: scope)
        : store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: before, calendars: scope)
    let fetched: [EKReminder]? = await withCheckedContinuation { cont in
        store.fetchReminders(matching: pred) { cont.resume(returning: $0) }
    }
    let found = try fetchedOrError(fetched, kind: "Erinnerungen")
    var reminders = found.map { r -> ReminderOut in
        let due = r.dueDateComponents.flatMap { ($0.calendar ?? calendar).date(from: $0) }
        return ReminderOut(
            title: r.title ?? "", list: r.calendar.title, due: due,
            priority: priorityLabel(r.priority), notes: r.notes, completed: r.isCompleted)
    }
    // predicateForReminders(in:) ignores the due date, so filter here too.
    if let before { reminders = reminders.filter { ($0.due.map { $0 < before }) ?? false } }
    try output(sortReminders(reminders))
}

// macOS attributes privacy access to the "responsible" app: the terminal, or
// the claude binary when Claude Code runs ekread. Those may lack the calendar
// usage description, and macOS then denies access without asking. So ekread
// re-spawns itself with disclaimed responsibility: macOS then checks ekread's
// own embedded Info.plist, and one grant for ekread works everywhere.
@_silgen_name("responsibility_spawnattrs_setdisclaim")
func responsibility_spawnattrs_setdisclaim(_ attrs: UnsafeMutablePointer<posix_spawnattr_t?>, _ disclaim: Int32) -> Int32

let disclaimedEnv = "EKREAD_DISCLAIMED"

/// Runs this binary again as a disclaimed child and exits with its status.
/// Returns only if spawning fails; the caller then continues in-process.
func respawnDisclaimed() {
    var size: UInt32 = 0
    _NSGetExecutablePath(nil, &size)
    var path = [CChar](repeating: 0, count: Int(size))
    guard _NSGetExecutablePath(&path, &size) == 0 else { return }

    var attrs: posix_spawnattr_t?
    posix_spawnattr_init(&attrs)
    defer { posix_spawnattr_destroy(&attrs) }
    guard responsibility_spawnattrs_setdisclaim(&attrs, 1) == 0 else { return }

    setenv(disclaimedEnv, "1", 1)
    let argv = CommandLine.unsafeArgv
    var pid: pid_t = 0
    guard posix_spawn(&pid, path, nil, &attrs, argv, environ) == 0 else {
        unsetenv(disclaimedEnv)
        return
    }
    var status: Int32 = 0
    while waitpid(pid, &status, 0) == -1 && errno == EINTR {}
    exit(exitCode(fromWaitStatus: status))
}

do {
    let command = try parseArgs(Array(CommandLine.arguments.dropFirst()))
    if command != .help, ProcessInfo.processInfo.environment[disclaimedEnv] == nil {
        respawnDisclaimed()
    }
    switch command {
    case .help:
        print(helpText)
    case .calendars:
        try await listCalendars()
    case let .events(from, to, names):
        try await listEvents(from: from, to: to, names: names)
    case let .reminders(lists, dueBefore, includeCompleted):
        try await listReminders(lists: lists, dueBefore: dueBefore, includeCompleted: includeCompleted)
    }
} catch let e as CLIError {
    fail(e)
} catch {
    fail(CLIError(message: "Fehler: \(error)", code: 1))
}
