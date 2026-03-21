# Add Reference to Daily Note

Technische Dokumentation des Moduls `add-reference-to-daily-note`.

## Zweck

Das Modul schreibt Referenzen in eine Obsidian-Daily-Note. Die Referenz kann
aus einem AppleScript/Hazel-Workflow kommen oder direkt per Shell-Aufruf
übergeben werden.

Der aktuelle Implementierungsstand unterstützt vor allem diese Fälle:

- Markdown-Links aus Browsern, typischerweise als `Bookmark:: ...`
- Inhalte aus der Zwischenablage
- DEVONthink-Links oder andere Einträge ohne expliziten Dataview-Key

## Komponenten

### 1. Shell-Skript

Datei: `add-reference-to-daily-note.sh`

Verantwortung:

- lädt lokale Konfiguration aus `~/.zettelkasten/config`
- bestimmt die Zieldatei der Daily Note
- liest den Eintrag optional aus der Zwischenablage
- ergänzt einen Dataview-Key oder verwendet den Eintrag direkt
- hängt die erzeugte Zeile an die Daily Note an
- schreibt Laufzeit-Logs in `logs/execution.log`

### 2. Meeting-Suche

Datei: `find-meeting-note.py`

Verantwortung:

- durchsucht rekursiv einen explizit übergebenen Meeting-Ordner nach `.md`-Dateien
- liest YAML-Frontmatter mit `python-frontmatter`
- wertet `meeting.day`, `meeting.start` und `meeting.end` aus
- gibt die erste lexikographisch sortierte passende Meeting-Note zurück
- fällt sonst auf eine Daily-Note `YYYY-MM-DD.md` in einem separaten Daily-Ordner zurück
- kann optional direkt einen Listeneintrag in die aufgelöste Zieldatei schreiben

### 3. AppleScript

Datei: `Add Reference to Daily Note.scpt`

Verantwortung:

- dient als Einstiegspunkt für macOS-Automationen
- unterstützt drei Modi:
  - `run {}` für einen direkten Testlauf
  - `hazelProcessFile(theFile, inputAttributes)` für Hazel-Workflows
  - `addClipboardToDailyNote()` für Inhalte aus der Zwischenablage
- leitet Inhaltstyp und Eintrag an das Shell-Skript weiter

## Laufzeitvoraussetzungen

- macOS
- Bash
- `pbpaste`
- Python 3
- `python-frontmatter`
- `~/.zettelkasten/config`

Erwartete Konfiguration:

- `ZETTELKASTEN_VAULT_DIR`

Das Shell-Skript verwendet daraus:

- `"$ZETTELKASTEN_VAULT_DIR/Journal"` als Basisordner der Daily Notes

## Dateistruktur

```text
add-reference-to-daily-note/
├── Add Reference to Daily Note.scpt
├── add-reference-to-daily-note.sh
├── find-meeting-note.py
├── find-meeting-note.sh
├── logs/
│   └── execution.log
└── README.md
```

## Datenfluss

### AppleScript-Pfad

1. Ein Workflow ruft `hazelProcessFile(...)` oder `addClipboardToDailyNote()`
   auf.
2. Das AppleScript bestimmt einen `workflowContentType`.
3. Das AppleScript ruft das Shell-Skript mit `-d=<type>` und `-e=<entry>` auf.
4. Das Shell-Skript erzeugt daraus eine Markdown-Zeile.
5. Die Zeile wird an die Daily Note des aktuellen Tages angehängt.

### Direkter Shell-Pfad

1. Das Skript liest CLI-Parameter.
2. Falls `entry` fehlt, wird `pbpaste` verwendet.
3. Falls `dataviewKey` fehlt, wird je nach Eintragsformat ein Default gesetzt.
4. Das Skript schreibt `- <key>:: <entry>` oder direkt den aufbereiteten
   Eintrag an das Dateiende.

### Meeting-Suche

1. Das Skript liest `--root`, `--timestamp` und optional `--entry`.
2. Es durchsucht unter `--meeting-root` rekursiv alle Markdown-Dateien.
3. Es berücksichtigt nur Dateien mit Frontmatter und vollständigem `meeting`-Block.
4. Es vergleicht den Zeitstempel mit `meeting.day`, `meeting.start` und `meeting.end`.
5. Es verwendet die erste passende Meeting-Note oder als Fallback `DAILY_ROOT/YYYY-MM-DD.md`.
6. Optional hängt es `- <entry>` an die aufgelöste Zieldatei an.

## Technische Details der Meeting-Suche

### Eingabemodell

