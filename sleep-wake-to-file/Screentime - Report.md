Übersicht der Zeiten (von/bis, Dauer, Total) pro Tag, in denen der Mac im FullWake mit eingeschaltetem Display war. 

```bash
project_dir="/Users/steffen/Projects/WorkflowScripts/sleep-wake-to-file"
for i in {0..7}
do
    date=$(gdate -d"-$i days" +%Y-%m-%d)     
    gdate -d"-$i days" "+%A, %d.%m.%Y"
    if (( i < 2 )); then
		pmset -g log | grep -e "$date" \
		     | grep -e " Sleep  " -e " Wake  " \
		     | awk -f "$project_dir/screentime.awk"
	else
	   log_file="$project_dir/logs/pmset-sleep-wake_$date.log"
	   if [[ -f "$log_file" ]]; then
	      awk -f "$project_dir/screentime.awk" "$log_file"
	   else
	      printf "Keine Logdatei: %s\n\n" "$log_file"
	   fi
	fi
done
```
