# Sleep Wake to File

Ein Modul zum Erfassen und Auswerten von Sleep/Wake-Events aus `pmset` sowie zum Synchronisieren der Tageswerte in Obsidian-Daily-Notes.

Das Modul besteht aus:

- `sleep-wake-to-file/sleep-wake-to-file.sh`
  Exportiert Sleep/Wake-Events der letzten 6 Tage in Tages-Logs unter `sleep-wake-to-file/logs/`.
- `sleep-wake-to-file/screentime.awk`
  Berechnet aus den Events die Session-Zeiten und Tagesmetriken.
- `sleep-wake-to-file/sync-daily-note-frontmatter.py`
  Schreibt die berechneten Werte in YAML-Frontmatter einer Daily Note.
- `sleep-wake-to-file/sync-last-7-days.sh`
  Batch-Sync fuer die letzten 7 Tage (ohne aktuellen Tag), geeignet fuer cron.
- `sleep-wake-to-file/doc/Screentime - Report.md`
  Beispiel fuer die Auswertung direkt in Obsidian per Execute-Code-Plugin.

Weiterfuehrende Dokumentation:

- [Nutzerdokumentation](./doc/USAGE.md)
- [Technische Dokumentation](./doc/TECHNICAL.md)
