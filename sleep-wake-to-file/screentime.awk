BEGIN { 
    previousEvent = ""; 
    previousTime = ""; 
    currentEvent = ""; 
    currentTime = ""; 
    currentValidEvent = ""; 
    currentValidTime = ""; 
    total=0;
    # print "Begin"
} { 
    currentTime=$2
    currentEvent=$4
    if ( previousEvent == "Wake" && currentEvent == "Wake" ) {
    } else {
        currentValidTime=$2
        currentValidEvent=$4
        if (currentValidEvent == "Sleep" ) {
            split(previousTime, start, ":"); 
            split(currentValidTime, end, ":"); 

            start_sec = start[1]*3600 + start[2]*60;    
            end_sec = end[1]*3600 + end[2]*60;
            diff = end_sec - start_sec;
            total = total + diff

            hours = int(diff / 3600);
            minutes = int((diff % 3600) / 60);            
            
            printf previousTime " - " currentValidTime ": %02d:%02d\n", hours, minutes;

        }
        previousTime=currentValidTime; 
        previousEvent=currentValidEvent; 
    } 
} 
END { 
    hours = int(total / 3600);
    minutes = int((total % 3600) / 60);            
    printf "Total Screentime: %02d:%02d\n", hours, minutes;
    print ""
}