# Technische Dokumentation

## Zweck

Der Workflow erstellt aus einem Exchange-Kalendereintrag eine Markdown-Meeting-Notiz im Inbox-Ordner des Zettelkastens.

Die Notiz enthaelt:

- Frontmatter unter `meeting`
- vorbereitete Aufgaben
- Termin- und Teilnehmerinformationen
- die Terminbeschreibung

## Komponenten

- `create-meeting-note/Create Meeting Note from Calendar Entry.scpt`
  Kompilierter AppleScript-Einstiegspunkt fuer manuelle Nutzung.
- `create-meeting-note/README.md`
  Modulueberblick.
- `create-meeting-note/doc/USAGE.md`
  Nutzerdokumentation.
- `create-meeting-note/doc/TECHNICAL.md`
  Technische Dokumentation.
- `create-meeting-note/doc/CALL-CHAIN.md`
  Sequenzdiagramm der Standard-Call-Chain.

## Datenfluss

1. Das Skript laedt Konfiguration aus `~/.workflowscripts/config.scpt`.
2. `run` startet einen Dialog mit Datum/Uhrzeit und den Buttons `List Meetings`, `Cancel` und `Create`.
3. `List Meetings` ruft `fetchEventsByDay(...)` auf, zeigt eine Auswahlliste und erzeugt ueber `createNoteFromEvent(...)` eine Notiz fuer den gewaehlten Termin.
4. `Create` soll ueber `createNoteFromDateTime(...)` direkt den zum Zeitpunkt passenden Termin aufloesen.
5. `fetchEventsByDay(...)` liest ueber `CalendarLib EC` Termine fuer den Tagesbereich `00:00` bis `23:59`.
6. `resolveCalendars(...)` sammelt bevorzugt Exchange-, iCloud- und lokale Kalender und durchsucht diese gemeinsam.
7. `getEventByTime(...)` waehlt den Termin, dessen Startzeit `<=` Zielzeit und dessen Endzeit `>` Zielzeit ist.
8. `createNoteFromEvent(...)` sammelt Event-Info und Attendees, erzeugt den Dateinamen `YYYYMMDD-HHMM.md`, schreibt den Markdown-Inhalt und setzt die Zwischenablage.
9. Optional entfernt `removeCallInBlock(...)` einen Block aus der geschriebenen Datei per `grep`, `awk` und `sed`.
10. Wenn Start- oder Endmarker fuer den Call-In-Block fehlen, wird der Entfernungsschritt geloggt und uebersprungen.

## Sequenzdiagramm

Die Standard-Call-Chain ist separat dokumentiert:

- [Call Chain](./CALL-CHAIN.md)

## Erzeugter Inhalt

Die Notiz wird von `createContentForMeetingNote(...)` aufgebaut und besteht aus:

- YAML-Frontmatter mit:
  - `meeting.day`
  - `meeting.start`
  - `meeting.end`
  - `meeting.attendees_total`
  - `meeting.attendees_accepted`
  - `meeting.attendees_declined`
  - `meeting.attendees_tentative`
  - `meeting.attendees_other`
- Ueberschrift aus `pMeetingNoteHeading`
- Abschnitt `# Todos`
- Abschnitt `# Termin`
- Abschnitt `### Description`
- Abschnitt `# Mitschrift`
- Abschnitt `# Referenzen`

## Teilnehmerlogik

- `createAttendeesList(...)` trennt Attendees nach Rolle in `chair`, `required` und `optional`.
- `createAttendeesSection(...)` gruppiert danach zusaetzlich nach Status:
  - `accepted`
  - `declined`
  - `tentative`
  - Rest in `other`
- `getChair(...)` nimmt den ersten bzw. letzten gefundenen Attendee mit Rolle `chair` oder `unknown`.
- Die Gesamtzahl im Frontmatter wird aus den gezaehlten Attendees plus `1` fuer den Chair gebildet.

## Konfiguration

Das Skript erwartet diese Properties in `~/.workflowscripts/config.scpt`:

- `pZettelkastenInboxFolder`
- `pWorkflowScriptsBaseFolder`
- `pMeetingNoteHeading`
- `pLastname`
- `pOverwriteExistingNote`
- `pRemoveCallInBlock`
- `pCallInBlockStartIdentifier`
- `pCallInBlockEndIdentifier`

Logfile:

- `<pWorkflowScriptsBaseFolder>/create-meeting-note/logs/execution.log`

## Voraussetzungen

- macOS
- AppleScript Library `CalendarLib EC` in Version `1.1.5`
- GNU `date` unter `/opt/homebrew/bin/gdate`
- Shell-Tools `grep`, `awk`, `sed`, `date`
- Kalenderfreigabe fuer die aufrufende Anwendung

## Ist-Zustand und bekannte Probleme

- Die produktive Laufzeitdatei ist ausschliesslich `Create Meeting Note from Calendar Entry.scpt`.
- Es liegt keine menschenlesbare `*.applescript`-Quelldatei im Modul vor.
- `createNoteFromDateTime(...)` ruft aktuell `createMeetingNoteFromEvent(...)` auf; dieser Handler existiert nicht. Der `Create`-Pfad ist damit kaputt.
- Das Modul hat im aktuellen Stand keinen Hazel-Einstiegspunkt.
- `pOverwriteExistingNote` ist im Skript hart auf `true` gesetzt und ignoriert damit den Konfigurationswert.
- Der Kalenderzugriff durchsucht bevorzugt Exchange-, iCloud- und lokale Kalender gemeinsam und faellt sonst auf alle verfuegbaren Kalender zurueck.
- `removeCallInBlock(...)` prueft jetzt auf fehlende Start- und Endmarker und bricht in diesem Fall kontrolliert ohne Dateiaenderung ab.
- `createContentForMeetingNote(...)` schreibt den kompletten generierten Note-Inhalt ins Logfile. Das ist fuer Debugging nuetzlich, aber inhaltlich sehr ausfuehrlich.
