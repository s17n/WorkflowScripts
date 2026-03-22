BEGIN {
    outputMode = (output == "" ? "human" : output);
    total = 0;
    hasOpenWake = 0;
    wakeTime = "";
    sessionCount = 0;
    earliestStartSec = -1;
    latestEndSec = -1;
    earliestStartTime = "-";
    latestEndTime = "-";
}

function toSeconds(timeValue, parts) {
    split(timeValue, parts, ":");
    return parts[1] * 3600 + parts[2] * 60 + parts[3];
}

function formatDuration(durationSec, hours, minutes) {
    hours = int(durationSec / 3600);
    minutes = int((durationSec % 3600) / 60);
    return sprintf("%02d:%02d", hours, minutes);
}

function openSession(timeValue) {
    if (!hasOpenWake) {
        wakeTime = timeValue;
        hasOpenWake = 1;
    }
}

function closeSession(timeValue, startSec, stopSec, diff, hours, minutes) {
    if (!hasOpenWake) {
        return;
    }

    startSec = toSeconds(wakeTime);
    stopSec = toSeconds(timeValue);
    diff = stopSec - startSec;

    if (diff < 0) {
        hasOpenWake = 0;
        return;
    }

    total += diff;
    if (sessionCount == 0 || startSec < earliestStartSec) {
        earliestStartSec = startSec;
        earliestStartTime = wakeTime;
    }
    if (sessionCount == 0 || stopSec > latestEndSec) {
        latestEndSec = stopSec;
        latestEndTime = timeValue;
    }
    sessionCount += 1;

    if (outputMode != "kv") {
        hours = int(diff / 3600);
        minutes = int((diff % 3600) / 60);
        printf "%s - %s: %02d:%02d\n", wakeTime, timeValue, hours, minutes;
    }

    hasOpenWake = 0;
}

{
    currentTime = $2;
    currentEvent = $4;

    if (currentEvent == "Wake") {
        # Count only transitions to a full, user-visible wake state.
        if ($0 ~ /Wake from Deep Idle/ || $0 ~ /DarkWake to FullWake from Deep Idle/) {
            openSession(currentTime);
        }
        next;
    }

    if (currentEvent == "Sleep") {
        # End a visible session at Idle/Clamshell or any non-maintenance sleep cause.
        if ($0 ~ /Entering DarkWake state due to 'Idle Sleep'/) {
            closeSession(currentTime);
            next;
        }

        if ($0 ~ /Entering Sleep state due to '/) {
            if ($0 ~ /'Maintenance Sleep'/ || $0 ~ /'Sleep Service Back to Sleep'/) {
                next;
            }
            closeSession(currentTime);
            next;
        }
    }
}
END {
    totalText = formatDuration(total);

    if (sessionCount > 0) {
        worktimeSec = latestEndSec - earliestStartSec;
        if (worktimeSec < 0) {
            worktimeSec = 0;
        }
        breakSec = worktimeSec - total;

        if (breakSec < 0) {
            breakTimeText = "-" formatDuration(-breakSec);
            plausibility = "WARN (screentime > duration)";
        } else {
            breakTimeText = formatDuration(breakSec);
            plausibility = "OK";
        }
    }

    if (outputMode == "kv") {
        if (sessionCount > 0) {
            print "first_screen_on=" earliestStartTime;
            print "last_screen_off=" latestEndTime;
            print "duration=" formatDuration(worktimeSec);
            print "duration_off_screentime=" breakTimeText;
            print "screentime=" totalText;
            print "session_count=" sessionCount;
            print "plausibility=" plausibility;
        } else {
            print "first_screen_on=-";
            print "last_screen_off=-";
            print "duration=00:00";
            print "duration_off_screentime=00:00";
            print "screentime=00:00";
            print "session_count=0";
            print "plausibility=n/a (keine Sessions)";
        }
    } else {
        printf "Screentime: %s\n", totalText;

        if (sessionCount > 0) {
            printf "first_screen_on: %s\n", earliestStartTime;
            printf "last_screen_off: %s\n", latestEndTime;
            printf "duration: %s\n", formatDuration(worktimeSec);
            printf "duration_off_screentime: %s\n", breakTimeText;
            printf "Plausibility: %s\n", plausibility;
        } else {
            print "first_screen_on: -";
            print "last_screen_off: -";
            print "duration: 00:00";
            print "duration_off_screentime: 00:00";
            print "Plausibility: n/a (keine Sessions)";
        }

        print "";
    }
}
