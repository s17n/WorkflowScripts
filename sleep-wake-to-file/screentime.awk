BEGIN {
    # output=kv -> machine-readable key=value output, sonst Human-Output.
    outputMode = (output == "" ? "human" : output);

    # Awake-Session-Metriken (Wake -> Sleep).
    awakeTotalSec = 0;
    hasOpenAwake = 0;
    awakeStartTime = "";
    awakeSessionCount = 0;
    earliestAwakeStartSec = -1;
    latestAwakeEndSec = -1;
    earliestAwakeStartTime = "-";
    latestAwakeEndTime = "-";

    # Screen-Metriken (Display on -> Display off).
    screenTotalSec = 0;
    hasOpenScreen = 0;
    screenStartTime = "";
    screenSessionCount = 0;
    firstScreenOnSec = -1;
    lastScreenOffSec = -1;
    firstScreenOnTime = "-";
    lastScreenOffTime = "-";

    # Defaults fuer Tageszusammenfassung, werden bei vorhandenen Sessions ueberschrieben.
    worktimeSec = 0;
    breakTimeText = "00:00";
    plausibility = "n/a (keine Sessions)";
}

# ---------- Allgemeine Helfer ----------
function toSeconds(timeValue, parts) {
    split(timeValue, parts, ":");
    return parts[1] * 3600 + parts[2] * 60 + parts[3];
}

function formatDuration(durationSec, hours, minutes) {
    hours = int(durationSec / 3600);
    minutes = int((durationSec % 3600) / 60);
    return sprintf("%02d:%02d", hours, minutes);
}

# ---------- Erkennungslogik fuer Ereignisse ----------
function isVisibleWakeLine(line) {
    # Nur echte, benutzersichtbare Wake-Uebergaenge zaehlen.
    return (line ~ /Wake from Deep Idle/ || line ~ /DarkWake to FullWake from Deep Idle/);
}

function isIgnoredMaintenanceSleep(line) {
    return (line ~ /'Maintenance Sleep'/ || line ~ /'Sleep Service Back to Sleep'/);
}

function shouldCloseAwakeSession(line) {
    # Idle Sleep beendet eine sichtbare Session.
    if (line ~ /Entering DarkWake state due to 'Idle Sleep'/) {
        return 1;
    }

    # Allgemeines Sleep-Ende, ausser technische Maintenance-Zyklen.
    if (line ~ /Entering Sleep state due to '/ && !isIgnoredMaintenanceSleep(line)) {
        return 1;
    }
    return 0;
}

function isDisplayOnLine(line) {
    return (line ~ /Display is turned on/);
}

function isDisplayOffLine(line) {
    return (line ~ /Display is turned off/);
}

# ---------- Awake-Session-Handling ----------
function openAwakeSession(timeValue) {
    if (!hasOpenAwake) {
        awakeStartTime = timeValue;
        hasOpenAwake = 1;
    }
}

function closeAwakeSession(timeValue, startSec, stopSec, diff, hours, minutes) {
    if (!hasOpenAwake) {
        return;
    }

    startSec = toSeconds(awakeStartTime);
    stopSec = toSeconds(timeValue);
    diff = stopSec - startSec;

    # Schutz gegen fehlerhafte Reihenfolge im Input.
    if (diff < 0) {
        hasOpenAwake = 0;
        return;
    }

    awakeTotalSec += diff;
    if (awakeSessionCount == 0 || startSec < earliestAwakeStartSec) {
        earliestAwakeStartSec = startSec;
        earliestAwakeStartTime = awakeStartTime;
    }
    if (awakeSessionCount == 0 || stopSec > latestAwakeEndSec) {
        latestAwakeEndSec = stopSec;
        latestAwakeEndTime = timeValue;
    }
    awakeSessionCount += 1;

    # Detaillierte Session-Zeilen nur im Human-Modus ausgeben.
    if (outputMode != "kv") {
        hours = int(diff / 3600);
        minutes = int((diff % 3600) / 60);
        printf "%s - %s: %02d:%02d\n", awakeStartTime, timeValue, hours, minutes;
    }

    hasOpenAwake = 0;
}

function handleWakeEvent(timeValue, line) {
    if (isVisibleWakeLine(line)) {
        openAwakeSession(timeValue);
    }
}

function handleSleepEvent(timeValue, line) {
    if (shouldCloseAwakeSession(line)) {
        closeAwakeSession(timeValue);
    }
}

