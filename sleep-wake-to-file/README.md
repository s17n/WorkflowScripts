Ein Skript zum Auslesen der `Sleep/Wake Events` aus dem MacOS [Power Management Settings mit pmset](../../../Zettelkasten/Power%20Management%20Settings%20mit%20pmset.md).

Das Skript ließt die Events der letzten 6 Tage aus - exklusive des aktuellen Tages - und schreibt sie pro Tag in eine Datei in`./logs`. Falls die Datei schon existiert wird der Tag übersprungen.

Das Skript wird idealerweise als cronjob ins System eingebunden - mit täglich einmaliger Ausführung - so, das eine lückenlose History der Sleep/Wake Events erstellt werden kann. Voraussetzung dafür ist, dass das Skript mindestens einmal alle 6 Tage ausgeführt wird.

Die Sleep/Wake-Meldungen können dann z.B. wie folgt aus den Logs ausgelesen werden.

Auslesen der **Wake-Meldungen**:

````bash
#date="2025-03-03"                     # individual day
#date=$(date +"%Y-%m-%d")              # today
date=$(gdate -d"-1 days" +%Y-%m-%d)    # yesterday
file=~/Projects/WorkflowScripts/sleep-wake-to-file/logs/pmset-sleep-wake_"$date".log
cat "$file" | grep -e " Wake  " | grep "$date" | head -n 1
````

Auslesen der **Sleep-Meldungen**:

````bash
#date="2025-03-03"                     # individual day
#date=$(date +"%Y-%m-%d")              # today
date=$(gdate -d"-1 days" +%Y-%m-%d)    # yesterday -1
file=~/Projects/WorkflowScripts/sleep-wake-to-file/logs/pmset-sleep-wake_"$date".log
cat "$file" |grep -e "Entering Sleep state due to \'Clamshell Sleep\'" | grep "$date"
````
