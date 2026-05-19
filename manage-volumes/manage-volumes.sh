#!/bin/bash
# =============================================================================
# manage-volumes.sh
# Mountet oder unmountet Volumes anhand ihrer Partition-UUIDs.
# Aufruf via macOS Shortcuts → "Shell-Skript ausführen"
#
# Einrichtung:
#   1. Volumes unten eintragen (siehe Kommentar weiter unten)
#   2. Skript ausführbar machen: chmod +x manage-volumes.sh
#   3. In Shortcuts: Neue Kurzbefehl → Aktion "Shell-Skript ausführen"
#      → Pfad zu diesem Skript eintragen
#      Optional: Argument "mount", "unmount" oder leer für Toggle
# =============================================================================

# =============================================================================
# KONFIGURATION – hier deine Volumes eintragen
# Format:
#   "UUID:Anzeigename:plain"
#   "UUID:Anzeigename:apfs_encrypted:KeychainService"
#
# UUID herausfinden:
#   diskutil info /dev/disk2s1 | grep "Volume UUID"
#
# Fuer `plain` nutzt das Skript `diskutil mount` bzw. `diskutil unmount`.
# Fuer `apfs_encrypted` liest das Skript die Passphrase aus dem macOS-
# Schlüsselbund und ruft `sudo diskutil apfs unlockVolume` bzw.
# `sudo diskutil apfs lockVolume` auf.
# =============================================================================
VOLUMES=(
  "71A539BF-E5C7-483F-BCFD-5FE233F13AFD:Time Machine:apfs_encrypted:tm-volume-TimeMachine"
)
#   "7E9C8F9D-4D21-3A93-BB78-795B3A37F358:Data:plain"

# =============================================================================
# Modus bestimmen
# Kein Argument → Toggle (Standard)
# Argument "mount"   → alle mounten
# Argument "unmount" → alle unmounten
# =============================================================================
MODE="${1:-toggle}"
DISKUTIL="/usr/sbin/diskutil"
SECURITY="/usr/bin/security"
SUDO="/usr/bin/sudo"

# =============================================================================
# Logging – Ausgabe landet in Shortcuts als Ergebnis des Skripts
# =============================================================================
log() {
  echo "$1"
}

# =============================================================================
# Hilfsfunktionen
# =============================================================================
volume_exists() {
  local uuid="$1"
  "$DISKUTIL" info "$uuid" &>/dev/null
}

is_mounted() {
  local uuid="$1"
  "$DISKUTIL" info "$uuid" 2>/dev/null | grep -q "Mounted:.*Yes"
}

mount_plain_volume() {
  local uuid="$1"
  local name="$2"
  local result

  if is_mounted "$uuid"; then
    log "✅ $name – bereits gemountet"
    return 0
  fi

  result=$("$DISKUTIL" mount "$uuid" 2>&1)
  if [ $? -eq 0 ]; then
    log "💾 $name – gemountet"
    return 0
  fi

  log "❌ $name – Fehler beim Mounten: $result"
  return 1
}

unmount_plain_volume() {
  local uuid="$1"
  local name="$2"
  local result

  if ! is_mounted "$uuid"; then
    log "✅ $name – bereits unmountet"
    return 0
  fi

  result=$("$DISKUTIL" unmount "$uuid" 2>&1)
  if [ $? -eq 0 ]; then
    log "⏏  $name – unmountet"
    return 0
  fi

  log "❌ $name – Fehler beim Unmounten (Platte in Benutzung?): $result"
  return 1
}

