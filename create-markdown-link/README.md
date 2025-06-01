# Create Markdown Link

Ein AppleScript-Skript, das auf verschiedene macOS-Anwendungen - aktuell auf DEVONthink und den Finder - oder die Zwischenablage zugreift und anwendungsspezifisch Markdown Links auf die ausgewählten Ressourcen erstellt und in die Zwischenablage kopiert.

Für Anwendungen muss die verlinkte Ressource in der Anwendung selektiert sein - für URL muss sich die URL in der Zwischenablage befinden. Der erstellte Markdown Link wird ebenfalls wieder in die Zwischenablage kopiert.

Der Text des Markdown-Links wird anwendungsspezifisch wie folgt erstellt:

* **DEVONthink:**
  * Mails: `[Datum: Autor: Betreff](x-devonthink-item://...)`
  * Dokumente: `[Datum: Absender: Betreff]((x-devonthink-item://...)`)\`
* **Slack Links:** `[Slack](Slack Url)`
* **Box Links:** `[Box://Pfad-und-Dateiname](Box Url)`
  * Achtung: Damit der Dateiname ermittelt werden kann, muss die Datei im Box-Folder im Finder selektiert sein.

Das Skript wird üblicherweise als macOS Quick Action mit Keyboard Shortcut oder mittels *LaunchBar* und Custom Abbreviation `cml` (**c**reate **m**arkdown-**l**ink) gestartet.
