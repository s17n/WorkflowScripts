#!/usr/bin/env bash

dirExport="attachments"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

for i in "$@"
do
case $i in
    -e=*|--zk-export=*)
    zkExport="${i#*=}"
    ;;
    -n=*|--zk-note=*)
    zkNote="${i#*=}"
    ;;
    *)
            # unknown option
    ;;
esac
done

if [ "$zkExport" == "" ]; then
	zkExport=$ZETTELKASTEN_EXPORT_DIR
	if [ "$zkExport" == "" ]; then
		echo "$timestamp: Zettelkasten export directory not provided and ZETTELKASTEN_EXPORT_DIR not set."
		exit -1
	fi
fi

if [ "$zkNote" == "" ]; then
	echo "$timestamp: Zettelkasten note not provided."
	exit -1
fi

mdFile="$zkExport/$zkNote"
zkPath=${zkNote%/*}

echo "$timestamp: Zettelkasten Export Directory: $zkExport"
echo "$timestamp: Zettelkasten Note: $zkNote"
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
