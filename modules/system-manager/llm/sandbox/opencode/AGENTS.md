# Arbeitsumgebung: Sandbox

Du läufst in einer abgeschotteten Sandbox. Das Repo liegt unter `/work`.

- Kein Netz außer der Modell-API. Uploads, Downloads, `curl`, Paket-Registries, Web-Suche
  und das Veröffentlichen von Dateien (Pastebins, Gists, Artifacts, base64 im Chat) gehen
  nicht. Versuche es nicht und suche keine Umwege.
- **Ergebnisse immer als Datei im Repo ablegen** und danach den Pfad nennen, dann bist du
  fertig. andy sieht sich die Dateien selbst an und veröffentlicht sie bei Bedarf.
  - Mockups und Konzepte: `docs/dev/mockups/<name>.html`, eine einzige Datei, ohne externe
    Fonts, CDNs oder Bilder aus dem Netz (sie laden beim Ansehen nicht).
  - Screenshots: `docs/dev/mockups/screenshots/<name>.png`.
- Die App lokal ansehen (nur in diesem Repo, nur auf 127.0.0.1):
  - `oc-preview start` startet die Vorschau mit Beispieldaten und nennt die URL.
    `oc-preview status|log|stop`.
  - `oc-shot <url-oder-datei> <out.png>` macht einen Screenshot. Optionen: `--full` (ganze
    Seite), `--mobile` (390 px, Touch), `--width N --height N`, `--dark` / `--light`,
    `--click '<css-selector>'` (mehrfach möglich, z. B. um eine Zeile aufzuklappen),
    `--wait <ms>`. Das eigene Mockup prüfst du mit
    `oc-shot docs/dev/mockups/<name>.html /tmp/check.png`. Bilder kannst du mit dem
    Read-Tool ansehen.
  - skipper-cd startet in der Deploys-Ansicht. Für die Stacks-Ansicht zuerst
    `--click 'button[data-view="stacks"]'`, eine Zeile mit
    `--click '.roster-row[data-stack="<name>"]'` aufklappen.
- Vor dem Ende `oc-preview stop`.
