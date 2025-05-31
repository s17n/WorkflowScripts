# Convert Link to Markdown Link

Ein AppleScript-Skript, das auf die Zwischenablage zugreift und anwendungsspezifische URLs (Links) in Markdown-Links umwandelt. Die URL muss sich dafür in der Zwischenablage befinden - der Markdown Link wird ebenfalls wieder in die Zwischenablage kopiert.

Der Text des Markdown-Links wird anwendungsspezifisch wie folgt erstellt:

* **Slack Links:** `[Slack](Slack Url)`
* **Box Links:** `[Box://Pfad-und-Dateiname](Box Url)`
  * Achtung: Damit der Dateiname ermittelt werden kann, muss die Datei im Box-Folder im Finder selektiert sein.

Das Skript wird üblicherweise mittels *LaunchBar* und Custom Abbreviation `mdl` (markdown-link) gestartet.
