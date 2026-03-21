# Technische Dokumentation

## Zweck

Der Workflow haengt einen formatierten Referenzeintrag an eine passende Obsidian-Notiz an.
Die Zielnotiz ist entweder:

- eine Meeting-Notiz, deren Frontmatter-Zeitfenster zum uebergebenen Zeitstempel passt
- oder als Fallback die Daily Note `YYYY-MM-DD.md`

## Komponenten

- `Add Reference to Note.scpt`
  Kompilierter AppleScript-Einstiegspunkt fuer Hazel / AppleScript-Laufzeit.
- `add-reference-to-note.py`
  Python-Logik fuer Zielnotiz-Aufloesung und Dateischreiben.
- `requirements.txt`
  Python-Abhaengigkeit: `python-frontmatter`

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
5. Python sucht zuerst eine passende Meeting-Notiz und faellt sonst auf die Daily Note zurueck.
6. Wenn `--entry` gesetzt ist, wird der Eintrag mit Zeilenumbruch an die Zieldatei angehaengt.

## Python-Verhalten

- Meeting-Matching basiert auf Frontmatter unter `meeting`:
  - `day`
  - `start`
  - `end`
- Zeitvergleich erfolgt auf Minutenebene.
- `--daily-only` ueberspringt die Meeting-Suche komplett und schreibt direkt in die Daily Note.
- Ausgabe auf `stdout` ist immer der finale Zielpfad.

## Konfiguration

Das AppleScript laedt `~/.workflowscripts/config.scpt` und verwendet daraus:

- `pWorkflowScriptsBaseFolder`
- `pZettelkastenDailyHome`
- `pZettelkastenMeetingsHome`

Logfile:

- `<pWorkflowScriptsBaseFolder>/logs/execution.log`

## Voraussetzungen

- zentrale virtuelle Python-Umgebung auf Repo-Ebene unter:
  - `.venv/bin/python`
- installierte Python-Abhaengigkeit:
  - `python-frontmatter`
- Schreibrechte auf Daily- und Meeting-Notizen

## Wichtige Hinweise

- Die produktive Laufzeitdatei ist `Add Reference to Note.scpt`.
- `run` im AppleScript ist nur ein manueller Testpfad mit festem Testwert fuer `datetime`.
- Im aktuellen Stand formatiert das AppleScript den kompletten Listeneintrag; Python schreibt den String unveraendert plus Newline.
