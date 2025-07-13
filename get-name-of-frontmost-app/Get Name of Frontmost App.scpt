#@osa-lang:AppleScript
property pScriptName : "Get Name of Frontmost App.scpt"

property configFile : load script (POSIX path of (path to home folder) & ".workflowscripts/config.scpt")
property pWorkflowScriptsBaseFolder : pWorkflowScriptsBaseFolder of configFile
property pLogFile : pWorkflowScriptsBaseFolder & "/get-name-of-frontmost-app/logs/execution.log"

on run {}
	my writeLog("run: Started")

	set test to "Sample with dashes"
	set replacement to my replace_spaces(test)

	my writeLog("run: Finished")
end run

on hazelProcessFile(theFile, inputAttributes)
	my writeLog("hazelProcessFile: Started - theFile: " & theFile)

	set posixFile to POSIX path of theFile
	set theAppName to the application named (the path to the frontmost application)

	-- replace spaces with dashes
	set theAppNameWithDashes to my replace_spaces(theAppName)

	my writeLog("hazelProcessFile: Finished - theAppName: " & theAppName & ", theAppNameWithDashes: " & theAppNameWithDashes)
	return {hazelOutputAttributes:{appName:(theAppName as string), appNameWithDashes:(theAppNameWithDashes as string)}}
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

