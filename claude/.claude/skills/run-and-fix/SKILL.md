---
name: run-and-fix
description: Führt einen Befehl aus, analysiert Fehler und erstellt einen Schritt-für-Schritt-Behebungsplan. Verwenden wenn ein Befehl fehlschlägt und der Fehler behoben werden soll.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - EnterPlanMode
  - ExitPlanMode
  - AskUserQuestion
---

# /run-and-fix — Befehl ausführen und Fehler beheben

Führt einen Befehl aus, analysiert den Fehler, erstellt einen Plan zur Behebung und führt ihn auf Wunsch aus.

Argumente: `$ARGUMENTS`

---

## Ablauf

### Schritt 1 — Befehl ermitteln

Wenn `$ARGUMENTS` leer ist: Frage den Benutzer nach dem Befehl, der den Fehler verursacht hat.

Wenn `$ARGUMENTS` gesetzt ist: Verwende den übergebenen Wert direkt als Befehl.

### Schritt 2 — Befehl ausführen

Führe den Befehl mit `Bash` aus. Fange sowohl stdout als auch stderr ein.

- Wenn der Befehl **erfolgreich** ist (Exit-Code 0): Teile dem Benutzer mit, dass kein Fehler aufgetreten ist, und beende den Skill.
- Wenn der Befehl **fehlschlägt** (Exit-Code ≠ 0): Fahre mit Schritt 3 fort.

### Schritt 3 — Fehleranalyse

Analysiere die Ausgabe gründlich und präsentiere dem Benutzer eine klare Fehlerbeschreibung in folgendem Format:

```
## Fehleranalyse

**Befehl:** <ausgeführter Befehl>
**Exit-Code:** <code>

**Fehlermeldung:**
<relevante Fehlerausgabe>

**Ursache:**
<kurze, klare Erklärung was schiefgelaufen ist>

**Betroffene Komponenten:**
<Dateien, Dienste, Abhängigkeiten die betroffen sind>
```

### Schritt 4 — Plan erstellen (Plan Mode)

Wechsle in den Plan Mode mit `EnterPlanMode` und erstelle einen detaillierten Schritt-für-Schritt-Plan zur Fehlerbehebung.

Der Plan muss:
- Jeden Schritt klar und umsetzbar beschreiben
- Konkrete Befehle oder Dateiänderungen nennen
- Die Reihenfolge der Schritte begründen wenn nicht offensichtlich
- Mögliche Nebeneffekte oder Risiken je Schritt nennen

Verlasse den Plan Mode mit `ExitPlanMode` nachdem der Plan fertig ist.

### Schritt 5 — Benutzer fragen

Frage den Benutzer mit `AskUserQuestion` ob er den erstellten Plan ausführen möchte:

- **"Ja, Plan ausführen"** → Fahre mit Schritt 6 fort
- **"Nein, nur Plan anzeigen"** → Beende den Skill ohne weitere Aktionen

### Schritt 6 — Plan ausführen

Führe die Schritte des Plans sequenziell aus:

- Führe jeden Schritt durch und gib eine kurze Statusmeldung aus
- Wenn ein Schritt fehlschlägt: Halte an, beschreibe was schiefgelaufen ist, und frage den Benutzer wie weitergemacht werden soll
- Nach Abschluss aller Schritte: Führe den ursprünglichen Befehl erneut aus, um zu bestätigen dass der Fehler behoben ist
- Teile dem Benutzer das Ergebnis mit

---

## Wichtige Hinweise

- Sei präzise bei der Fehleranalyse — erkläre die eigentliche Ursache, nicht nur die Symptome
- Der Plan soll minimal und zielgerichtet sein — keine unnötigen Schritte
- Wenn der Fehler mehrdeutig ist, liste mögliche Ursachen und erkläre welche am wahrscheinlichsten ist
- Sicherheitskritische Befehle (rm -rf, Datenbankoperationen etc.) immer explizit benennen und um Bestätigung bitten
