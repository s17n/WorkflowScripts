#@osa-lang:AppleScript
use AppleScript version "2.5"
use framework "Foundation"
use script "CalendarLib EC" version "1.1.5" -- put this at the top of your scripts
use scripting additions

property pScriptName : "Create Meeting Note from Calendar Entry.scpt"

property configFile : load script (POSIX path of (path to home folder) & ".workflowscripts/config.scpt")
property pInboxFolder : pZettelkastenInboxFolder of configFile
property pWorkflowScriptsBaseFolder : pWorkflowScriptsBaseFolder of configFile
property pNoteHeading : pMeetingNoteHeading of configFile
property pLastname : pLastname of configFile
property pOverwriteExistingNoteDefault : pOverwriteExistingNote of configFile
property pRemoveCallInBlock : pRemoveCallInBlock of configFile
property pCallInBlockStartIdentifier : pCallInBlockStartIdentifier of configFile
property pCallInBlockEndIdentifier : pCallInBlockEndIdentifier of configFile
property pLogFile : pWorkflowScriptsBaseFolder & "/create-meeting-note/logs/execution.log"
property pOverwriteExistingNote : true --pOverwriteExistingNoteDefault

on run {}
	my writeLog("run: Started")
	set timeParam to do shell script "/opt/homebrew/bin/gdate \"+%y-%m-%d %H:%M\""
	set timeParam to "2025-05-30 11:00"
	my createNoteWithTime(timeParam)
	my writeLog("run: Finished")
end run

-- Ermittelt für die angegebene Zeit den passenden Kalendereintrag und erstellt mit den Daten
-- des Kalendereintrags eine Meeting Note im Inbox Folder des Zettelkastens.
-- Wird nur eine Uhrzeit übergeben, dann wird als Datum das aktuelle Systemdatum verwendet.
-- Der Aufruf erfolgt überlicherweise aus der Daily Note heraus mittels PopClip.
-- Parameter:
--   timeParam - im Format "HH:MM" oder "YYYY-mm-dd HH:MM"
on createNoteWithTime(timeParam)
	my writeLog("createNoteWithTime: Started - timeParam: " & timeParam)

	set dateFragment to null
	if length of timeParam is 16 then
		set dateTimeParam to timeParam
	else
		set dateFragment to do shell script "/opt/homebrew/bin/gdate \"+%Y-%m-%d\""
		set dateTimeParam to dateFragment & " " & timeParam
	end if
	my fetchEventAndCreateNote(dateTimeParam)

	my writeLog("createNoteWithTime: Finished - dateTimeParam: " & dateTimeParam)
end createNoteWithTime

on hazelProcessFile(theFile, inputAttributes)
	my writeLog("hazelProcessFile: " & POSIX file theFile)
	set filename to null
	if (theFile as string) contains "Microsoft-Teams" then
		my writeLog("hazelProcessFile: Microsoft-Teams file detected - process Calendar events")
		set todayFragment to do shell script "/opt/homebrew/bin/gdate \"+%y-%m-%d %H:%M\""
		set filename to my fetchEventAndCreateNote(todayFragment)
	end if
	return {hazelOutputAttributes:{filename}}
end hazelProcessFile

-- Ermittelt das Meeting (Event) aus dem Kalender und delegiert das Erstellen der Note.
-- Wenn kein Event ermittelt werden kann, wird eine Meldung im Log ausgegeben.
-- Parameter:
--   dateFragment - im Format "yy-MM-dd hh:mm"
-- Return:
--   filenameOfMeetingNote - aktuell nur für Hazel relevant
on fetchEventAndCreateNote(dateFragment)
	my writeLog("fetchEventAndCreateNote: Started - dateFragment: " & dateFragment)

	set theFilenameOfMeetingNote to null
	set fetchStartFragment to text items 1 thru 10 of dateFragment & " 00:00"
	set fetchEndFragment to text items 1 thru 10 of dateFragment & " 23:59"

	set theDate to my convertDateStringToISO8601Date(dateFragment)
	set fetchStartDate to my convertDateStringToISO8601Date(fetchStartFragment)
	set fetchEndDate to my convertDateStringToISO8601Date(fetchEndFragment)

	set theEvent to my fetchEvent(fetchStartDate, fetchEndDate, theDate)
	if theEvent is not null then
		set theFilenameOfMeetingNote to my createMeetingNoteFromEvent(theEvent)
	else
		my writeLog("fetchEventAndCreateNote: No Meeting Note created because no event was found for the given date/time.")
	end if

	my writeLog("fetchEventAndCreateNote: Finished - filenameOfMeetingNote: " & theFilenameOfMeetingNote)
	return theFilenameOfMeetingNote
