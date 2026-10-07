# Todo (später)

- [ ] **Trainer-VM `PSLAB-TRAINER`** ergänzen: eigene Windows-VM für den Trainer (Domänenmitglied, PowerShell 7, VS Code, Domänen-Admin `labadmin` als lokaler Admin), damit Demos nicht auf `DC01` laufen. Terraform: eigene `trainer`-Ressource analog zu `students.tf`, nicht Teil von `student_count`; in `lab.ps1 status/start/stop` und Smoke-Tests aufnehmen.
- [ ] Aufgabentest (`./lab.ps1 test-exercises`) erneut laufen lassen und Ergebnis prüfen (Harness wurde verfeinert, noch nicht ausgeführt).
- [ ] `./lab.ps1 reset-all` im Lab testen, danach `test`.
- [ ] Lebenszyklus komplett durchspielen: `end-of-day` → `start` → `status` (Start nach Auto-Shutdown wurde bereits bestätigt).
- [ ] PR #2 (`powershell-kurs`) mergen; danach Image-Tag in `3kshetzner` auf den `main`-Stand umstellen.
- [ ] Optional: PowerPoint-Export der Folien (aktuell reveal.js).
- [ ] Optional: Historie von `feat/slides-trainer-handbook` bereinigen (früher eingecheckte Plan-Datei, Passwörter sind rotiert).
