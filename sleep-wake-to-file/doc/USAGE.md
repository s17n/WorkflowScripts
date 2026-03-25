# Nutzerdokumentation

## Zweck

Das Modul erfasst Sleep/Wake-Events ueber `pmset`, berechnet daraus taegliche Awake-Session-Zeiten und kann diese Werte in Daily-Notes schreiben.

Es gibt drei typische Nutzungsarten:

- Tageslogs erzeugen (`sleep-wake-to-file.sh`)
- Werte anzeigen (`screentime.awk` oder `doc/Screentime - Report.md`)
- Werte in YAML-Frontmatter synchronisieren (`sync-daily-note-frontmatter.py`)

## 1) Tageslogs erzeugen

Das Skript schreibt fuer die letzten 6 Tage (ohne aktuellen Tag) je eine Datei nach:

- `sleep-wake-to-file/logs/pmset-sleep-wake_YYYY-MM-DD.log`

Aufruf:

```bash
./sleep-wake-to-file/sleep-wake-to-file.sh
```

Hinweis:

- Existierende Tageslogs werden nicht ueberschrieben.
- Fuer eine lueckenlose Historie sollte das Skript mindestens einmal innerhalb von 6 Tagen laufen (typisch per cron).

## 2) Awake-Session-Werte ausgeben

Direkt aus Live-Daten:

```bash
date="2026-03-21"
pmset -g log | grep -e "$date" | grep -e " Sleep  " -e " Wake  " | awk -f ./sleep-wake-to-file/screentime.awk
```

Aus einem Archivlog:

```bash
date="2026-03-21"
awk -f ./sleep-wake-to-file/screentime.awk "./sleep-wake-to-file/logs/pmset-sleep-wake_$date.log"
```

Maschinenlesbare Ausgabe:

```bash
date="2026-03-21"
pmset -g log | grep -e "$date" | grep -e " Sleep  " -e " Wake  " | awk -v output=kv -f ./sleep-wake-to-file/screentime.awk
```

KV-Keys:

- `firstOn`
- `lastOff`
- `duration`
- `durationOff`
- `awakeSessionTime`
- `session_count`
- `plausibility`

## 3) Werte in Daily Notes schreiben

Das Sync-Skript erwartet:

- `--daily-root` als Basisordner der Daily Notes
- `--date` im Format `YYYY-MM-DD`

Dateischema:

- `<daily-root>/YYYY/MM/YYYY-MM-DD.md`

Dry-Run (kein Dateischreiben):

```bash
./sleep-wake-to-file/sync-daily-note-frontmatter.py \
  --daily-root "/Pfad/zu/DailyNotes" \
  --date "2026-03-21" \
  --dry-run
```

Write-Modus:

```bash
./sleep-wake-to-file/sync-daily-note-frontmatter.py \
  --daily-root "/Pfad/zu/DailyNotes" \
  --date "2026-03-21"
```

## YAML-Zielattribute

Unter `mac` (nur falls unset):

- `firstOn` (ISO-8601 ohne Sekunden: `YYYY-MM-DDTHH:MM`)
- `lastOff` (ISO-8601 ohne Sekunden: `YYYY-MM-DDTHH:MM`)
- `duration` (Format `HhMMm`, z. B. `10h35m`)
- `durationOff` (Format `HhMMm`, z. B. `1h20m`)

Unter `worktime` (nur falls unset):

- `start <- mac.firstOn` (ISO-8601 ohne Sekunden: `YYYY-MM-DDTHH:MM`)
- `end <- mac.lastOff` (ISO-8601 ohne Sekunden: `YYYY-MM-DDTHH:MM`)
- `break <- mac.durationOff` (Format `HhMMm`)

Unset bedeutet:

- Key fehlt
- leerer Wert
- `null`, `~`, `""`, `''`

Bereits gesetzte Werte werden nicht ueberschrieben.

## No-Session-Verhalten

Wenn fuer den Tag keine Sessions ermittelt werden:

- keine Datei-/YAML-Aenderung
- Rueckgabecode `0`
- Konsolenmeldung: `No sessions found for <date>. Nothing to write.`

## 4) Batch-Sync fuer cron (letzte 7 Tage)

Das Wrapper-Skript ruft den Daily-Sync fuer die letzten 7 Tage auf (ohne den aktuellen Tag):

```bash
./sleep-wake-to-file/sync-last-7-days.sh \
  --daily-root "/Pfad/zu/DailyNotes"
```

Beispiel fuer `crontab` (taeglich um 01:30 Uhr):

```cron
30 1 * * * /Users/steffen/Projects/WorkflowScripts/sleep-wake-to-file/sync-last-7-days.sh --daily-root "/Pfad/zu/DailyNotes" >> /tmp/sleep-wake-sync.log 2>&1
```
