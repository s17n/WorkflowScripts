#@osa-lang:AppleScript
use AppleScript version "2.5"
use framework "Foundation"
use script "CalendarLib EC" version "1.1.5" -- put this at the top of your scripts
use scripting additions

property pScriptName : "Create Meeting Note from Calendar Entry.scpt"

property configFile : load script (POSIX path of (path to home folder) & ".workflowscripts/config.scpt")
property pInboxFolder : pZettelkastenInboxFolder of configFile
property pWorkflowScriptsBaseFolder : pWorkflowScriptsBaseFolder of configFile
property pMeetingNoteHeading : pMeetingNoteHeading of configFile
property pLastname : pLastname of configFile
property pOverwriteExistingNoteDefault : pOverwriteExistingNote of configFile
property pRemoveCallInBlock : pRemoveCallInBlock of configFile
property pCallInBlockStartIdentifier : pCallInBlockStartIdentifier of configFile
property pCallInBlockEndIdentifier : pCallInBlockEndIdentifier of configFile
property pLogFile : pWorkflowScriptsBaseFolder & "/create-meeting-note/logs/execution.log"
property pOverwriteExistingNote : true --pOverwriteExistingNoteDefault

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

on run {}
	my writeLog("run: Started")

	set theDateTime to do shell script "/opt/homebrew/bin/gdate \"+%Y-%m-%d\""
	set theResult to display dialog "Datum & Uhrzeit (Beginn des Meetings) zu der eine Meeting Note erstellt werden soll (Format: YYYY-mm-dd hh:mm):" buttons {"List Meetings", "Cancel", "Create"} default answer theDateTime default button 1

	set theDateTime to text returned of theResult
	if button returned of theResult is "List Meetings" then
		set allEventsOfDayResult to my fetchEventsByDay(theDateTime)
		set theEvents to item 1 of allEventsOfDayResult
		set theListOfEvents to item 2 of allEventsOfDayResult
		set theSelectedEvent to choose from list theListOfEvents
		if theSelectedEvent is not false then
			set theEvent to my getEventByListEntry(theEvents, theSelectedEvent)
			set theFilenameOfMeetingNote to my createNoteFromEvent(theEvent)
			my setClipboard(theEvent)
		end if

	else if button returned of theResult is "Create" then
		my createNoteFromDateTime(theDateTime)

	end if

	my writeLog("run: Finished")
end run


-- Ermittelt für die angegebene Zeit den passenden Kalendereintrag und erstellt mit den Daten
-- des Kalendereintrags eine Meeting Note im Inbox Folder des Zettelkastens.
-- Wird nur eine Uhrzeit übergeben, dann wird als Datum das aktuelle Systemdatum verwendet.
-- Der Aufruf erfolgt überlicherweise aus der Daily Note heraus mittels PopClip.
-- Parameter:
--   timeParam - im Format "HH:MM" oder "YYYY-mm-dd HH:MM"
on createNoteFromDateTime(theDateTime)
	my writeLog("createNoteFromDateTime: Started - theDateTime: " & theDateTime)

	if not length of theDateTime is 16 then
		set theDay to do shell script "/opt/homebrew/bin/gdate \"+%Y-%m-%d\""
		set theDateTime to theDay & " " & theDateTime
	end if
	set theDay to text items 1 thru 10 of theDateTime

	set allEventsOfDayResult to my fetchEventsByDay(theDay)
	set theEvents to item 1 of allEventsOfDayResult
	set theEvent to my getEventByTime(theEvents, theDateTime)
	if theEvent is not null then
		set theFilenameOfMeetingNote to my createMeetingNoteFromEvent(theEvent)
	end if
	my writeLog("createNoteFromDateTime: Finished")
end createNoteFromDateTime

on getEventByListEntry(theEvents, theSelectedEvent)
	my writeLog("getEventByListEntry: Started")

	set theEvent to null
	repeat with anEvent in theEvents
		set eventEntryString to my eventEntry(anEvent)
		if (eventEntryString as string) is equal to (theSelectedEvent as string) then
			set theEvent to anEvent
		end if
	end repeat

	my writeLog("getEventByListEntry: Finished")
	return theEvent
end getEventByListEntry

on getEventByTime(theEvents, theDateTime)
	my writeLog("getEventByTime: Started")

	set theDateTimeInISO to my convertDateStringToISO8601Date(theDateTime)
	set theEvent to null

	repeat with anEvent in theEvents
		set anEventInfo to event info for event anEvent
		set startDate to event_start_date of anEventInfo
		set endDate to event_end_date of anEventInfo
		if startDate is less than or equal to theDateTimeInISO and endDate is greater than theDateTimeInISO then
			my writeLog("getEventByTime: Found matching event:  " & my eventInfoSummary(anEventInfo))
			set theEvent to anEvent
		end if
	end repeat

	my writeLog("getEventByTime: Finished")
	return theEvent
end getEventByTime

