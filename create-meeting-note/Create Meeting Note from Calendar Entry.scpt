#@osa-lang:AppleScript
use AppleScript version "2.5"
use framework "Foundation"
use script "CalendarLib EC" version "1.1.5" -- put this at the top of your scripts
use scripting additions

property pScriptName : "Create Meeting Note from Calendar Entry.scpt"

property configFile : load script (POSIX path of (path to home folder) & ".workflowscripts/config.scpt")
property pInboxFolder : pZettelkastenInboxFolder of configFile
property pWorkflowScriptsBaseFolder : pWorkflowScriptsBaseFolder of configFile
property pMeetingNoteTemplateFile : pWorkflowScriptsBaseFolder & "/create-meeting-note/templates/meeting-note.md"
property pLastname : pLastname of configFile
property pOverwriteExistingNoteDefault : pOverwriteExistingNote of configFile
property pLogFile : pWorkflowScriptsBaseFolder & "/create-meeting-note/logs/execution.log"
property pOverwriteExistingNote : true --pOverwriteExistingNoteDefault

on run {}
	my writeLog("run: Started")

	set theDateTime to do shell script "/opt/homebrew/bin/gdate \"+%Y-%m-%d\""
	set theResult to display dialog "Datum zu dem die Meetings aufgelistet werden sollen (Format: YYYY-mm-dd):" buttons {"List Meetings", "Cancel"} default answer theDateTime default button 1

	set theDateTime to text returned of theResult
	if button returned of theResult is "List Meetings" then
		set allEventsOfDayResult to my fetchEventsByDay(theDateTime)
		set theEvents to item 1 of allEventsOfDayResult
		set theListOfEvents to item 2 of allEventsOfDayResult
		if (count of theListOfEvents) is 0 then
			my writeLog("run: No meetings found for day: " & theDateTime)
			display dialog "Keine Meetings fuer " & theDateTime & " gefunden." buttons {"OK"} default button 1
			return
		end if
		set theSelectedEvent to choose from list theListOfEvents
		if theSelectedEvent is not false then
			set theEvent to my getEventByListEntry(theEvents, theSelectedEvent)
			set theFilenameOfMeetingNote to my createNoteFromEvent(theEvent)
			my setClipboard(theEvent)
		end if
	end if

	my writeLog("run: Finished")
end run

on getEventByListEntry(theEvents, theSelectedEvent)
	my writeLog("getEventByListEntry: Started")

	set theEvent to missing value
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
	set theEvent to missing value

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
	set theCalendars to my resolveCalendars(theStore)
	my writeLog("fetchEventsByDay: Searching calendars: " & (count of theCalendars))
	set theEvents to fetch events starting date fetchStartDate ending date fetchEndDate searching cals theCalendars event store theStore

	set theEventsList to {}
	if length of theEvents > 0 then
		repeat with anEvent in theEvents
			set end of theEventsList to my eventEntry(anEvent)
		end repeat
	end if

	my writeLog("fetchEventsByDay: Finished")
	return {theEvents, theEventsList}
end fetchEventsByDay

on resolveCalendars(theStore)
	my writeLog("resolveCalendars: Started")

	set theCalendars to {}
	try
		set theCalendars to fetch calendars {} cal type list {cal exchange, cal cloud, cal local} event store theStore
		if (count of theCalendars) > 0 then
			my writeLog("resolveCalendars: Using Exchange/iCloud/local calendars")
			return theCalendars
		end if
	on error errStr number errorNumber
		my writeLog("resolveCalendars: Preferred calendar lookup failed: " & errorNumber & " - " & errStr)
	end try

	try
		set theCalendars to fetch calendars {} event store theStore
		if (count of theCalendars) > 0 then
			my writeLog("resolveCalendars: Using all available calendars as fallback")
			return theCalendars
		end if
	on error errStr number errorNumber
		my writeLog("resolveCalendars: Generic calendar fallback failed: " & errorNumber & " - " & errStr)
	end try

	error "Kein verwendbarer Kalender gefunden."
end resolveCalendars

