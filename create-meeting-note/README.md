# Create Meeting Note

Ein AppleScript-Skript zum Erstellen einer Meeting Note (nachfolgend Notiz) im Markdown-Format auf Basis eines Exchange-Kalendereintrags.

Das Skript wird üblicherweise mit einer Uhrzeit (im Format `HH:MM`) aufgerufen, zu der ein Kalendereintrag existieren sollte. Üblicherweise wird als Uhrzeit der Beginn des Meetings verwendet. Das Skript ermittelt standardmäßig für den aktuellen Tag und für die angegebene Uhrzeit den entsprechenden Kalendereintrag und erstellt mit den im Kalendereintrag enthaltenen Informationen (Datum/Uhrzeit, Summary, Description, Teilnehmer, Status usw.) eine Notiz zur weiteren Bearbeitung (Mitschrift, Referenzen usw.) und Auswertung.

Optional können:

* Standardaufgaben in Obsidians `Task`-Syntax mit in die Notiz aufgenommen werden
* Call-In-Informations-Blöcke aus der Description entfernt werden (Exchange generiert diese z.B. automatisch in jede Meeting Description)

Die Notiz wird im Inbox-Folder des Zettelkastens angelegt und der Dateiname (ohne Extension) wird als Wiki-Link (im Format `[[ ]]`) in die Zwischenablage kopiert. Als Dateiname werden Datum und Uhrzeit (Beginn des Meetings) verwendet, z.B. `20250502-1300.md`. Falls die Notiz im Inbox-Folder bereits existiert wird standardmäßig nichts gemacht.

**Workflow Integration**

Das Script wird üblicherweise im Rahmen der Tagesplanung aus der Daily Note heraus genutzt. Dabei werden alle Meetings des Tages - bzw. genauer gesagt die entsprechenden Uhrzeiten ("von - bis") - notiert. Anschließend wird die Uhrzeit markiert und mittels *PopClip* wird für die Markierung das Skript zum Erstellen der Meeting Note aufgerufen (PopClip bietet hierfür Regular Expressions, so das die Uhrzeit nicht trennscharf markiert werden muss). Anschließend wird der Dateiname - als Wiki-Link aus der Zwischenablage - nach der Uhrzeit in die Daily Note eingefügt.

Zur nachgelagerten statistischen Auswertung mittels *Dataview* werden ausgewählte Informationen des Meetings (Datum, Uhrzeit, Anzahl Teilnehmer und Teilnehmerstatus) zusätzlich als Frontmatter in die Notiz übernommen.

In der nachgelagerten Bearbeitung der Notiz (nicht mehr aktiv von diesem Skript unterstützt) wird die Notiz noch umbenannt und nach Abschluss der Bearbeitung wird die Notiz mittels [Hazel Rule](../../../Zettelkasten/Hazel%20-%20Zettelkasten%20-%20Inbox.md) in einen dedizierten Meetings-Ordner verschoben. Der Dateiname wird ergänzt - Datum und Uhrzeit bleiben als Prefix erhalten, so dass alle Meeting Notes im Meetings-Ordner eindeutig sind.

**Architektur**

Das Skript nutzt die AppleScript Library *CalendarLib EC* für den Zugriff auf den Kalender (der Zugriff über Calendar.app dauert bis zu einer Minute) und GNU date (`gdate`) für Berechnungen und Formatierungen von Datums-Attributen (weil in AppleScript zu umständlich). Für die restlichen Dinge werden macOS-Standardtools genutzt.