# ---------- Screen-Session-Handling ----------
function openScreenSession(timeValue) {
    # Doppeltes "Display on" wird ignoriert, solange eine Session offen ist.
    if (!hasOpenScreen) {
        screenStartTime = timeValue;
        hasOpenScreen = 1;
    }
}

function closeScreenSession(timeValue, startSec, stopSec, diff) {
    if (!hasOpenScreen) {
        return;
    }

    startSec = toSeconds(screenStartTime);
    stopSec = toSeconds(timeValue);
    diff = stopSec - startSec;

    if (diff < 0) {
        hasOpenScreen = 0;
        return;
    }

    screenTotalSec += diff;
    if (screenSessionCount == 0 || startSec < firstScreenOnSec) {
        firstScreenOnSec = startSec;
        firstScreenOnTime = screenStartTime;
    }
    if (screenSessionCount == 0 || stopSec > lastScreenOffSec) {
        lastScreenOffSec = stopSec;
        lastScreenOffTime = timeValue;
    }
    screenSessionCount += 1;
    hasOpenScreen = 0;
}

function handleNotificationEvent(timeValue, line) {
    if (isDisplayOnLine(line)) {
        openScreenSession(timeValue);
        return;
    }
    if (isDisplayOffLine(line)) {
        closeScreenSession(timeValue);
    }
}

# ---------- Ausgabe ----------
function computeAwakeDaySummary(breakSec) {
    if (awakeSessionCount <= 0) {
        return;
    }

    worktimeSec = latestAwakeEndSec - earliestAwakeStartSec;
    if (worktimeSec < 0) {
        worktimeSec = 0;
    }

    breakSec = worktimeSec - awakeTotalSec;
    if (breakSec < 0) {
        breakTimeText = "-" formatDuration(-breakSec);
        plausibility = "WARN (awakeSessionTime > duration)";
    } else {
        breakTimeText = formatDuration(breakSec);
        plausibility = "OK";
    }
}

function printKvOutput(awakeTotalText, screenTotalText) {
    if (awakeSessionCount > 0) {
        print "firstOn=" earliestAwakeStartTime;
        print "lastOff=" latestAwakeEndTime;
        print "duration=" formatDuration(worktimeSec);
        print "durationOff=" breakTimeText;
        print "awakeSessionTime=" awakeTotalText;
        print "session_count=" awakeSessionCount;
        print "plausibility=" plausibility;
    } else {
        print "firstOn=-";
        print "lastOff=-";
        print "duration=00:00";
        print "durationOff=00:00";
        print "awakeSessionTime=00:00";
        print "session_count=0";
        print "plausibility=n/a (keine Sessions)";
    }

    if (screenSessionCount > 0) {
        print "screenTime=" screenTotalText;
        print "firstScreenOn=" firstScreenOnTime;
        print "lastScreenOff=" lastScreenOffTime;
        print "screen_session_count=" screenSessionCount;
    } else {
        print "screenTime=00:00";
        print "firstScreenOn=-";
        print "lastScreenOff=-";
        print "screen_session_count=0";
    }
}

function printHumanOutput(awakeTotalText, screenTotalText) {
    printf "awakeSessionTime: %s\n", awakeTotalText;
    printf "screenTime: %s\n", screenTotalText;

    if (awakeSessionCount > 0) {
        printf "firstOn: %s\n", earliestAwakeStartTime;
        printf "lastOff: %s\n", latestAwakeEndTime;
        printf "duration: %s\n", formatDuration(worktimeSec);
        printf "durationOff: %s\n", breakTimeText;
        printf "Plausibility: %s\n", plausibility;
    } else {
        print "firstOn: -";
        print "lastOff: -";
        print "duration: 00:00";
        print "durationOff: 00:00";
        print "Plausibility: n/a (keine Sessions)";
    }

    print "";
}

{
    currentTime = $2;
    currentEvent = $4;

    if (currentEvent == "Wake") {
        handleWakeEvent(currentTime, $0);
        next;
    }

    if (currentEvent == "Sleep") {
        handleSleepEvent(currentTime, $0);
        next;
    }

    if (currentEvent == "Notification") {
        handleNotificationEvent(currentTime, $0);
        next;
    }
}

END {
    awakeTotalText = formatDuration(awakeTotalSec);
    screenTotalText = formatDuration(screenTotalSec);
    computeAwakeDaySummary();

    if (outputMode == "kv") {
        printKvOutput(awakeTotalText, screenTotalText);
    } else {
        printHumanOutput(awakeTotalText, screenTotalText);
    }
}
