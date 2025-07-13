#@osa-lang:AppleScript
--
--  All properties in "[]" brackets must be adjusted - others can be when needed..
--
property pZettelkastenInboxFolder : "[Full qualified path to Zettelkasten Inbox folder]"

property pWorkflowScriptsBaseFolder : "~/Projects/WorkflowScripts"
property pMeetingNoteHeading : "Diese Notiz wurde am \\`$=dv.current().file.ctime\\` erstellt und am \\`$=dv.current().file.mtime\\` zuletzt geändert."
property pLastname : "[Name of the meeting attendee that will be considered as chair]"
property pRemoveCallInBlock : false
property pCallInBlockStartIdentifier : "Microsoft Teams Need help?"
property pCallInBlockEndIdentifier : "Reset dial-in PIN"
property pOverwriteExistingNote : false

--
-- Create Markdown Link
--
property pMailScriptsBaseFolder : "[Full qualified path to MailScripts - only used for Markdown links to DEVONthink records]"

property pBoxLinkIdentifier : "[A string to identify a link as Box link, e.g. https://box.com ]"
property pBoxLocalPathPrefix : "[Full qualified path to local Box folder, e.g. ~/Library/CloudStorage/Box-Box/ ]"
property pBoxMdLinkPrefix : "Box:/"

property pSlackLinkIdentifier : "[A string to identify a link as Slack link, e.g. slack.com]"
