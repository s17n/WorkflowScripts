# Manage Volumes

Ein kleines Shell-Modul zum Mounten, Unmounten oder Umschalten des Mount-Status vordefinierter Volumes ueber `diskutil`.

Die produktive Laufzeitdatei ist `manage-volumes/manage-volumes.sh`.

Das Skript verwaltet eine Liste von Volume-UUIDs direkt im Quelltext und arbeitet die Eintraege nacheinander ab. Ohne Argument wird fuer jedes konfigurierte Volume der aktuelle Status geprueft und zwischen Mount und Unmount umgeschaltet. Mit `mount` oder `unmount` laesst sich die Aktion explizit vorgeben.

Typischer Einsatz ist ein Aufruf aus macOS Shortcuts ueber "Shell-Skript ausfuehren". Die Ausgabe ist fuer die direkte Rueckgabe in Shortcuts formatiert und meldet pro Volume Erfolg, bereits erreichten Zielzustand oder Fehler.

## Konfiguration

Das Array `VOLUMES` in `manage-volumes/manage-volumes.sh` unterstuetzt zwei Formate:

* `UUID:Anzeigename:plain`
* `UUID:Anzeigename:apfs_encrypted:KeychainService`

Beispiel:

```bash
VOLUMES=(
  "71A539BF-E5C7-483F-BCFD-5FE233F13AFD:Time Machine:apfs_encrypted:tm-volume-TimeMachine"
  "7E9C8F9D-4D21-3A93-BB78-795B3A37F358:Data:plain"
)
```

Der Anzeigename dient nur fuer die Log-Ausgabe. Technisch arbeitet das Skript ueber die UUID.

Die UUID eines Volumes laesst sich zum Beispiel mit `diskutil info /dev/disk2s1 | grep "Volume UUID"` ermitteln.

## Verschluesselte APFS-Volumes

Fuer `apfs_encrypted` liest das Skript die Passphrase aus dem macOS-Schluesselbund und ruft dann `diskutil apfs unlockVolume` ueber `sudo` auf. Damit bei jedem `mount`-Aufruf weder Admin-Passwort noch Volume-Passphrase eingegeben werden muessen, sind zwei Vorarbeiten noetig.

Passphrase einmal im Schluesselbund ablegen:

```bash
security add-generic-password -a "$USER" -s "tm-volume-TimeMachine" -w
```

Das Skript sucht die Passphrase zuerst ueber `Service + Account ($USER)` und faellt danach auf `Service` allein zurueck. Ein abweichender oder leerer Account im Schluesselbund ist also zulaessig, solange der Service-Name eindeutig ist.

Danach eine eng begrenzte `sudoers`-Freigabe mit `visudo` eintragen:

```sudoers
steffen ALL=(root) NOPASSWD: /usr/sbin/diskutil apfs unlockVolume 71A539BF-E5C7-483F-BCFD-5FE233F13AFD -stdinpassphrase
steffen ALL=(root) NOPASSWD: /usr/sbin/diskutil apfs lockVolume 71A539BF-E5C7-483F-BCFD-5FE233F13AFD
```

Die Freigabe ist absichtlich auf genau diese UUID begrenzt. Fuer weitere verschluesselte Volumes ist je UUID ein eigener Eintrag noetig.

## Aufruf

Das Skript kann ohne Argument oder mit `mount` bzw. `unmount` gestartet werden:

```bash
./manage-volumes/manage-volumes.sh
./manage-volumes/manage-volumes.sh mount
./manage-volumes/manage-volumes.sh unmount
```
