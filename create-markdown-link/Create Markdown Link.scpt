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
	my createMarkdownLink()
	my writeLog("run: Finished")
end run

on hazelProcessFile(theFile, inputAttributes)
	my writeLog("hazelProcessFile: Started - theFile: " & theFile)

	-- 'theFile' is an alias to the file that matched.
	-- 'inputAttributes' is an AppleScript list of the values of any attributes you told Hazel to pass in.
	-- Be sure to return true or false (or optionally a record) to indicate whether the file passes this script.


	set title to "Screenshot" -- in Hazel only used for Screenshots
	set subtitle to item 1 of inputAttributes

	set prefixText to title & " - " & subtitle
	set mdLink to createMdLinkForFileReference(prefixText, theFile)
	set the clipboard to {text:(mdLink as string), Unicode text:mdLink}

	my writeLog("hazelProcessFile: Finished - mdLink: " & mdLink)
end hazelProcessFile

on createMdLinkForFileReference(thePrefix, theFile)
	my writeLog("createMdLinkForFileReference: Started")

	set posixFile to POSIX path of theFile
	--set posixFileUrlEncoded to my urlEncode(posixFile)

	set mdLink to "[" & thePrefix & "](file://" & posixFile & ")"

	my writeLog("createMdLinkForFileReference: Finished")
	return mdLink
end createMdLinkForFileReference

on createMdLinkForSelectedFinderItem()
	my writeLog("createMdLinkForSelectedFinderItem: Started")

	tell application "Finder" to set theSelection to selection
	set theSelectedItem to POSIX path of (item 1 of theSelection as alias)
	--set theSelectedItemUrlEncoded to my urlEncode(theSelectedItem)
	set theFileName to name of (item 1 of theSelection)
	my writeLog("createMdLinkForSelectedFinderItem: theSelectedItem: " & theSelectedItem & ", theName: " & theFileName)

	set mdLink to "[" & theFileName & "](file://" & theSelectedItem & ")"

	my writeLog("createMdLinkForSelectedFinderItem: Started")
	return mdLink
end createMdLinkForSelectedFinderItem

on createMarkdownLink()
	my writeLog("createMarkdownLink: Started")

	-- set theCurrentApp to name of current application
	set theFrontmostApp to application (path to frontmost application as text) as text

	set theClipboardText to (the clipboard as text)
	set theMdLink to null
	set theDataviewKey to null

	my writeLog("run: frontmost application: " & theFrontmostApp)
	if theFrontmostApp contains "DEVONthink" then
		set theMdLink to my createDEVONthinkLink()
		set theDataviewKey to "r/DEVONthink"
	else if theFrontmostApp contains "Finder" then
		set theMdLink to my createMdLinkForSelectedFinderItem()
		set theDataviewKey to "r/Finder"
	else
		my writeLog("run: clipboard: " & theClipboardText)
		if theClipboardText contains pBoxLinkIdentifier then
			set theMdLink to my convertBoxLink(theClipboardText)
			set theDataviewKey to "r/Box"
		else if theClipboardText contains pSlackLinkIdentifier then
			set theMdLink to my convertSlackLink(theClipboardText)
			set theDataviewKey to "r/Slack"
		else
			my writeLog("run: Unknown application and link format")
		end if
	end if

	if theMdLink is not null then
		set the clipboard to {text:(theMdLink as string), Unicode text:theMdLink}
		do shell script "echo \"" & theDataviewKey & "\" > " & pWorkflowScriptsBaseFolder & "/.current-dataview-key"
	end if
	my writeLog("createMarkdownLink: Finished - mdLink: " & theMdLink)

end createMarkdownLink


on urlEncode(str)
	my writeLog("urlEncode: Stared")
	local str
	local strEncoded
	try
		set strEncoded to (do shell script "/bin/echo " & quoted form of str & ¬
			" | perl -MURI::Escape -lne 'print uri_escape($_)'")
	on error eMsg number eNum
		error "Can't urlEncode: " & eMsg number eNum
	end try
	my writeLog("urlEncode: Finished")
	return strEncoded
end urlEncode


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

