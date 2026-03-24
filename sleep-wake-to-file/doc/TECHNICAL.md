# Technische Dokumentation

## Zweck

Das Modul kombiniert drei Schritte:

1. Export von Sleep/Wake-Rohdaten aus `pmset` in Tageslogs
2. Berechnung von Screentime-Metriken aus diesen Events
3. Synchronisierung der berechneten Werte in Daily-Note-Frontmatter

## Komponenten

- `sleep-wake-to-file/sleep-wake-to-file.sh`
  Exportiert die letzten 6 Tage in `sleep-wake-to-file/logs/`.
- `sleep-wake-to-file/screentime.awk`
  Auswertung der Sessions und Ausgabe in Human- oder KV-Format.
- `sleep-wake-to-file/sync-daily-note-frontmatter.py`
  Schreibt Werte in Daily-Notes unter Beruecksichtigung von unset-Regeln.
- `sleep-wake-to-file/sync-last-7-days.sh`
  Wrapper fuer den Batch-Sync der letzten 7 Tage (ohne aktuellen Tag), geeignet fuer cron.
- `sleep-wake-to-file/doc/Screentime - Report.md`
  Obsidian-Report-Snippet fuer Execute-Code.

## Datenfluss

1. `sleep-wake-to-file.sh` ruft `pmset -g log` auf und schreibt pro Datum ein Logfile.
2. `screentime.awk` verarbeitet Sleep/Wake-Zeilen:
   - Session-Start bei `Wake from Deep Idle` oder `DarkWake to FullWake from Deep Idle`
   - Session-Ende bei `Idle Sleep` bzw. Sleep-Ursachen ausser Maintenance/Sleep Service
3. `sync-daily-note-frontmatter.py` nutzt `awk -v output=kv` auf:
   - bevorzugt `sleep-wake-to-file/logs/pmset-sleep-wake_<date>.log`
   - fallback auf gefiltertes `pmset -g log`
4. Python mappt die AWK-Werte in YAML und schreibt nur fehlende/ungefuellte Felder.
5. `sync-last-7-days.sh` berechnet die Datumswerte `today-1` bis `today-7` und ruft den Python-Sync fuer jedes Datum auf.

## AWK-Ausgabe

Human-Ausgabe:

- Session-Zeilen `HH:MM:SS - HH:MM:SS: HH:MM`
- Tageszusammenfassung mit `Screentime`, `firstOn`, `lastOff`, `duration`, `durationOff`, `Plausibility`

KV-Ausgabe (`-v output=kv`):

- `firstOn`
- `lastOff`
- `duration`
- `durationOff`
- `screentime`
- `session_count`
- `plausibility`

## YAML-Mapping in Python

AWK -> Zielstruktur im Frontmatter:

- `firstOn` -> `mac.firstOn`
- `lastOff` -> `mac.lastOff`
- `duration` -> `mac.duration`
- `durationOff` -> `mac.durationOff`

Initialisierung unter `worktime` (nur falls unset):

- `worktime.start <- mac.firstOn`
- `worktime.end <- mac.lastOff`
- `worktime.break <- mac.durationOff`

Zeitnormalisierung:

- `mac.firstOn`, `mac.lastOff`, `worktime.start`, `worktime.end` werden als `YYYY-MM-DDTHH:MM` geschrieben.
- `mac.duration`, `mac.durationOff`, `worktime.break` werden als `HhMMm` geschrieben (z. B. `10h35m`).
- Die AWK-KV-Durations bleiben `HH:MM`; die Umformatierung passiert erst im Python-Sync.

## Schreibregeln

- Zieldatei: `<daily-root>/YYYY/MM/YYYY-MM-DD.md`
- Wenn Datei fehlt: wird angelegt.
- Wenn Frontmatter fehlt: wird angelegt.
- Write nur bei `missing` oder `empty` (`null`, `~`, `""`, `''` eingeschlossen).
- Wenn alle Zielkeys bereits gesetzt sind: kein Rewrite (`Write result: no changes`).

## Voraussetzungen

- macOS mit `pmset`
- `awk`
- `gdate` fuer den Collector (`sleep-wake-to-file.sh`)
- Python 3 fuer `sync-daily-note-frontmatter.py`

## Ist-Zustand und bekannte Grenzen

- Das Modul liefert eine praktikable Naeherung fuer Display-On-Zeiten auf Basis von `pmset`-Events.
- Ein hardwaregenaues "Display wirklich an" Signal fuer alle Sonderfaelle ist damit nicht garantiert.
- `sync-daily-note-frontmatter.py` beendet No-Session-Faelle bewusst mit Exit-Code `0`.
