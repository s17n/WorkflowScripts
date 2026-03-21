# Nutzerdokumentation

## Zweck

Der Workflow erstellt aus einem Exchange-Kalendereintrag eine Meeting-Notiz im Markdown-Format.

Die Notiz wird im Inbox-Ordner des Zettelkastens angelegt und enthaelt:

- Frontmatter mit Meeting-Metadaten fuer spaetere Auswertung
- einen Todo-Bereich
- Termin-Details
- Teilnehmerinformationen, soweit vom Kalender lieferbar
- die Beschreibung des Kalendereintrags
- leere Bereiche fuer Mitschrift und Referenzen

## Was passiert

- Das Skript ermittelt fuer eine uebergebene Uhrzeit den passenden Termin des Tages.
- Alternativ kann ein komplettes Datum mit Uhrzeit uebergeben werden.
- Aus dem Termin wird ein Dateiname im Format `YYYYMMDD-HHMM.md` gebildet.
- Die Notiz wird im konfigurierten Inbox-Ordner erstellt.
- Ein Wiki-Link zur erzeugten Notiz wird in die Zwischenablage gelegt.

## Typischer Einsatz

Der uebliche Aufruf erfolgt aus der Daily Note heraus, zum Beispiel ueber PopClip mit einer markierten Uhrzeit.

Im manuellen Start zeigt das Skript einen Dialog mit diesen Aktionen:

- `List Meetings`: listet die Termine eines Tages zur Auswahl auf, inklusive Kalendername
- `Create`: versucht direkt fuer den eingegebenen Zeitpunkt eine Notiz zu erzeugen
- `Cancel`: bricht ab

## Eingaben

Unterstuetzt werden:

- `HH:MM`
- `YYYY-MM-DD HH:MM`

Bei reiner Uhrzeit wird automatisch das aktuelle Datum verwendet.

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

- Der Dialogpfad `Create` ist im aktuellen Stand defekt und erzeugt keine Notiz.
- Wenn eine Notiz bereits existiert, wird sie im aktuellen Stand ueberschrieben.
- Das Modul hat im aktuellen Stand keinen Hazel-Einstiegspunkt mehr.
- Wenn beim Entfernen des Call-In-Blocks Start- oder Endmarker fehlen, wird der Schritt uebersprungen und die Notiz unveraendert belassen.

## Logfile

Zur Fehlersuche:

- `logs/execution.log`
