# Add Reference to Note

Ein Workflow zum Anhängen eines formatierten Referenzeintrags an eine passende Obsidian-Notiz.

Der Workflow wird typischerweise aus Hazel oder AppleScript mit einem Typ, einem Markdown-Link und einem Zeitstempel im Format `YYYYMMDD-HHmmss` aufgerufen. Wenn zum Zeitstempel eine passende Meeting-Notiz existiert, wird der Eintrag dort angehängt. Andernfalls wird in die Daily Note des betreffenden Datums geschrieben.

Der Eintrag wird im AppleScript vorbereitet und anschließend von `add-reference-to-note.py` in die Zieldatei geschrieben. Das Format ist dabei typischerweise:

* normal: `- Typ:: [Titel](https://beispiel.de)`
* inline: `- Typ:: ![Titel](https://beispiel.de)`

Die produktive Laufzeitdatei für AppleScript-Automationen ist `Add Reference to Note.scpt`.

Weiterführende Dokumentation:

* [Nutzerdokumentation](./doc/USAGE.md)
* [Technische Dokumentation](./doc/TECHNICAL.md)