- `--timestamp` erwartet weiterhin `YYYYMMDD-HHmmss`
- Sekunden werden beim Vergleich bewusst verworfen
- `--meeting-root` und `--daily-root` können getrennt gesetzt werden
- `--root` bleibt als Kompatibilitätsoption erhalten und setzt beide Root-Pfade zugleich

### Frontmatter-Modell

Erwartet wird ein YAML-Block am Dateianfang mit diesem Schema:

```yaml
---
meeting:
  day: 2026-03-20
  start: 13:30
  end: 14:15
...
---
```

Wichtige technische Randbedingung:

- `python-frontmatter` nutzt intern `PyYAML`
- unquotierte Werte wie `day: 2026-03-20` und `start: 13:30` werden dabei nicht als Strings, sondern als `date` und Ganzzahl eingelesen
- der Code normalisiert diese Typen intern wieder zu `YYYY-MM-DD` und `HH:MM`

### Auflösungslogik

- alle `.md`-Dateien unter `--meeting-root` werden lexikographisch sortiert
- die erste Datei, deren Zeitfenster den Timestamp inklusive Start- und Endminute enthält, wird als Ziel gewählt
- wenn keine Datei passt, wird als Ziel `--daily-root/YYYY-MM-DD.md` verwendet
- der Fallback wird logisch über `None` unterschieden, nicht über Dateinamen; dadurch funktionieren auch Meeting-Dateien mit Namen wie `2026-03-20.md`

### Schreiblogik

- ohne `--entry` gibt das Skript nur den aufgelösten absoluten Pfad aus
- mit `--entry` wird die Zieldatei bei Bedarf angelegt und `- <entry>` angehängt
- das Daily-Verzeichnis wird bei Bedarf automatisch erzeugt

## CLI-Schnittstelle der Meeting-Suche

Unterstützte Parameter:

- `--meeting-root=DIR` setzt das Suchverzeichnis für Meeting-Notizen
- `--daily-root=DIR` setzt das Verzeichnis für Daily-Notes
- `--root=DIR` verwendet denselben Ordner für Meeting-Suche und Daily-Fallback
- `--timestamp=YYYYMMDD-HHmmss` setzt den abzugleichenden Zeitpunkt
- `--entry=TEXT` hängt optional einen Listeneintrag an die aufgelöste Zieldatei an

Verhalten:

- es werden nur `.md`-Dateien berücksichtigt
- der Zeitstempel muss am selben Tag liegen und innerhalb des Intervalls `start` bis `end`
- Sekunden im Eingabeformat werden ignoriert; der Abgleich erfolgt auf Minutenbasis
- bei mehreren Treffern wird der erste Pfad nach lexikographischer Sortierung ausgegeben
- wenn keine Meeting-Note passt, verwendet das Skript als Fallback `DAILY_ROOT/YYYY-MM-DD.md`
- mit `--entry` wird `- <entry>` an die gefundene Meeting-Note oder an die Fallback-Datei angehängt
- bei ungültiger Eingabe beendet sich das Skript mit Exitcode `1`

Beispiel:

```text
./find-meeting-note.py --meeting-root=/path/to/meetings --daily-root=/path/to/daily --timestamp=20260320-133500
```

Hazel-Beispiel mit Schreib-Fallback:

```text
./find-meeting-note.py --meeting-root=/path/to/meetings --daily-root=/path/to/daily --timestamp=20260320-133500 --entry="Mein Eintrag"
```

Hazel mit explizitem venv-Python:

```text
/absolute/path/to/.venv/bin/python /absolute/path/to/find-meeting-note.py --meeting-root=/path/to/meetings --daily-root=/path/to/daily --timestamp=20260320-133500 --entry="Mein Eintrag"
```

Installation:

