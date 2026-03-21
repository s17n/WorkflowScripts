# Nutzerdokumentation

## Zweck

Der Workflow fuegt einen Link automatisch in die passende Obsidian-Notiz ein.

## Was passiert

- Wenn zum Zeitstempel eine passende Meeting-Notiz existiert, wird dort geschrieben.
- Wenn keine Meeting-Notiz passt, wird in die Daily Note des Datums geschrieben.

## Eingaben

Der Workflow erwartet:

- einen Typ, z. B. `Screenshot`
- einen Markdown-Link
- einen Zeitstempel im Format `YYYYMMDD-HHmmss`
- optional ein Inline-Flag

## Ergebnis

Es wird ein Eintrag wie dieser angehaengt:

```md
- Screenshot:: [Titel](https://beispiel.de)
```

Mit Inline-Flag:

```md
- Screenshot:: ![Titel](https://beispiel.de)
```

## Initiales Setup

Vor der ersten Nutzung die virtuelle Python-Umgebung auf Repo-Ebene anlegen:

```sh
cd /Users/steffen/Projects/WorkflowScripts
python3 -m venv .venv
./.venv/bin/python -m pip install --upgrade pip
./.venv/bin/python -m pip install -r add-reference-to-note/requirements.txt
```

Danach kann das Script ueber `./.venv/bin/python` gestartet werden.

## Direkter Python-Aufruf

Beispiel:

```sh
./.venv/bin/python add-reference-to-note/add-reference-to-note.py \
  --meeting-root="/Pfad/zu/Meetings" \
  --daily-root="/Pfad/zu/Journal" \
  --timestamp="20260321-081500" \
  --entry="- Screenshot:: [Google](https://www.google.com)"
```

Direkt in die Daily Note schreiben:

```sh
./.venv/bin/python add-reference-to-note/add-reference-to-note.py \
  --daily-only \
  --daily-root="/Pfad/zu/Journal" \
  --timestamp="20260321-081500" \
  --entry="- Screenshot:: [Google](https://www.google.com)"
```

## Fehlerbilder

- Kein Eintrag sichtbar:
  Es wurde wahrscheinlich in die Daily Note oder in eine andere Meeting-Notiz geschrieben als erwartet.
- Python startet nicht:
  Die `.venv` oder `python-frontmatter` fehlt.
- Schreiben scheitert:
  Es fehlen Schreibrechte auf die Obsidian-Dateien.

## Logfile

Zur Fehlersuche:

- `/Users/steffen/Projects/WorkflowScripts/logs/execution.log`
