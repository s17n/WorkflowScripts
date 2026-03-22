# Create Meeting Note

Ein Workflow zum Erstellen einer Markdown-Meeting-Notiz aus einem Kalendereintrag.

Das Skript wird typischerweise fuer ein Datum im Format `YYYY-MM-DD` aufgerufen. Es listet die Termine dieses Tages auf, laesst einen Termin auswaehlen, erzeugt daraus eine Meeting-Notiz im Inbox-Ordner des Zettelkastens und legt Metadaten fuer die weitere Bearbeitung und spaetere Auswertung ab.

Das Layout der erzeugten Meeting-Notiz kommt aus dem externen Template `templates/meeting-note.md` und kann dort ohne AppleScript-Aenderung angepasst werden.
Microsoft-Teams- bzw. Call-In-Bloecke in der Terminbeschreibung werden vor dem Rendern ueber konfigurierbare Marker aus `config.scpt` abgeschnitten.

Die produktive Laufzeitdatei ist `Create Meeting Note.scpt`.

Weiterfuehrende Dokumentation:

* [Nutzerdokumentation](./doc/USAGE.md)
* [Technische Dokumentation](./doc/TECHNICAL.md)