```text
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

## CLI-Schnittstelle des Shell-Skripts

Unterstützte Parameter im aktuellen Ist-Zustand:

- `-d=` oder `--dataview-key=` setzt `dataviewKey`
- `--date=` setzt `datum`
- `-k=` oder `--key=` setzt `key`
- `-e=` oder `--entry=` setzt `entry`

Hinweise zum tatsächlichen Verhalten:

- Die Kurzoption `-d` ist im Code doppelt belegt. Praktisch wird sie für
  `dataviewKey` verwendet.
- `datum` wird zwar geparst, aber aktuell nicht für die Zielpfad-Bestimmung
  benutzt.
- `key` wird geparst, aber im weiteren Ablauf nicht verwendet.

## Schreiblogik

Die Daily Note wird aktuell immer auf Basis des heutigen Datums bestimmt:

```text
$ZETTELKASTEN_VAULT_DIR/Journal/YYYY-MM-DD.md
```

Danach baut das Skript die Ausgabezeile wie folgt:

- Falls `entry` leer ist: Inhalt aus `pbpaste`
- Falls `dataviewKey` leer ist und der Eintrag mit `[` beginnt:
  `Bookmark:: <entry>`
- Falls `dataviewKey` leer ist und der Eintrag nicht mit `[` beginnt:
  der Eintrag wird über eine `sed`-Regel transformiert
- Falls `dataviewKey` gesetzt ist:
  `<dataviewKey>:: <entry>`

Die finale Zeile wird als Listeneintrag geschrieben:

```text
- <lineEntry>
```

## AppleScript-Verhalten

### `run {}`

`run {}` ist aktuell als Testmodus implementiert:

- `workflowContentType = "Screenshot"`
- `entry = "[Google](https://www.google.com)"`

Der Handler ist damit eher ein eingebauter Smoke-Test als ein produktiver
Einstiegspunkt.

### `hazelProcessFile(theFile, inputAttributes)`

Erwartet:

- `item 1 of inputAttributes` als Inhaltstyp
- `item 2 of inputAttributes` als Eintrag

Der Dateiparameter `theFile` wird nur geloggt, aber nicht weiterverarbeitet.

### `addClipboardToDailyNote()`

Leitet den Typ anhand der aktiven App ab:

- `Arc` oder `Safari` -> `Bookmark`
- `DEVONthink` -> leerer Typ
- sonst -> `Other`

Danach wird der Clipboard-Text an das Shell-Skript übergeben.

## Logging

Beide Komponenten schreiben in dieselbe Logdatei:

- `logs/execution.log`

Typische Logeinträge enthalten:

- Start und Ende eines Laufs
- gewählten Dataview-Key
- aufgelöste Daily-Note-Datei
- finalen Eintrag

## Bekannte technische Schwächen

### 1. Inkonsistente CLI

- `-d` ist doppelt belegt
- `datum` und `key` sind aktuell tote Parameter

### 2. Kein Update bestehender Einträge

Das aktuelle produktive Shell-Skript hängt Einträge nur an. Die im
Repository-README beschriebene Fähigkeit zum Aktualisieren bestehender
Markdown-Referenzen ist in dieser Version nicht implementiert.

### 3. Fragile Eintragsnormalisierung

Die `sed`-Regel für Einträge ohne Dataview-Key ist schwer nachvollziehbar und
deckt typische URL-Schemata mit Bindestrichen nicht sauber ab.

### 4. Unsichere Shell-Aufrufe im AppleScript

Das AppleScript baut Shell-Befehle per String-Konkatenation zusammen.
Einträge oder Log-Nachrichten mit doppelten Anführungszeichen können den
Aufruf beschädigen. Shell-Escaping erfolgt nicht robust.

### 5. Fehlende Validierung

Es gibt keine harte Prüfung auf:

- vorhandene Konfigurationsdatei
- vorhandenen Journal-Ordner
- schreibbare Zieldatei
- leere oder ungültige Eingaben

## Soll-Architektur für eine Bereinigung

Für eine technische Konsolidierung bietet sich diese Struktur an:

1. Eine einzige Shell-Implementierung als Source of Truth
2. Saubere CLI mit:
   - `--date`
   - `--entry`
   - `--dataview-key`
3. Robuste Unterscheidung zwischen:
   - DEVONthink-Link
   - normalem Markdown-Link
   - Plain-Text-Eintrag
4. Optionales Update vorhandener Einträge statt blindem Anhängen
5. AppleScript nur als dünner Wrapper mit sauberem Shell-Quoting
6. Explizite Fehlerbehandlung und Rückgabecodes

## Beispiele

### Browser-Link als Bookmark

```bash
./add-reference-to-daily-note.sh \
  --dataview-key=Bookmark \
  --entry='[OpenAI](https://openai.com)'
```

Erwartetes Ergebnis in der Daily Note:

```text
- Bookmark:: [OpenAI](https://openai.com)
```

### Eintrag aus Zwischenablage

```bash
./add-reference-to-daily-note.sh
```

Das Skript liest dann den Inhalt per `pbpaste`.

## Status

Die aktuelle Implementierung ist funktional klein und gut anschlussfähig für
Automationen, aber technisch noch nicht konsolidiert. Die Dokumentation
beschreibt daher bewusst den Ist-Zustand einschließlich der bekannten
Abweichungen und Risiken.
