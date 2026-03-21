# Technische Dokumentation

## Zweck

Der Workflow hängt einen formatierten Referenzeintrag an eine passende Obsidian-Notiz an.
Die Zielnotiz ist entweder:

- eine Meeting-Notiz, deren Frontmatter-Zeitfenster zum übergebenen Zeitstempel passt
- oder als Fallback die Daily Note `YYYY-MM-DD.md`

## Komponenten

- `add-reference-to-note/Add Reference to Note.scpt`
  Kompilierter AppleScript-Einstiegspunkt für Hazel / AppleScript-Laufzeit.
- `add-reference-to-note/add-reference-to-note.py`
  Python-Logik für Zielnotiz-Auflösung und Dateischreiben.
- `add-reference-to-note/requirements.txt`
  Python-Abhängigkeit: `python-frontmatter`

## Datenfluss

1. `hazelProcessFile(theFile, inputAttributes)` nimmt Eingaben aus Hazel entgegen.
2. Erwartete `inputAttributes`:
   - `item 1`: Typ, z. B. `Screenshot`
   - `item 2`: Markdown-Link
   - `item 3`: Zeitstempel im Format `YYYYMMDD-HHmmss`
   - `item 4`: Inline-Flag; `"1"` bedeutet Inline-Markierung
3. AppleScript baut daraus einen Eintrag im Format:
   - normal: `- <Typ>:: <Markdown-Link>`
   - inline: `- <Typ>:: !<Markdown-Link>`
4. AppleScript ruft `add-reference-to-note.py` mit:
   - `--meeting-root`
   - `--daily-root`
   - `--timestamp`
   - `--entry`
5. Python sucht zuerst eine passende Meeting-Notiz und fällt sonst auf die Daily Note zurück.
6. Wenn `--entry` gesetzt ist, wird der Eintrag mit Zeilenumbruch an die Zieldatei angehängt.

## Python-Verhalten

- Meeting-Matching basiert auf Frontmatter unter `meeting`:
  - `day`
  - `start`
  - `end`
- Zeitvergleich erfolgt auf Minutenebene.
- `--daily-only` überspringt die Meeting-Suche komplett und schreibt direkt in die Daily Note.
- Ausgabe auf `stdout` ist immer der finale Zielpfad.

## Konfiguration

Das AppleScript lädt `~/.workflowscripts/config.scpt` und verwendet daraus:

- `pWorkflowScriptsBaseFolder`
- `pZettelkastenDailyHome`
- `pZettelkastenMeetingsHome`

Logfile:

- `<pWorkflowScriptsBaseFolder>/logs/execution.log`

## Voraussetzungen

- zentrale virtuelle Python-Umgebung auf Repo-Ebene unter:
  - `.venv/bin/python`
- installierte Python-Abhängigkeit:
  - `python-frontmatter`
- Schreibrechte auf Daily- und Meeting-Notizen

## Wichtige Hinweise

- Die produktive Laufzeitdatei ist `Add Reference to Note.scpt`.
- `run` im AppleScript ist nur ein manueller Testpfad mit festem Testwert für `datetime`.
- Im aktuellen Stand formatiert das AppleScript den kompletten Listeneintrag; Python schreibt den String unverändert plus Newline.