end fetchEventAndCreateNote

on fetchEvent(fetchStartDate, fetchEndDate, theDate)

	try
		my writeLog("fetchEvent: Started - fetchStartDate: " & fetchStartDate & ", fetchEndDate: " & fetchEndDate & ", theDate: " & theDate)

		set theStore to fetch store
		set theCal to fetch calendar "Calendar" cal type cal exchange event store theStore -- change to suit
		set theEvents to fetch events starting date fetchStartDate ending date fetchEndDate searching cals {theCal} event store theStore

		set theEvent to null
		if length of theEvents > 0 then
			my writeLog("fetchEvent: Events found: " & length of theEvents)
			repeat with anEvent in theEvents
				set anEventInfo to event info for event anEvent
				-- my writeLog("run: Fetch events - event #" & i & ":  " & my eventInfoSummary(theEventInfo))
				set startDate to event_start_date of anEventInfo
				set endDate to event_end_date of anEventInfo
				if startDate is less than or equal to theDate and endDate is greater than theDate then
					my writeLog("fetchEvent: Found matching event:  " & my eventInfoSummary(anEventInfo))
					set theEvent to anEvent
				end if
			end repeat
		else
			my writeLog("fetchEvent: No events found.")
		end if
		my writeLog("fetchEvent: Finsihed")

		return theEvent
	on error errStr number errorNumber
		error errStr number errorNumber
	end try
end fetchEvent

-- Erstellt eine Notiz für ein Meeting. Das Meeting muss zur angegebenen Uhrzeit im Exchange Kalender stehen.
--
on createMeetingNoteFromEvent(theEvent)
	my writeLog("createMeetingNoteFromEvent: Started")

	set theEventInfo to event info for event theEvent
	set theEventAttendees to null
	try
		set theEventAttendees to event attendees for event theEvent
	on error errStr number errorNumber
		if errorNumber = -10000 then
			my writeLog("createMeetingNoteFromEvent: Bekannter Fehler bei Aufruf von 'event attendees for event' -> wird ignoriert")
		else
			error errStr number errorNumber
		end if
	end try

	set theFilename to my formatASDate(event_start_date of theEventInfo, "%Y%m%d-%H%M")
	set theFQFN to pInboxFolder & "/" & theFilename & ".md"
	set the clipboard to "[[" & theFilename & "]]"

	if my FileExists(theFQFN) and not pOverwriteExistingNote then
		my writeLog("createMeetingNoteFromEvent: Meeting Note already exists.")
	else
		my writeLog("createMeetingNoteFromEvent: Create Meeting Note: " & theFQFN)
		set content to my createContentForMeetingNote(theEventInfo, theEventAttendees)
		do shell script "echo \"" & (content as string) & "\" > \"" & theFQFN & "\""
		if pRemoveCallInBlock then
			my removeCallInBlock(theFQFN)
		end if
	end if
	my writeLog("createMeetingNoteFromEvent: Finished")
	return theFQFN
end createMeetingNoteFromEvent

on removeCallInBlock(theFile)
	my writeLog("removeCallInBlock: Started")

	-- grep -n "Microsoft Teams Need help?" 20250530-1100.md | awk  -F':' ' { print $1 }'
	set startLineNumber to do shell script "grep -n \"" & (pCallInBlockStartIdentifier as string) & "\" \"" & (theFile as string) & "\" | awk  -F':' ' { print $1 }'"
	set endLineNumber to do shell script "grep -n \"" & (pCallInBlockEndIdentifier as string) & "\" \"" & (theFile as string) & "\" | awk  -F':' ' { print $1 }'"
	set startLineNumber to startLineNumber - 1
	set endLineNumber to endLineNumber + 1
	set sedParameter to startLineNumber & "," & endLineNumber & "d"
	-- sed -i -e '36,51d' 20250530-1100.md
	my writeLog("removeCallInBlock: Remove lines: " & startLineNumber & " - " & endLineNumber & " from note: " & theFile)
	do shell script "sed -i -e \"" & sedParameter & "\" \"" & (theFile as string) & "\""

	my writeLog("removeCallInBlock: Finished")
end removeCallInBlock

