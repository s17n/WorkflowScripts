#@osa-lang:AppleScript
property pLogFile : "~/Projects/WorkflowScripts/copy-file-path-as-markdown-link/execution.log"
property pScriptName : "Copy Filepath as Markdown Link.scpt"

on hazelProcessFile(theFile, inputAttributes)

	-- 'theFile' is an alias to the file that matched.
	-- 'inputAttributes' is an AppleScript list of the values of any attributes you told Hazel to pass in.
	-- Be sure to return true or false (or optionally a record) to indicate whether the file passes this script.

	my writeLog("theFile: " & theFile)

	set posixFile to POSIX path of theFile
	set posixFileUrlEncoded to my urlEncode(posixFile)

	set title to "Screenshot" -- in Hazel only used for Screenshots
	set subtitle to item 1 of inputAttributes

	set mdLink to create_markdown_link(title, subtitle, posixFile)
	my writeLog("mdLink: " & mdLink)
	set the clipboard to {text:(mdLink as string), Unicode text:mdLink}

end hazelProcessFile

on create_markdown_link(theTitle, theSubtitle, theLink)
	set mdLink to "[" & theTitle & " - " & theSubtitle & "](file://" & theLink & ")"
	return mdLink
end create_markdown_link

on urlEncode(str)
	local str
	try
		return (do shell script "/bin/echo " & quoted form of str & ¬
			" | perl -MURI::Escape -lne 'print uri_escape($_)'")
	on error eMsg number eNum
		error "Can't urlEncode: " & eMsg number eNum
	end try
end urlEncode

on writeLog(theMessage)
	set timestamp to do shell script "date \"+%Y-%m-%d %H:%M:%S\""
	do shell script "echo \"" & timestamp & ": " & pScriptName & ": " & theMessage & "\" >> " & pLogFile
end writeLog

on run {}
	set mdLink to my create_markdown_link("Titel", "Untertitel", "the-actual-link")
	my writeLog(mdLink)
end run