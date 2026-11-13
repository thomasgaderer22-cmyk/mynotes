# MyNotes – Start in 3 Schritten (Windows)

1. ZIP entpacken, z. B. nach `C:\Users\<du>\mynotes-src`
   (Pfad ohne Leerzeichen/Umlaute, nicht in OneDrive/Nextcloud – der Rust-Build erzeugt ~10 GB).
2. PowerShell im Ordner öffnen und ausführen:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup-and-build-mynotes.ps1
   ```
   Installiert fehlende Build-Tools per winget (Git, Node, Rust, CMake, LLVM, VS Build Tools – alles kostenlos,
   einmalig Admin-Bestätigung) und baut den Installer. Erster Build: 15–40 min.
   Bricht es nach der Tool-Installation ab: **neues** PowerShell-Fenster, Skript nochmal starten.
3. Installer aus `target\release\bundle\nsis\MyNotes_0.4.1_x64-setup.exe` ausführen.

Nur testen ohne Installer: `... .\setup-and-build-mynotes.ps1 -Dev`
GPU (AMD/Intel/NVIDIA über Vulkan, braucht Vulkan SDK): `-Vulkan`

## Erster Start
- Mikrofon-Berechtigung erlauben (Windows: Einstellungen › Datenschutz › Mikrofon › Desktop-Apps).
- Transkriptionsmodell: Onboarding lädt lokal Parakeet/Whisper herunter (kostenlos, offline).
- Summary-Modell: Standard ist lokal (eingebautes Modell oder Ollama, kostenlos).
  Claude/Groq/OpenRouter/OpenAI sind **kostenpflichtige** Cloud-APIs mit eigenem API-Key – nicht aktiviert.

## Nutzung
- Aufnahme starten (Mic + Systemaudio wählbar) → rechts „My notes“ tippen. Strg+Enter = Zeitstempel.
- Stop → Meeting wird gespeichert, Notizen hängen am Meeting, Summary (Template „MyNotes“) wird erzeugt.
- In der Meeting-Ansicht: Notizen unten links editierbar, Summary editierbar, „Export .md“ → Downloads.
- Suche in der Sidebar durchsucht Titel, Transkripte und eigene Notizen.