mount_apfs_encrypted_volume() {
  local uuid="$1"
  local name="$2"
  local keychain_service="$3"
  local passphrase
  local result

  if [ -z "$keychain_service" ]; then
    log "❌ $name – Konfigurationsfehler: Keychain-Service fehlt"
    return 1
  fi

  if is_mounted "$uuid"; then
    log "✅ $name – bereits entsperrt und gemountet"
    return 0
  fi

  passphrase=$("$SECURITY" find-generic-password -a "$USER" -s "$keychain_service" -w 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$passphrase" ]; then
    # Fallback: manche Eintraege haben keinen oder einen abweichenden Account-Namen.
    passphrase=$("$SECURITY" find-generic-password -s "$keychain_service" -w 2>/dev/null)
  fi

  if [ $? -ne 0 ] || [ -z "$passphrase" ]; then
    log "❌ $name – Passphrase nicht im Schlüsselbund gefunden (Service: $keychain_service, Account: $USER)"
    return 1
  fi

  result=$(printf '%s' "$passphrase" | "$SUDO" -n "$DISKUTIL" apfs unlockVolume "$uuid" -stdinpassphrase 2>&1)
  unset passphrase

  if [ $? -eq 0 ]; then
    log "💾 $name – entsperrt und gemountet"
    return 0
  fi

  if printf '%s' "$result" | grep -qi "password is required"; then
    log "❌ $name – sudoers-Freigabe fuer 'diskutil apfs unlockVolume $uuid -stdinpassphrase' fehlt oder passt nicht"
  else
    log "❌ $name – Fehler beim Entsperren: $result"
  fi
  return 1
}

unmount_apfs_encrypted_volume() {
  local uuid="$1"
  local name="$2"
  local result

  if ! is_mounted "$uuid"; then
    log "✅ $name – bereits unmountet"
    return 0
  fi

  result=$("$SUDO" -n "$DISKUTIL" apfs lockVolume "$uuid" 2>&1)
  if [ $? -eq 0 ]; then
    log "⏏  $name – unmountet und gesperrt"
    return 0
  fi

  if printf '%s' "$result" | grep -qi "password is required"; then
    log "❌ $name – sudoers-Freigabe fuer 'diskutil apfs lockVolume $uuid' fehlt oder passt nicht"
  else
    log "❌ $name – Fehler beim Sperren: $result"
  fi
  return 1
}

perform_action() {
  local uuid="$1"
  local name="$2"
  local kind="$3"
  local keychain_service="$4"
  local action="$5"

  case "$kind" in
    plain)
      if [ "$action" = "mount" ]; then
        mount_plain_volume "$uuid" "$name"
      else
        unmount_plain_volume "$uuid" "$name"
      fi
      ;;
    apfs_encrypted)
      if [ "$action" = "mount" ]; then
        mount_apfs_encrypted_volume "$uuid" "$name" "$keychain_service"
      else
        unmount_apfs_encrypted_volume "$uuid" "$name"
      fi
      ;;
    *)
      log "❌ $name – Konfigurationsfehler: Unbekannter Volume-Typ '$kind'"
      return 1
      ;;
  esac
}

# =============================================================================
# Hauptlogik
# =============================================================================
SUCCESS=0
FAILED=0

if [ "$MODE" != "toggle" ] && [ "$MODE" != "mount" ] && [ "$MODE" != "unmount" ]; then
  log "❌ Ungueltiger Modus: $MODE"
  log "Erlaubt sind: mount, unmount, toggle"
  exit 1
fi

for entry in "${VOLUMES[@]}"; do
  IFS=':' read -r UUID NAME KIND KEYCHAIN_SERVICE <<<"$entry"
  KIND="${KIND:-plain}"

  # Prüfen ob UUID überhaupt bekannt ist (Platte angeschlossen?)
  if ! volume_exists "$UUID"; then
    log "⚠️  $NAME – nicht gefunden (Platte angeschlossen?)"
    ((FAILED++))
    continue
  fi

  if [ "$MODE" = "mount" ]; then
    ACTION="mount"
  elif [ "$MODE" = "unmount" ]; then
    ACTION="unmount"
  else
    # Toggle: gemountet → unmount, nicht gemountet → mount
    if is_mounted "$UUID"; then
      ACTION="unmount"
    else
      ACTION="mount"
    fi
  fi

  if perform_action "$UUID" "$NAME" "$KIND" "$KEYCHAIN_SERVICE" "$ACTION"; then
    ((SUCCESS++))
  else
    ((FAILED++))
  fi

done

# =============================================================================
# Zusammenfassung
# =============================================================================
echo ""
echo "──────────────────────────────"
if [ $FAILED -eq 0 ]; then
  echo "✅ Fertig – $SUCCESS Operation(en) erfolgreich."
else
  echo "⚠️  Fertig – $SUCCESS erfolgreich, $FAILED Fehler."
fi
