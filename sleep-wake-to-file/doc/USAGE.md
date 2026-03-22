# Nutzerdokumentation

## Zweck

Das Modul erfasst Sleep/Wake-Events ueber `pmset`, berechnet daraus taegliche Bildschirmzeiten und kann diese Werte in Daily-Notes schreiben.

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

## 2) Screentime-Werte ausgeben

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

- `first_screen_on`
- `last_screen_off`
- `duration`
- `duration_off_screentime`
- `screentime`
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

Primaere Attribute:

- `firstScreenOn`
- `lastScreenOff`
- `duration`
- `durationOffScreen`

Legacy-Attribute (nur falls unset):

- `Start`
- `End`
- `breaktime`
- `worktime`

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
