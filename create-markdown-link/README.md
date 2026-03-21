# Create Markdown Link

Ein AppleScript-Skript, das auf verschiedene macOS-Anwendungen, aktuell DEVONthink und den Finder, oder auf die Zwischenablage zugreift und anwendungsspezifische Markdown-Links für die ausgewählten Ressourcen erstellt.

Für Anwendungen muss die zu verlinkende Ressource in der jeweiligen Anwendung ausgewählt sein. Für URLs muss sich die URL in der Zwischenablage befinden. Der erzeugte Markdown-Link wird anschließend wieder in die Zwischenablage kopiert.

Der Text des Markdown-Links wird je nach Quelle wie folgt aufgebaut:

* **DEVONthink:**
  * Mails: `[Datum: Autor: Betreff](x-devonthink-item://...)`
  * Dokumente: `[Datum: Absender: Betreff](x-devonthink-item://...)`
* **Slack-Links:** `[Slack](Slack-URL)`
* **Box-Links:** `[Box://Pfad-und-Dateiname](Box-URL)`
  * Achtung: Damit der Dateiname ermittelt werden kann, muss die Datei im Box-Ordner im Finder ausgewählt sein.

Das Skript wird üblicherweise als macOS Quick Action mit Tastaturkürzel oder über *LaunchBar* mit der Abkürzung `cml` gestartet.
