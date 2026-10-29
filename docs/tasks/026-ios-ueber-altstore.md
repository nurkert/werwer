# Task 026 – iPhone-App über AltStore Classic

Status: umgesetzt, wartet auf das erste Release mit `.ipa` (2026-10-29)

Ohne Apple-Entwickler-Account kommt die iPhone-App über **AltStore Classic**: Jeder Spieler signiert sie auf seinem Gerät mit seiner eigenen Apple-ID. Wir stellen nur zwei Dateien öffentlich bereit, die `.ipa` und eine „Source“ (`https://whowolf.de/altstore.json`). AltStore liest die Source selbst, eine Anmeldung oder Prüfung bei AltStore gibt es nicht. AltStore PAL (EU-Marktplatz) braucht Notarisierung durch Apple und damit den bezahlten Account; das kommt mit TestFlight.

## Ablauf, vollautomatisch

1. Release-Tag → `prerelease.yml` baut iOS unsigniert (`flutter build ios --no-codesign`), und `tool/package_ipa.sh` packt daraus `whowolf-<version>-ios.ipa` (reproduzierbar: feste Zeitstempel) und `whowolf-<version>-ios-altstore.json`.
2. Die Begleitdatei liest alles, was AltStore prüft, **aus der gebauten App**: Bundle-ID, Version, Build-Nummer, mindestens iOS, Entitlements (unsigniert: keine) und alle `NS…UsageDescription`-Texte. So kann die Source nie etwas anderes versprechen, als in der `.ipa` steckt; AltStore verweigert sonst die Installation.
3. Beide Dateien bekommen wie alle Release-Dateien Prüfsumme (`SHA256SUMS.txt`) und Build-Attestation.
4. Das Release löst den Website-Build aus (`website.yml`, `release: published`). `website/src/pages/altstore.json.ts` liest die Releases, nimmt jede Version mit `.ipa` und passender Begleitdatei (neueste zuerst) und schreibt die Source. AltStore zeigt Updates danach von selbst.

## Checkliste

- [x] `tool/package_ipa.sh`, lokal geprüft (0.2.1+77: 52 MB, Kamera- und WLAN-Text, keine Entitlements)
- [x] iOS-Build im Release packt `.ipa` und Begleitdatei und lädt sie hoch
- [x] `whowolf.de/altstore.json` aus den Releases, ohne passende Version eine leere, gültige Source
- [x] Download-Seite (de/en): Knopf „In AltStore hinzufügen“ (`altstore://source?url=…`), die Adresse zum Abtippen, Schritte außerhalb von AltStore (AltServer einrichten mit Link auf die AltStore-Anleitung für Mac und Windows, Entwicklermodus ab iOS 16, 7-Tage-Erneuerung) und der Browser als Alternative
- [x] Spieleranleitung „Was ihr braucht“: iPhone im Browser oder über AltStore
- [ ] Erstes Release mit `.ipa` beobachten: Source auf whowolf.de prüfen, in AltStore hinzufügen und auf einem echten iPhone installieren (mit dem Eigentümer)
  - 0.2.1 (Run 40831013166): `.ipa` (52 MB) und Begleitdatei im Release, whowolf.de/altstore.json listet 0.2.1+18. Auf dem iPhone des Eigentümers liest AltStore die Source, zeigt Whowolf mit Icon und lädt die `.ipa`; die Installation scheiterte nur an „AltServer could not be found“ (kein AltServer auf seinem Mac). Offen: Installation mit laufendem AltServer.
- [ ] Prüfen, ob AltStore den Link `altstore://source?url=…` öffnet (aus der Doku nicht eindeutig; sonst bleibt die Adresse zum Abtippen)

## Grenzen

- Die Spieler brauchen einmal AltServer auf einem Mac oder PC; mit einer kostenlosen Apple-ID läuft die App 7 Tage und wird von AltStore erneuert, höchstens 3 solcher Apps gleichzeitig.
- AltStore ersetzt die Bundle-ID durch eine eigene pro Apple-ID. Universal Links gehen so nicht (brauchen den Account); der QR-Code öffnet mit der Kamera weiter den Browser, der Scanner in der App geht wie gewohnt.

## Sicherheit

- **Was schiefgehen kann:** Jemand schiebt eine veränderte `.ipa` oder Source unter; die Source verschweigt Berechtigungen; eine kaputte Begleitdatei bricht die Source oder schleust Text ein.
- **Was das verhindert:** `.ipa` und Begleitdatei entstehen nur im Release-Workflow, liegen bei GitHub mit Prüfsumme und Attestation (`gh attestation verify <datei> --repo nurkert/whowolf`); die Source kommt per HTTPS von whowolf.de und wird nur in `website.yml` gebaut. AltStore vergleicht die Berechtigungen der Source mit der `.ipa` und installiert bei Abweichung nicht; die Berechtigungen stammen aus der gebauten App. Die Website prüft jede Begleitdatei (Bundle-ID, Versionsformat, Build-Nummer, Typen) und lässt eine fehlerhafte Version weg; die Version muss zum Release-Tag passen. Die App läuft auf dem iPhone in Apples Sandbox wie jede andere, signiert mit der Apple-ID des Spielers; es gibt keine neuen Rechte, keine neue Abhängigkeit und keine Daten an AltStore.
- **Welcher Test es zeigt:** Der Release-Workflow bricht ab, wenn `package_ipa.sh` scheitert (kein `Info.plist`, Paketierung). Die Prüfung der Begleitdatei auf der Website hat keinen eigenen automatischen Test (die Website hat noch keine Testumgebung); AltStores eigener Abgleich mit der `.ipa` ist die zweite Hürde. Offen: ein Test der Website-Prüfung, sobald die Website Tests bekommt.
