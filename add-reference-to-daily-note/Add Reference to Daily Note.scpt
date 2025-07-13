#@osa-lang:AppleScript
property pScriptName : "Add Reference to Daily Note.scpt"

property configFile : load script (POSIX path of (path to home folder) & ".workflowscripts/config.scpt")
property pWorkflowScriptsBaseFolder : pWorkflowScriptsBaseFolder of configFile
property pLogFile : pWorkflowScriptsBaseFolder & "/add-reference-to-daily-note/logs/execution.log"

on run {}
	my writeLog("run: Started")

	set workflowContentType to "Screenshot"
	set entry to "[Google](https://www.google.com)"

	my addReferenceToDailyNote(workflowContentType, entry)

	my writeLog("run: Finished")
end run

on hazelProcessFile(theFile, inputAttributes)
	my writeLog("hazelProcessFile: Started - theFile: " & theFile)

	set workflowContentType to item 1 of inputAttributes
	set entry to item 2 of inputAttributes
	my writeLog("hazelProcessFile: workflowContentType: " & workflowContentType & ", entry: " & entry)

	my addReferenceToDailyNote(workflowContentType, entry)

	my writeLog("hazelProcessFile: Finished")
end hazelProcessFile

on addClipboardToDailyNote()
	my writeLog("addClipboardToDailyNote: Started")

	set theClipboardText to (the clipboard as text)
	set theFrontmostApp to application (path to frontmost application as text) as text

	set theWorkflowContentType to "Other"
	if theFrontmostApp contains "Arc" or theFrontmostApp contains "Safari" then
		set theWorkflowContentType to "Bookmark"
	else if theFrontmostApp contains "DEVONthink" then
		set theWorkflowContentType to ""
	else
		set theWorkflowContentType to "Other"
	end if
	my addReferenceToDailyNote(theWorkflowContentType, theClipboardText)

	my writeLog("addClipboardToDailyNote: Finished")
end addClipboardToDailyNote

on addReferenceToDailyNote(theWorkflowContentType, theEntry)
	my writeLog("addReferenceToDailyNote: Started - theWorkflowContentType: " & theWorkflowContentType & ", theEntry: " & theEntry)

	do shell script pWorkflowScriptsBaseFolder & "/add-reference-to-daily-note/add-reference-to-daily-note.sh -d=" & theWorkflowContentType & " -e=\"" & theEntry & "\""

	my writeLog("addReferenceToDailyNote: Finished")
end addReferenceToDailyNote

on writeLog(theMessage)
	set timestamp to do shell script "date \"+%Y-%m-%d %H:%M:%S\""
	do shell script "echo \"" & timestamp & ": " & pScriptName & ": " & theMessage & "\" >> " & pLogFile
end writeLog

