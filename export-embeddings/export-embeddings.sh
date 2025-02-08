#!/usr/bin/env bash

zkExport="$1" # "/Users/steffen/Downloads/Zk-Export"
zkNote="$2"   # "Output/xxx/yyy.md"

dirExport="attachments"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

mdFile="$zkExport/$zkNote"
zkPath=${zkNote%/*}

echo "$timestamp: Input Parameter: zkExport: $zkExport"
echo "$timestamp: Input Parameter: zkNote: $zkNote"
echo "$timestamp: mdFile: $mdFile"
echo "$timestamp: zkPath: $zkPath"

# attachmentFullQualified=$(grep -Eo "\(file:///.*\)" "$mdFile" | cut -c 9- | rev | cut -c 2- | rev)
for matchedLink in $(grep -Eo "\(file:///.*\)" "$mdFile" | cut -c 9- | rev | cut -c 2- | rev); do
    
	matchedFilename=$(echo $matchedLink | awk -F '/' '{print $NF}')
	if ! [ -d "$zkExport/$zkPath/attachments" ] ; then
		mkdir "$zkExport/$zkPath/attachments"
	fi
	replacedWith="$dirExport/$matchedFilename"
	echo "$timestamp: matchedLink: $matchedLink"
	echo "$timestamp: replacedWith: $replacedWith"

	$(cp $matchedLink $zkExport/$zkPath/$dirExport)
	sed -i -E "s#file://"$matchedLink"#"$replacedWith"#g" "$mdFile"

done
