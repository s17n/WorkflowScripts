# Nutzerdokumentation

## Zweck

Der Workflow erstellt aus einem Kalendereintrag eine Meeting-Notiz im Markdown-Format.

Die Notiz wird im Inbox-Ordner des Zettelkastens angelegt und enthaelt:

- Frontmatter mit Meeting-Metadaten fuer spaetere Auswertung
- einen Todo-Bereich
- Termin-Details
- Teilnehmerinformationen, soweit vom Kalender lieferbar
- die Beschreibung des Kalendereintrags
- leere Bereiche fuer Mitschrift und Referenzen

## Was passiert

- Das Skript listet fuer ein uebergebenes Datum die Termine des Tages auf.
- Aus dem Termin wird ein Dateiname im Format `YYYYMMDD-HHMM.md` gebildet.
- Die Notiz wird im konfigurierten Inbox-Ordner erstellt.
- Ein Wiki-Link zur erzeugten Notiz wird in die Zwischenablage gelegt.

## Typischer Einsatz

Der uebliche Aufruf erfolgt aus der Daily Note heraus, zum Beispiel ueber PopClip mit einer markierten Uhrzeit.

Im manuellen Start zeigt das Skript einen Dialog mit diesen Aktionen:

- `List Meetings`: listet die Termine eines Tages zur Auswahl auf, inklusive Kalendername
- `Cancel`: bricht ab

## Eingaben

Unterstuetzt werden:

- `YYYY-MM-DD`

## Ergebnis

Die erzeugte Datei beginnt mit Frontmatter wie:

```md
---
meeting:
  day: 2025-05-02
  start: 13:00
  end: 14:00
  attendees_total: 4
  attendees_accepted: 2
  attendees_declined: 1
  attendees_tentative: 0
  attendees_other: 0
---
```

Danach folgen Bereiche fuer Todos, Termin, Description, Mitschrift und Referenzen.

## Voraussetzungen

- macOS mit Zugriff auf den Kalender
- installierte AppleScript Library `CalendarLib EC`
- installiertes GNU `date` unter `/opt/homebrew/bin/gdate`
- passende Werte in `~/.workflowscripts/config.scpt`

Die aufrufende Anwendung, typischerweise Script Editor oder PopClip, braucht Kalender-Zugriff unter macOS:

- `System Settings > Privacy & Security > Calendars`

## Bekannte Einschraenkungen

- Wenn eine Notiz bereits existiert, wird sie im aktuellen Stand ueberschrieben.
- Das Modul hat im aktuellen Stand keinen Hazel-Einstiegspunkt mehr.
- Wenn beim Entfernen des Call-In-Blocks Start- oder Endmarker fehlen, wird der Schritt uebersprungen und die Notiz unveraendert belassen.

## Logfile

Zur Fehlersuche:

- `logs/execution.log`