on eventEntry(theEvent)
	my writeLog("eventEntry: Started")

	set theEventInfo to event info for event theEvent
	set theEventSummary to (event_summary of theEventInfo as string)
	set theCalendarName to ""
	try
		set theCalendarName to (calendar_name of theEventInfo as string)
	on error
		set theCalendarName to ""
	end try
	set startDate to event_start_date of theEventInfo
	set endDate to event_end_date of theEventInfo

	set startDateAsString to my formatASDate(event_start_date of theEventInfo, "%H:%M")
	set endDateAsString to my formatASDate(event_end_date of theEventInfo, "%H:%M")

	my writeLog("eventEntry: Finished")
	if theCalendarName is "" then
		return (startDateAsString as string) & " - " & (endDateAsString) & ": " & theEventSummary
	end if
	return (startDateAsString as string) & " - " & (endDateAsString) & ": " & theEventSummary & " [" & theCalendarName & "]"
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
	set theEventAttendees to missing value
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
		my writeTextFile(theFQFN, content)
	end if
	my writeLog("createNoteFromEvent: Finished")
	return theFQFN
end createNoteFromEvent

on createContentForMeetingNote(theEventInfo, theEventAttendees)
	my writeLog("createContentForMeetingNote: Started")
	set theChair to "n/a"
	set {content, chairEntry, requiredEntries, optionalEntries, numberTotal, numberAccepted, numberDeclined, numberTentative, numberOther} to {"", "(nicht ermittelbar)", "	- (keine)", "	- (keine)", 0, 0, 0, 0, 0}
	if theEventAttendees is not missing value then
		set theResult to my createAttendeesList(theEventAttendees)
		set chairEntry to chair of theResult
		set requiredEntries to required_entries of theResult
		set optionalEntries to optional_entries of theResult
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

	set theTasks to "- [ ] Notes erstellen bis: 🗓️" & theDay & linefeed
	if theChair is not missing value and theChair contains pLastname then
		set theTasks to theTasks & "- [ ] Protokoll verteilen bis: 🗓️" & theDay
	end if
	set theDescription to ""
	try
		set theDescription to (event_description of theEventInfo as string)
	end try
	set theDescription to my cleanMeetingDescription(theDescription, my getMeetingDescriptionTrimMarkers())
	set content to my renderMeetingNoteTemplate(theDay, theStart, theEnd, numberTotal, numberAccepted, numberDeclined, numberTentative, numberOther, theTasks, theSummary, theTime, chairEntry, requiredEntries, optionalEntries, theDescription)
	my writeLog("createContentForMeetingNote: Finished")
	return content
end createContentForMeetingNote

on renderMeetingNoteTemplate(theDay, theStart, theEnd, numberTotal, numberAccepted, numberDeclined, numberTentative, numberOther, theTasks, theSummary, theTime, chairEntry, requiredEntries, optionalEntries, theDescription)
	my writeLog("renderMeetingNoteTemplate: Started")

	set content to my loadMeetingNoteTemplate()
	set content to my replacePlaceholder(content, "meeting_day", theDay)
	set content to my replacePlaceholder(content, "meeting_start", theStart)
	set content to my replacePlaceholder(content, "meeting_end", theEnd)
	set content to my replacePlaceholder(content, "attendees_total", numberTotal)
	set content to my replacePlaceholder(content, "attendees_accepted", numberAccepted)
	set content to my replacePlaceholder(content, "attendees_declined", numberDeclined)
	set content to my replacePlaceholder(content, "attendees_tentative", numberTentative)
	set content to my replacePlaceholder(content, "attendees_other", numberOther)
	set content to my replacePlaceholder(content, "tasks", theTasks)
	set content to my replacePlaceholder(content, "summary", theSummary)
	set content to my replacePlaceholder(content, "time", theTime)
	set content to my replacePlaceholder(content, "chair", chairEntry)
	set content to my replacePlaceholder(content, "required_attendees", requiredEntries)
	set content to my replacePlaceholder(content, "optional_attendees", optionalEntries)
	set content to my replacePlaceholder(content, "description", theDescription)

	my writeLog("renderMeetingNoteTemplate: Finished")
	return content
end renderMeetingNoteTemplate

on loadMeetingNoteTemplate()
	my writeLog("loadMeetingNoteTemplate: Started")

	if not my FileExists(pMeetingNoteTemplateFile) then
		error "Template file not found: " & pMeetingNoteTemplateFile
	end if

	set templateContent to do shell script "cat " & quoted form of pMeetingNoteTemplateFile
	my writeLog("loadMeetingNoteTemplate: Finished")
	return templateContent
