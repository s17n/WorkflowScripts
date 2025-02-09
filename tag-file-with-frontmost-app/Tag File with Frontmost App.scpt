#@osa-lang:AppleScript
property pLogFile : "~/Projects/WorkflowScripts/tag-file-with-frontmost-app/execution.log"
property pScriptName : "Tag File with Frontmost App.scpt"

on hazelProcessFile(theFile, inputAttributes)

	-- 'theFile' is an alias to the file that matched.
	-- 'inputAttributes' is an AppleScript list of the values of any attributes you told Hazel to pass in.
	-- Be sure to return true or false (or optionally a record) to indicate whether the file passes this script.

	my writeLog("theFile: " & theFile)

	set posixFile to POSIX path of theFile
	set frontmostApp to the application named (the path to the frontmost application)
	do shell script "xattr -w s17n.app" & " \"" & frontmostApp & "\"" & " \"" & posixFile & "\""

	-- replace spaces with dashes
	set frontmostAppDashed to my replace_spaces(frontmostApp)

	my writeLog("frontmostApp: " & frontmostApp & ", frontmostAppDashed: " & frontmostAppDashed)
	return {hazelOutputAttributes:{frontApp:(frontmostApp as string), frontAppDashed:(frontmostAppDashed as string)}}

end hazelProcessFile

on replace_spaces(theText)

	-- command: echo "text with spaces" | sed 's/ /-/g'
	--  return: text-with-spaces
	set theReplacedText to do shell script "echo \"" & theText & "\" | sed 's/ /-/g'"
	return theReplacedText

end replace_spaces

on writeLog(theMessage)
	set timestamp to do shell script "date \"+%Y-%m-%d %H:%M:%S\""
	do shell script "echo \"" & timestamp & ": " & pScriptName & ": " & theMessage & "\" >> " & pLogFile
end writeLog

on run {}
	set test to "Sample with dashes"
	set replacement to my replace_spaces(test)
end run