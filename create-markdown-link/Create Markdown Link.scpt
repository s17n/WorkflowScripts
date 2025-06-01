#@osa-lang:AppleScript
property pScriptName : "Create Markdown Link.scpt"
property configFile : load script (POSIX path of (path to home folder) & ".workflowscripts/config.scpt")
property pWorkflowScriptsBaseFolder : pWorkflowScriptsBaseFolder of configFile
property pMailScriptsBaseFolder : pMailScriptsBaseFolder of configFile

property pBoxLinkIdentifier : pBoxLinkIdentifier of configFile
property pBoxLocalPathPrefix : pBoxLocalPathPrefix of configFile
property pBoxMdLinkPrefix : pBoxMdLinkPrefix of configFile

property pSlackLinkIdentifier : pSlackLinkIdentifier of configFile
property pDevonthinkCopyItemLinkScript : pMailScriptsBaseFolder & "/DEVONthink Menu/Copy Item Link as Markdown Link.scpt"
property pLogFile : pWorkflowScriptsBaseFolder & "/create-markdown-link/logs/execution.log"

on run {}
	my writeLog("run: Started")

	-- set theCurrentApp to name of current application
	set theFrontmostApp to application (path to frontmost application as text) as text

	set theClipboardText to (the clipboard as text)
	set theMdLink to null

	my writeLog("run: frontmost application: " & theFrontmostApp)
	if theFrontmostApp contains "DEVONthink" then
		set theMdLink to my createDEVONthinkLink()
	else
		my writeLog("run: clipboard: " & theClipboardText)
		if theClipboardText contains pBoxLinkIdentifier then
			set theMdLink to my convertBoxLink(theClipboardText)
		else if theClipboardText contains pSlackLinkIdentifier then
			set theMdLink to my convertSlackLink(theClipboardText)
		else
			my writeLog("run: Unknown application and link format")
		end if
	end if

	if theMdLink is not null then
		set the clipboard to {text:(theMdLink as string), Unicode text:theMdLink}
	end if
	my writeLog("run: Finished")

end run

on createDEVONthinkLink()
	my writeLog("createDEVONthinkLink: Started")

	set theScript to load script pDevonthinkCopyItemLinkScript
	tell theScript to set theMdLink to createMarkdownLink()

	my writeLog("createDEVONthinkLink: Finished - markdown link: " & theMdLink)
	return theMdLink
end createDEVONthinkLink

on convertSlackLink(theClipboardText)
	set mdLink to "[Slack](" & theClipboardText & ")"
	return mdLink
end convertSlackLink

on convertBoxLink(theClipboardText)
	tell application "Finder"
		--set theFile to selection as file specification
		set fileName to container of item 1 of (get selection)

		tell application "Finder" to set sel to selection
		set thePosixPath to POSIX path of (item 1 of sel as alias)

		set inputText to thePosixPath
		set findText to pBoxLocalPathPrefix
		set replaceText to pBoxMdLinkPrefix

		-- https://stackoverflow.com/questions/38041852/does-applescript-have-a-replace-function
		set theBoxPath to do shell script "sed 's|" & quoted form of findText & "|" & quoted form of replaceText & "|g' <<< " & quoted form of inputText

		set mdLink to "[" & theBoxPath & "](" & theClipboardText & ")"
		return mdLink

	end tell
end convertBoxLink

on writeLog(theMessage)
	set timestamp to do shell script "date \"+%Y-%m-%d %H:%M:%S\""
	do shell script "echo \"" & timestamp & ": " & pScriptName & ": " & theMessage & "\" >> " & pLogFile
end writeLog