on createContentForMeetingNote(theEventInfo, theEventAttendees)
	my writeLog("createContentForMeetingNote: Started")
	set {content, theTeilnehmer, numberTotal, numberAccepted, numberDeclined, numberTentative, numberOther} to {"", "(nicht ermittelbar)", 0, 0, 0, 0, 0}
	if theEventAttendees is not null then
		set theResult to my createAttendeesList(theEventAttendees)
		set theTeilnehmer to content of theResult
		set numberAccepted to number_accepted of theResult
		set numberDeclined to number_declined of theResult
		set numberTentative to number_tentative of theResult
		set numberOther to number_other of theResult
		set numberTotal to numberAccepted + numberDeclined + numberTentative + numberOther + 1 -- + 1 für Chair
		---
		set theChair to my getChair(theEventAttendees)
	end if

	set theSummary to (event_summary of theEventInfo as string)
	set theTime to my formatASDate(event_start_date of theEventInfo, "%d.%m.%Y %H:%M") & ¬
		" - " & my formatASDate(event_end_date of theEventInfo, "%H:%M")

	set theDay to my formatASDate(event_start_date of theEventInfo, "%Y-%m-%d")
	set theStart to my formatASDate(event_start_date of theEventInfo, "%H:%M")
	set theEnd to my formatASDate(event_end_date of theEventInfo, "%H:%M")
	set fm to "---" & linefeed
	set fm to fm & "meeting:" & linefeed
	set fm to fm & "  day: " & theDay & linefeed
	set fm to fm & "  start: " & theStart & linefeed
	set fm to fm & "  end: " & theEnd & linefeed
	set fm to fm & "  attendees_total: " & numberTotal & linefeed
	set fm to fm & "  attendees_accepted: " & numberAccepted & linefeed
	set fm to fm & "  attendees_declined: " & numberDeclined & linefeed
	set fm to fm & "  attendees_tentative: " & numberTentative & linefeed
	set fm to fm & "  attendees_other: " & numberOther & linefeed
	set fm to fm & "---" & linefeed

	set theTasks to "- [ ] Meeting Note erstellen für: " & theSummary & " bis: 🗓️" & theDay & linefeed
	if theChair contains pLastname then
		set theTasks to theTasks & "- [ ] Protokoll verteilen für: " & theSummary & " bis: 🗓️" & theDay
	end if
	set content to fm
	set content to content & pNoteHeading & linefeed ¬
		& "# Todos" & linefeed & linefeed ¬
		& theTasks & linefeed ¬
		& "# Termin" & linefeed & linefeed ¬
		& "- Summary: " & theSummary & linefeed ¬
		& "- Date: " & theTime & linefeed ¬
		& theTeilnehmer & linefeed ¬
		& "### Description " & linefeed & (event_description of theEventInfo as string) & linefeed ¬
		& "# Mitschrift " & linefeed & linefeed & linefeed ¬
		& "# Referenzen " & linefeed
	my writeLog(content)
	my writeLog("createContentForMeetingNote: Finished")
	return content
end createContentForMeetingNote

on getChair(theAttendees)
	my writeLog("getChair: Started")
	set theChairName to "(nicht ermittelbar)"
	repeat with attendee in theAttendees
		set theRole to attendee_role of attendee
		if theRole is "chair" or theRole is "unknown" then
			set theChairName to attendee_name of attendee
			my writeLog("getChair: Chair is: " & theChairName)
		end if
	end repeat
	return theChairName
	my writeLog("getChair: Finished")
end getChair

on createAttendeesList(theAttendees)
	my writeLog("createAttendeesList: Started")
	log (theAttendees)

	set theContent to ""

	set number_total to 0
	set number_accepted to 0
	set number_declined to 0
	set number_tentative to 0
	set number_other to 0 -- umfasst to attendee_status: in process, unknown
	if length of theAttendees > 0 then
		my writeLog("createAttendeesList: Attendees found: " & length of theAttendees)

		set theChairName to "(nicht ermittelbar)"
		set required to {}
		set optional to {}

		repeat with attendee in theAttendees
			set theRole to attendee_role of attendee
			if theRole is "chair" or theRole is "unknown" then
				set theChairName to attendee_name of attendee
			else if theRole is "required" then
				set end of required to attendee
			else
				set end of optional to attendee
			end if
		end repeat

		set theChairString to "- Chair: " & theChairName & linefeed
		set theContent to theContent & theChairString

		set theSublistResult to my createAttendeesSection("- Required: ", required)
		set number_accepted to number_accepted + (number_accepted of theSublistResult)
		set number_declined to number_declined + (number_declined of theSublistResult)
		set number_tentative to number_tentative + (number_tentative of theSublistResult)
		set number_other to number_other + (number_other of theSublistResult)
		set theContent to theContent & content of theSublistResult

		set theSublistResult to my createAttendeesSection("- Optional: ", optional)
		set number_accepted to number_accepted + (number_accepted of theSublistResult)
		set number_declined to number_declined + (number_declined of theSublistResult)
		set number_tentative to number_tentative + (number_tentative of theSublistResult)
		set number_other to number_other + (number_other of theSublistResult)
		set theContent to theContent & content of theSublistResult
	else
		set theContent to "(keine)"
		my writeLog("createAttendeesList: No attendees found. ")
	end if
	return {content:theContent, number_accepted:number_accepted, number_declined:number_declined, number_tentative:number_tentative, number_other:number_other}
	my writeLog("createAttendeesList: Finished")
