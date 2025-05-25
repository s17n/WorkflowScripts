Ein AppleScript-Skript zum Erstellen einer Meeting Note (nachfolgend Notiz) im Markdown-Format auf Basis eines Exchange-Kalendereintrags.

Das Skript wird üblicherweise mit einer Uhrzeit (im Format `HH:MM`) aufgerufen, zu der ein Kalendereintrag existieren sollte. Üblicherweise wird als Uhrzeit der Beginn des Meetings verwendet. Das Skript ermittelt standardmäßig für den aktuellen Tag und für die angegebene Uhrzeit den entsprechenden Kalendereintrag und erstellt mit den im Kalendereintrag enthaltenen Informationen (Datum/Uhrzeit, Summary, Description, Teilnehmer, Status usw.) eine Notiz zur weiteren Bearbeitung (Mitschrift, Referenzen usw.) und Auswertung.

Die Notiz wird im Inbox-Folder des Zettelkastens angelegt und der Dateiname (ohne Extension) wird als Wiki-Link (Format `[[ ]]`) in die Zwischenablage kopiert. Als Dateiname werden Datum und Uhrzeit (Beginn des Meetings) verwendet, z.B. `20250502-1300.md`. Falls die Notiz im Inbox-Folder bereits existiert wird nichts gemacht. 

**Workflow Integration**

Das Script wird üblicherweise im Rahmen der Tagesplanung aus der Daily Note heraus genutzt. Dabei werden alle Meetings des Tages - bzw. genauer gesagt die entsprechenden Uhrzeiten ("von - bis") - notiert. Anschließend wird die Uhrzeit markiert und mittels [[PopClip]] wird für die Markierung (PopClip bietet hierfür Regular Expressions, so das die Uhrzeit nicht trennscharf markiert werden muss) das Skript zum Erstellen der Meeting Note aufgerufen. Anschließend wird der Dateiname nach der Uhrzeit in die Daily Note als Link aus der Zwischenablage eingefügt.

Zur nachgelagerten Auswertung mittels [[Dataview]] werden ausgewählte Informationen des Meetings (Datum, Uhrzeit, Anzahl Teilnehmer und Teilnehmerstatus) zusätzlich als Frontmatter in die Notiz übernommen.

**Architektur**

Das Skript nutzt die AppleScript Library [[CalendarLib EC]] für den Zugriff auf den Kalender (der Zugriff über Calendar.app dauert bis zu einer Minute!) und `gdate` für Formatierungen von Datums-Attributen (weil in AppleScript zu umständlich).

