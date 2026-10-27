# Task 014 – Offene Prüfungen

**Status:** in Arbeit (2026-10-27)
**Bezug:** [Task 013](013-feinschliff-abend.md)

Alle Wünsche aus dem Chat vom 27. Oktober sind in Task 013 umgesetzt (der Verlauf ist noch einmal vollständig durchgesehen, auch die Nachrichten mitten in der Arbeit). Hier steht nur, was noch nicht mit eigenen Augen geprüft ist und sich ohne den Eigentümer prüfen lässt. Neue Wünsche aus dem Chat kommen hier dazu.

- [x] **Flug der Figur in der Lobby als Bildfolge:** `FLIGHT=1` im Screenshot-Test (`app/test/screens_test.dart`) tippt auf der Figurenseite eine freie Figur an und hält den Flug in Einzelbildern fest (`<sprache>-02-lobby-flight-<n>.png`). Geprüft: die Figur wächst aus ihrer Karte und fliegt mit einer Drehung nach oben, die Seite scrollt mit, die Karte bleibt als Lichtfeld zurück, die alte Figur gleitet in ihre Karte zurück. Ist die große Figur beim Antippen nicht im Bild, fliegt sie nicht sichtbar weg (wie gewünscht).
- [x] **Website sauber gestalten:** ein Durchgang über alle Seiten (Start, Download, Anleitung, Impressum/Datenschutz) auf Handy und Desktop mit echten Bildschirmfotos; alles, was unsauber aussieht (Abstände, Lesbarkeit, Kanten, Überlappungen, uneinheitliche Bausteine), wird behoben und noch einmal fotografiert. Gefunden und behoben: Seitenleisten der Anleitung ohne Untergrund (jetzt auf Plaketten), veralteter Schritt „Figur wählen“ in der Anleitung (jetzt Karten und Flug), Download-Karten auf dem Desktop zu gedrängt (jetzt zwei mal zwei). Startseite, Einladungsseite und Datenschutz waren sauber.
- [ ] **Patch-Release:** Version erhöhen, CHANGELOG abschließen, Tag pushen, Release-Workflow grün, Website zeigt die neue Version.
- [x] **Download-Seite: Version und Zahlen eingebettet:** die aktuelle Versionsnummer groß und präsent im Kopf der Seite, die Download-Zahlen auf derselben Tafel statt als eigener Block daruntergeklatscht; Handy und Desktop fotografiert. Umgesetzt als Ticket-Plakette im Kopf: Versionsnummer groß in Laternenfarbe, darunter Datum und „Was ist neu?“, hinter einer gestrichelten Naht die Zahlen.
- [x] **Website: Vorhangbogen in der Theaterszene zu klein:** der Bogen oben läuft groß über die ganze Breite (wie in der App), Desktop und Handy fotografiert.
- [x] **Website: Figuren und Handys im Startbild auf dem Desktop zu weit oben:** sie stehen jetzt auf den Bühnenbrettern; Desktop fotografiert.
- [x] **Website: Girlanden zwischen den Szenen zu klein:** die Girlanden („Die Besetzung“, Finale) laufen groß über die ganze Breite wie der Vorhangbogen; Desktop und Handy fotografiert.
