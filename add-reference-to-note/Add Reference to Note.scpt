#@osa-lang:AppleScript
use scripting additions

property pScriptName : "Add Reference to Note.scpt"

property configFile : load script (POSIX path of (path to home folder) & ".workflowscripts/config.scpt")
property pWorkflowScriptsBaseFolder : pWorkflowScriptsBaseFolder of configFile
property pZettelkastenDailyHome : pZettelkastenDailyHome of configFile
property pZettelkastenMeetingsHome : pZettelkastenMeetingsHome of configFile
property pLogFile : pWorkflowScriptsBaseFolder & "/logs/execution.log"

on hazelProcessFile(theFile, inputAttributes)
	my writeLog("hazelProcessFile: Started > theFile: " & theFile)

	set {type, entry, datetime, showInline} to {"", "", "", false}
	try
		set type to item 1 of inputAttributes
	end try
	try
		set mdLink to item 2 of inputAttributes
	end try
	try
		set datetime to item 3 of inputAttributes
	end try
	try
		set showInline to item 4 of inputAttributes
		if showInline is equal to "1" then set showInline to true
	end try
	my writeLog("hazelProcessFile: type: " & type & ", mdLink: " & mdLink & ", datetime: " & datetime & ", showInline: " & showInline)

	my addToNote(type, mdLink, datetime, showInline)

	my writeLog("hazelProcessFile: Finished")
end hazelProcessFile

on addToNote(theType, theMdLink, theDatetime, showInline)
	my writeLog("addToNote: Started > theType: " & theType & ", theMdLink: " & theMdLink & ", theDatetime: " & theDatetime & ", showInline: " & showInline)

	set theEntry to "- " & theType & ":: "
	if showInline then set theEntry to theEntry & "!"
	set theEntry to theEntry & theMdLink

	set pythonPath to quoted form of (pWorkflowScriptsBaseFolder & "/.venv/bin/python")
	set scriptPath to quoted form of (pWorkflowScriptsBaseFolder & "/add-reference-to-note/add-reference-to-note.py")
	set shellCommand to pythonPath & " " & scriptPath & ¬
		" --daily-root=" & quoted form of pZettelkastenDailyHome & ¬
		" --meeting-root=" & quoted form of pZettelkastenMeetingsHome & ¬
		" --timestamp=" & quoted form of theDatetime & ¬
		" --entry=" & quoted form of theEntry
	do shell script shellCommand

	my writeLog("addToNote: Finished")
end addToNote

on writeLog(theMessage)
	set timestamp to do shell script "date \"+%Y-%m-%d %H:%M:%S\""
	do shell script "printf '%s
' " & quoted form of (timestamp & ": " & pScriptName & ": " & theMessage) & " >> " & quoted form of pLogFile
end writeLog

on run
	my writeLog("run: Started")

	set type to "Screenshot"
	set mdLink to "[Google](https://www.google.com)"
	set datetime to "20260321-081500"
	set showInline to false

	my addToNote(type, mdLink, datetime, showInline)

	my writeLog("run: Finished")
end run