end loadMeetingNoteTemplate

on getMeetingDescriptionTrimMarkers()
	try
		return pMeetingDescriptionTrimMarkers of configFile
	on error
		return {}
	end try
end getMeetingDescriptionTrimMarkers

on cleanMeetingDescription(theDescription, trimMarkers)
	my writeLog("cleanMeetingDescription: Started")

	if theDescription is missing value then return ""
	set cleanedDescription to theDescription as string
	if trimMarkers is missing value then
		set cleanedDescription to my trimTrailingWhitespace(cleanedDescription)
		my writeLog("cleanMeetingDescription: Finished - no markers configured")
		return cleanedDescription
	end if
	if (count of trimMarkers) is 0 then
		set cleanedDescription to my trimTrailingWhitespace(cleanedDescription)
		my writeLog("cleanMeetingDescription: Finished - empty marker list")
		return cleanedDescription
	end if

	set nsDescription to current application's NSString's stringWithString:cleanedDescription
	set firstMarkerLocation to missing value

	repeat with marker in trimMarkers
		set markerText to marker as string
		if markerText is not "" then
			set foundRange to (nsDescription's rangeOfString:markerText options:(current application's NSCaseInsensitiveSearch))
			set foundLocation to foundRange's location() as integer
			if foundLocation is not (current application's NSNotFound) then
				if firstMarkerLocation is missing value or foundLocation < firstMarkerLocation then
					set firstMarkerLocation to foundLocation
				end if
			end if
		end if
	end repeat

	if firstMarkerLocation is not missing value then
		set nsDescription to nsDescription's substringToIndex:firstMarkerLocation
		set cleanedDescription to nsDescription as text
		set cleanedDescription to my trimTrailingSeparatorLines(cleanedDescription)
	else
		set cleanedDescription to nsDescription as text
	end if

	set cleanedDescription to my trimTrailingWhitespace(cleanedDescription)
	my writeLog("cleanMeetingDescription: Finished")
	return cleanedDescription
end cleanMeetingDescription

on trimTrailingSeparatorLines(theText)
	if theText is missing value then return ""

	set NSString to current application's NSString's stringWithString:(theText as string)
	set normalizedText to (NSString's stringByReplacingOccurrencesOfString:(return) withString:(linefeed)) as text
	set oldTIDs to AppleScript's text item delimiters
	set AppleScript's text item delimiters to linefeed
	set textLines to text items of normalizedText

	repeat while (count of textLines) > 0
		set lastLine to item -1 of textLines as string
		set normalizedLastLine to my trimBoundaryWhitespace(lastLine)
		if normalizedLastLine is "" or my isSeparatorLine(normalizedLastLine) then
			if (count of textLines) is 1 then
				set textLines to {}
			else
				set textLines to items 1 thru -2 of textLines
			end if
		else
			exit repeat
		end if
	end repeat

	if (count of textLines) is 0 then
		set cleanedText to ""
	else
		set AppleScript's text item delimiters to linefeed
		set cleanedText to textLines as text
	end if
	set AppleScript's text item delimiters to oldTIDs
	return cleanedText
end trimTrailingSeparatorLines

on trimBoundaryWhitespace(theText)
	set trimmedText to my trimLeadingWhitespace(theText)
	return my trimTrailingWhitespace(trimmedText)
end trimBoundaryWhitespace

on trimLeadingWhitespace(theText)
	if theText is missing value then return ""
	set trimmedText to theText as string
	repeat while trimmedText is not "" and ((trimmedText starts with linefeed) or (trimmedText starts with return) or (trimmedText starts with space) or (trimmedText starts with tab))
		if (length of trimmedText) is 1 then
			set trimmedText to ""
		else
			set trimmedText to text 2 thru -1 of trimmedText
		end if
	end repeat
	return trimmedText
end trimLeadingWhitespace

on trimTrailingWhitespace(theText)
	if theText is missing value then return ""
	set trimmedText to theText as string
	repeat while trimmedText is not "" and ((trimmedText ends with linefeed) or (trimmedText ends with return) or (trimmedText ends with space) or (trimmedText ends with tab))
		if (length of trimmedText) is 1 then
			set trimmedText to ""
		else
			set trimmedText to text 1 thru -2 of trimmedText
		end if
	end repeat
	return trimmedText
end trimTrailingWhitespace

on isSeparatorLine(theText)
	if theText is missing value then return false
	set separatorText to theText as string
	if separatorText is "" then return false
	repeat with i from 1 to length of separatorText
		set currentCharacter to character i of separatorText
		if currentCharacter is not "_" and currentCharacter is not "-" then return false
	end repeat
	return true
end isSeparatorLine

on writeTextFile(theFile, theContent)
	my writeLog("writeTextFile: Started - " & theFile)

	set NSString to current application's NSString's stringWithString:(theContent as string)
	set normalizedString to (NSString's stringByReplacingOccurrencesOfString:(return) withString:(linefeed))
	set {didWrite, writeError} to normalizedString's writeToFile:theFile atomically:true encoding:(current application's NSUTF8StringEncoding) |error|:(reference)
	if not (didWrite as boolean) then
		error (writeError's localizedDescription() as text)
	end if

	my writeLog("writeTextFile: Finished")
end writeTextFile

on replacePlaceholder(theContent, placeholderName, placeholderValue)
	set oldTIDs to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "{{" & placeholderName & "}}"
	set contentItems to text items of theContent
	if placeholderValue is missing value then
		set replacementValue to ""
	else
		set replacementValue to placeholderValue as string
	end if
	set AppleScript's text item delimiters to replacementValue
	set newContent to contentItems as text
	set AppleScript's text item delimiters to oldTIDs
	return newContent
end replacePlaceholder

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

	set number_accepted to 0
	set number_declined to 0
	set number_tentative to 0
	set number_other to 0 -- umfasst to attendee_status: in process, unknown
	set chair to "(nicht ermittelbar)"
	set required_entries to "	- (keine)"
	set optional_entries to "	- (keine)"
	if length of theAttendees > 0 then
		my writeLog("createAttendeesList: Attendees found: " & length of theAttendees)

		set required to {}
		set optional to {}

		repeat with attendee in theAttendees
			set theRole to attendee_role of attendee
			if theRole is "chair" or theRole is "unknown" then
				set chair to attendee_name of attendee
			else if theRole is "required" then
				set end of required to attendee
			else
				set end of optional to attendee
			end if
		end repeat

		set theSublistResult to my createAttendeesSection("- Required: ", required)
		set number_accepted to number_accepted + (number_accepted of theSublistResult)
		set number_declined to number_declined + (number_declined of theSublistResult)
		set number_tentative to number_tentative + (number_tentative of theSublistResult)
		set number_other to number_other + (number_other of theSublistResult)
		set required_entries to entries of theSublistResult

		set theSublistResult to my createAttendeesSection("- Optional: ", optional)
		set number_accepted to number_accepted + (number_accepted of theSublistResult)
		set number_declined to number_declined + (number_declined of theSublistResult)
		set number_tentative to number_tentative + (number_tentative of theSublistResult)
		set number_other to number_other + (number_other of theSublistResult)
		set optional_entries to entries of theSublistResult
	else
		my writeLog("createAttendeesList: No attendees found. ")
	end if
	return {chair:chair, required_entries:required_entries, optional_entries:optional_entries, number_accepted:number_accepted, number_declined:number_declined, number_tentative:number_tentative, number_other:number_other}
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
	set theEntries to ""
	repeat with attendee in accepted
		set theEntries to theEntries & "	- " & attendee_name of attendee & ", " & attendee_status of attendee & linefeed
	end repeat
	repeat with attendee in declined
		set theEntries to theEntries & "	- " & attendee_name of attendee & ", " & attendee_status of attendee & linefeed
	end repeat
	repeat with attendee in tentative
		set theEntries to theEntries & "	- " & attendee_name of attendee & ", " & attendee_status of attendee & linefeed
	end repeat
	repeat with attendee in other
		set theEntries to theEntries & "	- " & attendee_name of attendee & ", " & attendee_status of attendee & linefeed
	end repeat
	if theEntries is "" then
		set theEntries to "	- (keine)"
	else if theEntries ends with linefeed then
		set theEntries to text 1 thru -2 of theEntries
	end if

	my writeLog("createAttendeesSection: Finished")
	return {entries:theEntries, number_accepted:length of accepted, number_declined:length of declined, number_tentative:length of tentative, number_other:length of other}
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