end createAttendeesList

on createAttendeesSection(theSectionHeader, theAttendeeList)
	my writeLog("createAttendeesSection: Started - theSectionHeader: " & theSectionHeader)

	set accepted to {}
	set declined to {}
	set tentative to {}
	set other to {}
	repeat with attendee in theAttendeeList
		set theStatus to attendee_status of attendee
		if theStatus is "accepted" then
			set end of accepted to attendee
		else if theStatus is "declined" then
			set end of declined to attendee
		else if theStatus is "tentative" then
			set end of tentative to attendee
		else
			set end of other to attendee
		end if
	end repeat
	set theContent to theSectionHeader & linefeed
	repeat with attendee in accepted
		set theContent to theContent & "	- " & attendee_name of attendee & ", " & attendee_status of attendee & linefeed
	end repeat
	repeat with attendee in declined
		set theContent to theContent & "	- " & attendee_name of attendee & ", " & attendee_status of attendee & linefeed
	end repeat
	repeat with attendee in tentative
		set theContent to theContent & "	- " & attendee_name of attendee & ", " & attendee_status of attendee & linefeed
	end repeat
	repeat with attendee in other
		set theContent to theContent & "	- " & attendee_name of attendee & ", " & attendee_status of attendee & linefeed
	end repeat

	my writeLog("createAttendeesSection: Finished")
	return {content:theContent, number_accepted:length of accepted, number_declined:length of declined, number_tentative:length of tentative, number_other:length of other}
end createAttendeesSection

on eventInfoSummary(theEventInfo)
	set theSummary to (event_summary of theEventInfo & ¬
		", " & event_start_date of theEventInfo as string) & ¬
		", " & event_end_date of theEventInfo as string
	return theSummary
end eventInfoSummary

on FileExists(theFile) -- (String) as Boolean
	tell application "System Events"
		if exists file theFile then
			return true
		else
			return false
		end if
	end tell
end FileExists

on formatASDate(theDate, theFormat)
	my writeLog("formatASDate: Started")

	set {year:y, month:m, day:d, hours:h, minutes:min} to theDate
	set min_str to text -1 thru -2 of ("00" & min)
	set hours_str to text -1 thru -2 of ("00" & h)
	set day_str to text -1 thru -2 of ("00" & d)
	set mon_str to text -1 thru -2 of ("00" & (m * 1))
	set theNormalizedDateAsString to y & "-" & mon_str & "-" & day_str & " " & hours_str & ":" & min_str
	my writeLog("formatASDate: theDateAsString: " & theNormalizedDateAsString)

	set theFormatedDateAsString to do shell script "/opt/homebrew/bin/gdate -d\"" & theNormalizedDateAsString & "\"  +\"" & theFormat & "\" "
	my writeLog("formatASDate: Finished theFormatedDateAsString: " & theFormatedDateAsString)

	my writeLog("formatASDate: Finished")
	return theFormatedDateAsString

end formatASDate

-- Beispiel für das ISO8601 Date Format:
--    "2025-04-05T08:45:00GMT+2"
--    "2025-04-05T09:10:38+0200"
--
on convertDateStringToISO8601Date(theDateStringFragment)
	my writeLog("convertDateStringToISO8601Date: Started - theDateStringFragment: " & theDateStringFragment)

	set theDateString to do shell script "/opt/homebrew/bin/gdate -d\"" & theDateStringFragment & "\"  +\"%Y-%m-%dT%H:%M:%S%z\" "
	set formatter to current application's NSISO8601DateFormatter's new()
	set theDate to (formatter's dateFromString:theDateString) as date

	my writeLog("convertDateStringToISO8601Date: Finished - theDate: " & theDate)
	return theDate
end convertDateStringToISO8601Date

on writeLog(theMessage)
	set timestamp to do shell script "date \"+%Y-%m-%d %H:%M:%S\""
	do shell script "echo \"" & timestamp & ": " & pScriptName & ": " & theMessage & "\" >> " & pLogFile
end writeLog