on fetchEventsByDay(theDay)
	my writeLog("fetchEventsByDay: Started - theDay: " & theDay)

	set fetchStartDate to my convertDateStringToISO8601Date((theDay as text) & " 00:00")
	set fetchEndDate to my convertDateStringToISO8601Date((theDay as text) & " 23:59")
	set theStore to fetch store
	set theCal to fetch calendar "Calendar" cal type cal exchange event store theStore -- change to suit
	set theEvents to fetch events starting date fetchStartDate ending date fetchEndDate searching cals {theCal} event store theStore

	set theEventsList to {}
	if length of theEvents > 0 then
		repeat with anEvent in theEvents
			set end of theEventsList to my eventEntry(anEvent)
		end repeat
	end if

	my writeLog("fetchEventsByDay: Finished")
	return {theEvents, theEventsList}
end fetchEventsByDay

on eventEntry(theEvent)
	my writeLog("eventEntry: Started")

	set theEventInfo to event info for event theEvent
	set theEventSummary to (event_summary of theEventInfo as string)
	set startDate to event_start_date of theEventInfo
	set endDate to event_end_date of theEventInfo

	set startDateAsString to my formatASDate(event_start_date of theEventInfo, "%H:%M")
	set endDateAsString to my formatASDate(event_end_date of theEventInfo, "%H:%M")

	my writeLog("eventEntry: Finished")
	return (startDateAsString as string) & " - " & (endDateAsString) & ": " & theEventSummary
end eventEntry

on setClipboard(theEvent)
	my writeLog("setClipboard: Started")

	set theEventInfo to event info for event theEvent
	set startDateAsString to my formatASDate(event_start_date of theEventInfo, "%H:%M")
	set endDateAsString to my formatASDate(event_end_date of theEventInfo, "%H:%M")
	set theFilename to my formatASDate(event_start_date of theEventInfo, "%Y%m%d-%H%M")
	set the clipboard to startDateAsString & " - " & endDateAsString & " [[" & theFilename & "]]"

	my writeLog("setClipboard: Finished")
end setClipboard

on createNoteFromEvent(theEvent)
	my writeLog("createNoteFromEvent: Started")

	set theEventInfo to event info for event theEvent
	set theEventAttendees to null
	try
		set theEventAttendees to event attendees for event theEvent
	on error errStr number errorNumber
		if errorNumber = -10000 then
			my writeLog("createNoteFromEvent: Bekannter Fehler bei Aufruf von 'event attendees for event' -> wird ignoriert")
		else
			error errStr number errorNumber
		end if
	end try

	set theFilename to my formatASDate(event_start_date of theEventInfo, "%Y%m%d-%H%M")
	set theFQFN to pInboxFolder & "/" & theFilename & ".md"
	set the clipboard to "[[" & theFilename & "]]"

	if my FileExists(theFQFN) and not pOverwriteExistingNote then
		my writeLog("createNoteFromEvent: Meeting Note already exists.")
	else
		my writeLog("createNoteFromEvent: Create Meeting Note: " & theFQFN)
		set content to my createContentForMeetingNote(theEventInfo, theEventAttendees)
		do shell script "echo " & quoted form of content & " > \"" & theFQFN & "\""
		if pRemoveCallInBlock then
			my removeCallInBlock(theFQFN)
		end if
	end if
	my writeLog("createNoteFromEvent: Finished")
	return theFQFN
end createNoteFromEvent

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
	do shell script "sed -i '' -e \"" & sedParameter & "\" \"" & (theFile as string) & "\""

	my writeLog("removeCallInBlock: Finished")
end removeCallInBlock

on createContentForMeetingNote(theEventInfo, theEventAttendees)
	my writeLog("createContentForMeetingNote: Started")
	set theChair to "n/a"
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

	set theTasks to "- [ ] Notes erstellen bis: 🗓️" & theDay & linefeed
	if theChair is not null and theChair contains pLastname then
		set theTasks to theTasks & "- [ ] Protokoll verteilen bis: 🗓️" & theDay
	end if
	set content to fm
	set content to content & pMeetingNoteHeading & linefeed ¬
		& "# Todos" & linefeed & linefeed ¬
		& theTasks & linefeed ¬
		& "# Termin" & linefeed & linefeed ¬
		& "- Summary: " & theSummary & linefeed ¬
		& "- Date: " & theTime & linefeed ¬
		& theTeilnehmer & linefeed ¬
		& "**fett:** anwesend" & linefeed ¬
		& "### Description " & linefeed & linefeed & (event_description of theEventInfo as string) & linefeed ¬
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
	-- my writeLog("formatASDate: Started")

	set {year:y, month:m, day:d, hours:h, minutes:min} to theDate
	set min_str to text -1 thru -2 of ("00" & min)
	set hours_str to text -1 thru -2 of ("00" & h)
	set day_str to text -1 thru -2 of ("00" & d)
	set mon_str to text -1 thru -2 of ("00" & (m * 1))
	set theNormalizedDateAsString to y & "-" & mon_str & "-" & day_str & " " & hours_str & ":" & min_str
	-- my writeLog("formatASDate: theDateAsString: " & theNormalizedDateAsString)

	set theFormatedDateAsString to do shell script "/opt/homebrew/bin/gdate -d\"" & theNormalizedDateAsString & "\"  +\"" & theFormat & "\" "
	-- my writeLog("formatASDate: Finished theFormatedDateAsString: " & theFormatedDateAsString)

	-- my writeLog("formatASDate: Finished")
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
	set msg to timestamp & ": " & pScriptName & ": " & theMessage
	do shell script "echo " & quoted form of msg & " >> " & pLogFile
end writeLog

