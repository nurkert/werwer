# Marktanalyse

Stand: 2026-10-25

Diese Analyse ordnet Whowolf im Markt der Werwolf-, Mafia- und Social-Deduction-Apps ein. Sie stützt sich auf Store-Einträge (Google Play, App Store über die iTunes-Search-API), F-Droid, GitHub und einzelne Presseartikel. Alle Zahlen stammen aus diesen Quellen und sind am 2026-10-25 abgerufen worden.

**Lesehinweise**

- **Google-Play-Downloads** sind die öffentlichen Stufen von Google („1M+“ = mindestens 1 Million). Genauere Zahlen gibt es nicht öffentlich.
- **App-Store-Bewertungen** gelten je Land (US, DE oder FR, jeweils angegeben). Apple veröffentlicht keine Downloadzahlen.
- **„Unklar“** heißt: Die Quelle sagt dazu nichts. **„(unbestätigt)“** heißt: Die Angabe stammt aus einer schwachen oder widersprüchlichen Quelle.
- Herstellerangaben (z. B. „10 Millionen Spieler“) sind als solche gekennzeichnet und nicht unabhängig geprüft.

---

## 1. Kurzfazit

1. **Die Nische „gemeinsam am Tisch, jeder mit eigenem Handy, App als Erzähler“ ist nicht leer.** Es gibt mindestens sieben Apps oder Projekte, die genau das oder fast das anbieten: Mobile Werewolf, Awooo, Aouh, Werwolf Gamemaster (7wolf), Werewolf Local Hunt, MAFIA 374 und das Open-Source-Projekt werewolves_game. Alle sind klein (höchstens 100K+ Downloads). Keines dominiert.
2. **Viele der geplanten Alleinstellungsmerkmale sind schon besetzt:**
   - Beitritt per QR-Code im Browser: 7wolf, werewolves_game, AlecM33/Werewolf, MAFIA 374 (laut Store-Text)
   - Offline im LAN: Mobile Werewolf, Awooo, werewolves_game
   - Sprecherstimme und Atmosphäre: Awooo, Aouh, 7wolf, Night Claw, La Nuit Tombe
   - „Tarnzüge“ gegen Tells: Werwolf – Spielleiter, auf einem Handy
3. **Wirklich unbesetzt ist nach dieser Recherche die Kombination**, nicht ein einzelnes Merkmal. Keine gefundene App bietet alles zusammen: offline im LAN **und** Browser-Beitritt ohne Installation **und** alle Plattformen **und** Open Source/selbst hostbar **und** Tarnaufgaben für alle Spieler auf eigenen Geräten **und** später gemischtes Spiel lokal + remote über ein Relay.
4. **Die Massen-Downloads liegen woanders:**
   - Online-Werwolf: Wolvesville 10M+
   - Ein-Handy-Apps: Wolvesville Classic 5M+
   - Begleit-Apps zu Kartenspielen: Ravensburger Werwölfe Vollmondnacht 1M+, Bezier One Night 1M+
   - Allgemeine Party-Apps: Splash 5M+

   Multi-Device-Apps für den Tisch haben bisher keine große Reichweite erreicht.

---

## 2. Wettbewerber

### 2a. Multi-Device am selben Tisch (wichtigste Gruppe)

| App | Plattformen | Modell | Popularität | Eigenes Gerät | Offline/LAN | Browser-Beitritt | Erzähler/Ton |
|---|---|---|---|---|---|---|---|
| **Mobile Werewolf** (Skyost / Hugo Delaunay) | Android, iOS (Flutter laut It's All Widgets) | Gratis, IAP (iOS: „neue Rollen“ 1,99 $) | Play: 100K+, 4,2 ★, 492 Rezensionen. iOS US: 4,5 ★ / 17, FR: 4,5 / 72 | Ja (oder ein Gerät) | **Ja, lokales Netz, kein Online-Modus** | Nein, jeder installiert die App | Unklar |
| **Awooo** (Nearby Games, FR) | iOS, Android | Gratis, IAP | Play: 500+. iOS FR: 4,2 ★ / 10 (Start 08/2026) | **Ja** | **Ja, lokal per Bluetooth/WLAN, ohne Server** | Nein (App nötig, soweit erkennbar) | **Profi-Sprecherstimme** |
| **Aouh** (Happy App Studio / Sacha Hamiche, FR) | iOS, Android | Gratis, Werbung, Abo/IAP „Aouh+“ | Play: 1K+. iOS FR: 4,9 ★ / 18 (Start 02/2026) | Ja (oder ein Gerät) | **Nein**, der Modus mit mehreren Handys braucht Internet | Unklar (Code teilen) | Echte Stimme, Soundtrack |
| **Werwolf Gamemaster / 7wolf** (Mathias Pechinger, DE) | iOS/iPad, Android | Gratis, IAP „Premium Rollen“ 6,99 € | Play: 1K+. iOS DE: 4,2 ★ / 5 | Ja | **Nein**, Internet nötig | **Ja, über play.7wolf.de bzw. QR-Code** | **KI-Erzähler**, Musik über Bluetooth-Lautsprecher, eigene Hardware „Wolfbox“ |
| **Werewolf Local Hunt** (Mela Map, TW) | Android, iOS | Gratis, Erweiterungspakete per IAP | Play: 10K+, 3,6 ★. iOS DE: keine Bewertungen | Ja, ein Host | **Nein**, Internet nötig | QR-Code (App oder Browser unklar) | Soundeffekte, Ambient; chinesischer Regelstil |
| **MAFIA 374** (MoodBoard Media) | iOS | PRO als Einmalkauf oder Abo; Room Mode nur in PRO | Laut mwm.ai < 1.000 Downloads, 0 Bewertungen (Start 07/2026) | Ja | Unklar | Laut Store „kein App-Download“ per QR (unbestätigt) | Automatische Phasen |
| **Werewolf – Mafia Offline Game** (Zion Studios) | iOS | Abo bis 49,99 $ Lifetime | iOS: 4,2 ★ / 6 | Rollen per QR über die Website | Unklar, trotz „Offline“ im Titel | Rollenabruf per Website | Sprecherstimme |
| **Werewolf Offline Party Games** (Real Life Apps) | iOS | Werbung, Abo, Münzen | iOS DE: 2,3 ★ / 3 | Ja (auch für Video-Calls) | Unklar | Nein | KI-Moderator. Rezension: „DOESN'T WORK“ beim Hosten |
| **Mafia – A Party Game** (Strato InC) | Android | Gratis | Play: 10K+, 4,4 ★ | Ja, 6-stelliger Raumcode | Unklar (vermutlich online) | Nein | Automatische Phasen |
| **werewolves_game** (Open Source, siehe Kap. 3) | Android-APK (arm64), Linux | Gratis, GPL-3.0 | F-Droid; 16 GitHub-Sterne | Ja | **Ja, LAN ohne Internet** | **Ja, Browser + QR** | Kein Erzähler-Audio erkennbar |

**Wichtige Beobachtungen**

- **Awooo kommt Whowolf konzeptionell am nächsten:** eigenes Handy, lokale Verbindung ohne Server, Sprecherstimme, „tout le monde joue“. Unterschiede: nur iOS/Android, jeder braucht die App, kein Browser-Beitritt, nicht Open Source, 4 bis 17 Spieler. Awooo ist sehr jung und hat kaum Reichweite (Play 500+).
- **7wolf** hat genau das Beitrittsmodell, das Whowolf für Stufe 2 plant: QR-Code bzw. Webseite, Spieler im Browser. Dazu kommen KI-Erzähler und Musik. 7wolf braucht aber Internet und ist klein. Eine ältere Rezension nennt Abstürze. Der Entwickler erklärt fehlende Ansagen mit gesperrten Handys. Dieses Plattformproblem wird Whowolf auch haben.
- **Mobile Werewolf** ist die reichweitenstärkste Multi-Device-App (100K+, seit 2020). Sie ist ebenfalls in Flutter gebaut und hat einen LAN-Modus. Ein Browser-Beitritt fehlt. Eine einzelne iOS-Rezension klagt über ungewollte Abbuchung und darüber, dass das gemeinsame Spielen nicht funktionierte (Einzelstimme, nicht verifizierbar).
- **Fast alle Multi-Device-Apps brauchen Internet** (Aouh, 7wolf, Local Hunt). Echtes LAN ohne Internet bieten nur Mobile Werewolf, Awooo und werewolves_game.

### 2b. Erzähler-/Spielleiter-Apps für ein einzelnes Gerät

Diese Apps sind der eigentliche Massenmarkt „Werwolf am Tisch“. Entweder wird das Handy herumgereicht, oder ein Spielleiter bedient es.

| App | Plattformen | Modell | Popularität | Bemerkungen |
|---|---|---|---|---|
| **Wolvesville Classic** (Wolvesville GmbH) | Android, iOS, Windows | Werbung + IAP, Pro-Version | Play: **5M+**, 4,3 ★, 46,5K Rezensionen. iOS US: 4,6 / 419 | Handy herumreichen, über 30 Rollen, App führt durch Nacht/Tag |
| **Mafia Party – Werewolf** (Volant Games) | Android | Werbung | Play: 50K+, 4,7 ★ | Herumreichen, Moderator-Assistent |
| **Mafia Party – Card Game Dealer** | Android | – | Play: 100K+, 3,9 ★ (letztes Update 2017) | Rollenverteilung |
| **Werewolf Master** (Enes Sorucu) | Android | Werbung + IAP | Play: 10K+, 3,4 ★ | Herumreichen, über 36 Rollen |
| **Werewolf: Undercover / Loup Garou: Undercover** (Gregoire Lemoulant) | iOS, Android | IAP | iOS FR: 4,5 ★ / **655**. Play: 10K+ | Ein iPhone, „App als Erzähler“, Animationen |
| **Loup Garou: La Nuit Tombe** (INNOWAY) | iOS | ohne Werbung | iOS FR: 4,5 ★ / 91 (Start 07/2026) | Ein Handy, Sprecher. **Ruft auch tote Rollen nachts auf**, damit niemand erkennt, wer tot ist |
| **Loup Garou: Night Claw** (T&L Studio) | iOS, Android | IAP | iOS FR: 4,3 ★ / 87. Play: 1K+ | Ein Handy, sarkastische Erzählerstimme, Musik, offline, Selfies am Ende |
| **Werwolf – Spielleiter** (Lukas Beutler, DE) | iOS | 3 Partien gratis, dann Einmalkauf | neu (10/2026), 3 Bewertungen | **Tarnfrage für alle Spieler, Handy nachts völlig stumm.** Siehe Kap. 5 |
| **Werwolf – Erzähler** (Colin Ihlenfeldt, DE) | iOS (iPad) | gratis, ohne Werbung | iOS DE: 4,6 ★ / 50. Letztes Update 2023 | Hilfe für menschlichen Erzähler, Musik/Sounds, über 100 Kartensets |
| **Werwolf** (hyport, DE) | Android | – | Play: 5K+ | Hilfe für Spielleiter, „Trinkversion“ |
| **Werewolf Moderator** (sewookori, KR) | Android | Werbung + IAP | Play: 10K+, 3,2 ★ | Spielleiter-Assistent, Rollen per SMS/KakaoTalk |
| **Mafia Without Moderator** (Aves) | Android | Werbung + IAP | Play: 10K+, 4,3 ★ | ein Handy, koreanische Mafia-Variante |
| **WolfMafia** (Christian Ottenhaus) | iOS | gratis | kaum Bewertungen. Letztes Update 12/2022 | Rollen per QR, offline, DE/EN/ES |
| **Social Deduction Game** (F-Droid) | Android | gratis, Open Source | F-Droid, v0.9.0 | Offline-Assistent für menschlichen Spielleiter, ohne Werbung und Tracking |
| **Werewolf Game** (yannashuach) | Android | IAP | Play: 1K+ | ein Gerät, 19 Sprachen |

**Beobachtung:** Bei Single-Device-Apps ist „die App erzählt mit Stimme und Musik“ längst Standard, besonders auf dem französischen Markt (Night Claw, La Nuit Tombe, Undercover, Awooo). Ein starker Erzähler ist dort eine Grundvoraussetzung, kein Unterscheidungsmerkmal.

### 2c. Online-Spiele mit Fremden (und angrenzende Spiele)

| Spiel | Plattformen | Modell | Popularität | Bezug zu Whowolf |
|---|---|---|---|---|
| **Wolvesville** | Android, iOS, Web, Steam | Free-to-play, Werbung, IAP, Battle Pass | Play: **10M+**, 4,2 ★, 445K Rezensionen. iOS US: 4,5 / 6.824. Herstellerangabe: „10 million players“. Steam: Spitze 148 gleichzeitige Spieler (raijin.gg) | Private Räume mit Freunden möglich, aber online mit Chat. Über 100 Rollen |
| **Werewolf Online / Loups-Garous en ligne** (ComputerDev, FR) | Android, iOS | Werbung + IAP | Play: 1M+, 4,2 ★, 12,1K Rez. iOS FR: 4,5 / 9.238 | 30 Rollen, online (Details zum Modus unklar) |
| **Wolfy** (Wolfy SAS, FR) | Web, Android, iOS | Werbung + IAP | Play: 1M+, **3,1 ★**, 15,2K Rez. iOS FR: 4,5 / 4.796 | Online, bis 20 Spieler. Trustpilot-Kritik: unfreundlich zu Neulingen, Beleidigungen, Absprachen (anekdotisch) |
| **Town of Salem – The Coven** | Android, iOS, Steam | Werbung + IAP | Play: 1M+, **2,9 ★**, 25,8K Rez. Steam: bis 1,6 Mio. verkauft (Tracker, unbestätigt) | Online-Mafia-Klassiker |
| **Town of Salem 2** | Steam, Android | Free-to-play | Play: 50K+. Steam: Allzeit-Spitze ca. 3.700 gleichzeitig, aktuell ca. 170 bis 260 | Online |
| **Werewolf** (Sharejoy) | Android | IAP | Play: 1M+, 4,5 ★, 40,2K Rez. | Online-Sozial-App mit Voice, Dating, „Scripts“ |
| **Mafia42** | iOS, Android | IAP | iOS US: 3,9 / 737 | Chat-basiertes Online-Mafia |
| **Among Us** (angrenzend) | alle | Werbung + IAP | Play: **500M+**, 3,9 ★, 13,7M Rez. 2020: über 100 Mio. Downloads und 3,8 Mio. gleichzeitige Spieler (Entwickler über KitGuru). „720 Mio. Downloads“ (rec0ded88, unbestätigt) | Zeigt die Größe des Genres, ist aber kein Tischspiel |
| **Suspects: Mystery Mansion** (angrenzend) | Android, iOS | IAP | Play: 50M+ | Online-Social-Deduction |

**Beobachtung:** Online-Werwolf ist groß, aber ein anderes Produkt. Bewertungen um 3 Sterne bei Wolfy und Town of Salem und die Trustpilot-Kritik deuten auf Probleme mit toxischen Fremden hin. „Nur mit Freunden, in echt“ wird von Awooo, Night Claw und Local Hunt ausdrücklich als Gegenposition beworben. Auch das ist also kein Alleinstellungsmerkmal mehr.

### 2d. Offizielle Begleit-Apps kommerzieller Editionen

| App | Verlag | Popularität | Funktion |
|---|---|---|---|
| **One Night** (für One Night Ultimate Werewolf u. a.) | Bezier Games | Play: **1M+**, 4,2 ★, 4,59K Rez. iOS US: 4,2 / 632 | Automatisiert die Nacht-Erzählung, Timer. **Nur mit den Karten nutzbar** |
| **Ultimate Werewolf Moderator** | Bezier Games | Play: 10K+ | Deckbau, Karten scannen, führt durch Tag/Nacht |
| **Ultimate Werewolf Timer** | Bezier Games | Play: 50K+, 4,7 ★ | Timer |
| **Werewords** | Bezier Games | Play: 100K+, 4,2 ★ | Begleit-App zum Wortspiel |
| **Werwölfe Vollmondnacht** | Ravensburger | Play: **1M+**, 5,0 ★, 3,91K Rez. iOS DE: 4,0 / 329 | Begleit-App zu „Vollmondnacht“, „MorgenGrauen“ u. a.: Erzählung. Nur mit Karten |
| **Werwörter** | Ravensburger | iOS DE: 3,5 / 61 | Begleit-App, „übernimmt die Funktion des Spielleiters“, markante Sprecherstimme |
| **Lupus in Tabula** (dV Giochi) | – | Keine offizielle App gefunden. Es gibt die Drittanbieter-App „Lupus Moderator“ (Vincenzo Biallo, 2020) | – |

**Beobachtung:** Die Begleit-Apps erreichen Millionen-Downloads, weil jede verkaufte Schachtel einen Download auslöst. Dieser Vertriebsweg steht Whowolf nicht offen. Er zeigt aber, wie groß die Zielgruppe ist, die am Tisch mit einer App als Erzähler spielt. Begleit-Apps setzen immer ein Handy in der Mitte plus Karten voraus. Eigene Geräte pro Spieler gibt es dort nicht.

### Weitere Signale

- **Kartenspiel „Les Loups-Garous de Thiercelieux“:** Die Quellen widersprechen sich, „7 Millionen verkauft“ (Phonandroid) gegen „500.000 pro Jahr“ (Fnac/L'Éclaireur). In Frankreich gibt es außerdem eine TV-Show bei Canal+. Frankreich ist erkennbar der aktivste Markt für neue Werwolf-Apps 2025/2026: Awooo, Aouh, Night Claw, La Nuit Tombe und Undercover kommen alle von dort.
- **Allgemeine Party-Apps** sind viel größer als reine Werwolf-Apps: Splash (Imposter-Spiel) hat Play 5M+, 80,8K Rez. und iOS DE 4,7 / 228.304. „Undercover“ hat iOS FR 4,7 / 94.288.

---

## 3. Open-Source-Projekte

| Projekt | Technik | Lizenz | Aktivität | Bezug |
|---|---|---|---|---|
| **davidchilin/werewolves_game** | Python/Flask + WebSockets. Android-APK startet einen Server auf dem Handy | GPL-3.0 | aktiv (F-Droid v5 vom 22.10.2026), 16 Sterne | **Funktional der nächste Verwandte:** Host-Handy im WLAN, Spieler im Browser per QR, kein Internet, kein menschlicher Erzähler, 24 Rollen, Pass-and-Play. Einschränkungen: nur arm64, die App muss im Hintergrund laufen dürfen, Admin-Passwort „w“, Fokus eher auf Text/Chat als auf Atmosphäre |
| **AlecM33/Werewolf** (play-werewolf.app) | JavaScript, Web | GPL-3.0 (README nennt MIT, widersprüchlich) | Push 06/2026, 47 Sterne | Rollen auf jedes Gerät per Link/Code/QR, Moderator verwaltet den Zustand. **Spielt Tag/Nacht nicht selbst und setzt keine Fähigkeiten um** |
| **xiong35/werewolf** | Vue3, Koa, socket.io | (Repo-Lizenz) | letzter Push 2022, 177 Sterne | Chinesische Web-App für das Spiel vor Ort: kein Spielleiter, automatische Verteilung, 6 Rollen, Reconnect. Online gehostet, nicht LAN |
| **sadrasabouri/mafia** | Python, lokaler Webserver | – | letzter Push 2024, 95 Sterne | Rollen im Browser über LAN. Ein „GOD“ am Laptop moderiert weiter |
| **hperrin/nightwolf** | Web | Apache-2.0 | letzter Push 2020 | „Play in person or over VC“, Server als Erzähler. Inaktiv |
| **H1ghSyst3m/TableGather** | TypeScript, React, WebSockets | AGPL-3.0 | 2026, 0 Sterne | Browser-Hub für Tischspiele vor Ort, frühes Stadium |
| **Social Deduction Game** (jens_3, F-Droid) | Android | Open Source | v0.9.0 | Offline-Hilfe für menschlichen Spielleiter |
| **IamRezaMousavi/Mafia** (F-Droid) | Kotlin | – | aktiv | Mafia-Party-App |
| **Benkralex/Werewolf-App** | Dart/Flutter | – | 2025 | Hilfe für Spielleiter |
| **luismeyer/werwapp** | TypeScript | – | 2026 | Nur Hintergrundmusik für Tag/Nacht |
| **lykoss/lykos**, **GreyWolfDev/Werewolf** (Telegram, 665 Sterne), Discord-/Slack-Bots | div. | div. | teils aktiv | Online über Chat-Plattformen |

**Fazit Open Source:** Ein Open-Source-Werwolf mit Host-Handy, Browser-Beitritt und LAN gibt es bereits (werewolves_game). Es fehlt ein **polierter, plattformübergreifender** Vertreter mit Store-Präsenz (iOS!), Atmosphäre und Fokus auf das Spiel vor Ort. Keines der gefundenen Projekte hat nennenswerte Reichweite: Das größte relevante Repo hat 177 Sterne.

---

## 4. Funktionsvergleich mit Whowolf

Legende: ✅ vorhanden · ❌ nicht vorhanden · ◐ teilweise · ? unklar. Die Whowolf-Spalte ist **geplant**, nicht umgesetzt.

| Funktion | Whowolf (geplant) | Mobile Werewolf | Awooo | Aouh | 7wolf | Local Hunt | werewolves_game | Wolvesville Classic | Wolvesville |
|---|---|---|---|---|---|---|---|---|---|
| Jeder Spieler eigenes Gerät | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Gemeinsam am Tisch als Kernidee | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ (auch Video-Call) | ✅ | ❌ |
| Kein menschlicher Spielleiter | ✅ | ✅ | ✅ | ✅ (wählbar) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Ohne Internet (LAN/lokal) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ (1 Gerät) | ❌ |
| Beitritt im Browser ohne Installation | ✅ | ❌ | ❌ | ? | ✅ | ? | ✅ | – | ✅ (Web-Version) |
| QR-Code-Beitritt | ✅ | ? | ? | ◐ (Code) | ✅ | ✅ | ✅ | – | ? |
| Sprecherstimme/Atmosphäre | ✅ | ? | ✅ | ✅ | ✅ (KI) | ◐ (Sounds) | ❌ | ◐ | ◐ |
| Ton auf allen Geräten | ✅ | ? | ? | ? | ❌ (Lautsprecher am Host) | ? | ❌ | – | – |
| Tarnaufgabe nachts für **alle** | ✅ | ? | ? | ? | ? | ? | ❌ (nicht erwähnt) | – | – |
| Remote-Spieler mischen (Relay) | ✅ (Stufe 2) | ❌ | ❌ | ? | ◐ (alles online) | ❌ | ❌ | ❌ | ✅ (nur online) |
| Story/Zusammenfassung am Ende | ✅ | ? | ? | ? | ? | ? | ◐ (Spiel-Log) | ? | ? |
| Open Source | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Selbst hostbar | ✅ | – | – | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Android + iOS | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ (nur Android) | ✅ | ✅ |
| Desktop + Web | ✅ | ❌ | ❌ | ❌ | ◐ (Web-Client) | ❌ | ◐ (Linux) | ◐ (Windows) | ✅ |
| Ohne Werbung/Abo | ✅ | ◐ (IAP) | ◐ (IAP) | ❌ | ◐ (IAP) | ◐ (IAP) | ✅ | ❌ | ❌ |
| Eigene Rollen-Sets/Themes | ✅ (später) | ❌ | ? | ◐ | ? | ◐ (Pakete) | ✅ (Code) | ? | ❌ |

„?“ heißt fast immer, dass der Store-Text nichts dazu sagt. Ohne die Apps selbst zu testen, lässt sich das nicht klären.

---

## 5. Lücken und Unterscheidungsmerkmale, ehrlich bewertet

### Nicht einzigartig (bereits von anderen beansprucht)

| Geplantes Merkmal | Wer es schon hat |
|---|---|
| Jeder mit eigenem Handy, App als Erzähler | Mobile Werewolf, Awooo, Aouh, 7wolf, Local Hunt, werewolves_game, MAFIA 374 |
| Ohne Internet im lokalen Netz | Mobile Werewolf, Awooo, werewolves_game |
| Beitritt per QR-Code im Browser | 7wolf (play.7wolf.de), werewolves_game, AlecM33/Werewolf. MAFIA 374 laut Store |
| Atmosphärischer Erzähler mit Stimme/Musik | Awooo, Aouh, 7wolf (KI), Night Claw, La Nuit Tombe, Werwörter, Werwolf – Erzähler |
| Keine Tells in der Nacht | **Werwolf – Spielleiter** (alle beantworten eine Tarnfrage, Handy stumm, aber auf einem Gerät). **La Nuit Tombe** ruft tote Rollen weiter auf |
| „Nur mit Freunden, kein Online mit Fremden“ | Awooo, Night Claw, Local Hunt werben ausdrücklich damit |
| Open Source + selbst hostbar | werewolves_game (GPL-3.0) |
| Kein Spielleiter nötig, Regeln automatisch | Standard in fast allen Apps |

### Nach dieser Recherche wahrscheinlich unbesetzt

1. **Tarnaufgaben für alle auf eigenen Geräten:** Jeder tippt nachts auf seinem eigenen Handy etwas. In keiner Multi-Device-App wurde das gefunden. **Einschränkung:** Bei Awooo, Aouh, 7wolf und Local Hunt sagt die Store-Beschreibung nichts dazu. Ein Test wäre nötig. Die Idee selbst ist nicht neu (siehe Werwolf – Spielleiter).
2. **Offline im LAN *und* Beitritt ohne Installation, mit Store-App auf iOS und Android:** werewolves_game kann LAN + Browser, aber nur mit Android/Linux als Host und ohne Politur. 7wolf kann Browser-Beitritt, braucht aber Internet. Awooo kann offline, braucht aber die App auf jedem Gerät.
3. **Gemischtes Spiel:** Lokale Spieler im WLAN plus einzelne Remote-Spieler über ein Relay, mit dem Host-Gerät als Autorität. Kein gefundenes Produkt bietet das. Die Apps sind entweder rein lokal oder rein online.
4. **Plattformbreite:** Host auf Android, iOS, macOS, Windows und Linux, Client zusätzlich im Web. Kein Wettbewerber deckt das ab.
5. **Polierte Open-Source-Alternative ohne Werbung, Abo und Konto, im App Store.** Die kommerziellen Tisch-Apps arbeiten fast alle mit IAP, Abo oder Werbung. Teils gibt es hohe Abo-Preise (Zion Studios: 49,99 $ Lifetime, Real Life Apps: Münzen bis 49,99 $) und Paywalls für Kernmodi (MAFIA 374: Room Mode nur in PRO; Aouh+: anonyme Abstimmung).
6. **Story-Zusammenfassung am Ende:** Night Claw hat einen Abschluss-Bildschirm mit Selfies, werewolves_game ein Log. Eine erzählte Rückschau wurde nicht gefunden (Einschränkung wie oben).

### Risiken, die die Recherche zeigt

- **Die Nische wächst gerade.** Awooo (08/2026), Aouh (02/2026), MAFIA 374 (07/2026), Werwolf – Spielleiter (10/2026) und La Nuit Tombe (07/2026) sind alle 2026 erschienen. Es ist also kein leerer Markt, sondern ein Wettlauf.
- **Typische Ärgernisse aus Rezensionen und Entwicklerantworten:** Verbindungsprobleme beim Zusammenspielen (Mobile Werewolf, Real Life Apps), fehlende Ansagen bei gesperrtem Bildschirm (7wolf), App muss im Hintergrund laufen (werewolves_game). Whowolf muss Verbindung, Reconnect und Bildschirmsperre besonders gut lösen. Sonst trifft es dieselbe Kritik.
- **Keine Multi-Device-Tisch-App hat bisher mehr als 100K+ Downloads erreicht.** Das kann an fehlender Vermarktung liegen. Es kann aber auch ein Hinweis sein, dass viele Gruppen das Herumreichen eines Handys als „gut genug“ empfinden (Wolvesville Classic 5M+).

---

## 6. Download-Potenzial

**Größenordnungen aus dieser Recherche (Google Play):**

| Segment | Beispiele | Downloads |
|---|---|---|
| Online-Werwolf | Wolvesville | 10M+ |
| Online-Werwolf | Wolfy, Werewolf Online, Town of Salem | je 1M+ |
| Ein-Handy-Tisch-App | Wolvesville Classic | 5M+ |
| Ein-Handy-Tisch-App | übrige | meist 10K+ bis 100K+ |
| Begleit-Apps | Ravensburger, Bezier | je 1M+ (an Kartenverkauf gekoppelt) |
| Multi-Device-Tisch-App | Mobile Werewolf | 100K+ (nach ca. 6 Jahren) |
| Multi-Device-Tisch-App | 7wolf, Aouh | 1K+ |
| Multi-Device-Tisch-App | Awooo | 500+ |
| Multi-Device-Tisch-App | Local Hunt | 10K+ |
| Angrenzend: Party-Apps | Splash | 5M+ |

**Wie solche Apps sich verbreiten (Muster aus den Quellen):**

- **Am Tisch, von Mensch zu Mensch.** Eine Person bringt die App mit, alle anderen erleben sie. Jackbox hat das mit dem Browser-Beitritt über jackbox.tv groß gemacht. Laut einem GDC-Bericht (Thumbsticks, 08/2020) hatte Jackbox über 100 Mio. Spieler 2019 und über 110 Mio. Spieler von März bis Juni 2020. Der Bericht nennt den Beitritt „nur mit dem Smartphone-Browser“ als zentralen Grund für die niedrige Einstiegshürde. **Für Whowolf heißt das:** Jede Runde mit Browser-Beitritt zeigt 5 bis 15 Menschen die App, ohne dass sie etwas installieren müssen. Das ist der stärkste Wachstumshebel, aber nur, wenn dabei ein Hinweis wie „App holen / selbst hosten“ auftaucht.
- **Social Media:** Splash wirbt selbst damit, das Spiel sei „von TikTok/Insta bekannt“ (Herstelleraussage).
- **Physische Spiele:** Begleit-Apps verbreiten sich über die Schachtel. Für Whowolf ist das nicht übertragbar.
- **Lokale Märkte:** Frankreich ist sichtbar der aktivste Werwolf-App-Markt. Mobile Werewolf hat in FR mehr iOS-Bewertungen (72) als in den USA (17).

**Realistische Einschätzung (eigene Einordnung, keine Messung):**

- Ohne Marketing und ohne Store-Präsenz bleibt ein Open-Source-Projekt dieser Art bei Hunderten bis wenigen Tausend Nutzern. Das zeigen die Sternezahlen der bestehenden Projekte (max. 177).
- Mit guter Store-Präsenz auf iOS und Android, guter Politur und Mundpropaganda am Tisch sind 10K+ bis 100K+ Downloads in einigen Jahren plausibel. Das entspricht Mobile Werewolf.
- Millionen-Downloads haben in diesem Segment nur Online-Spiele, Ein-Handy-Apps großer Anbieter und Begleit-Apps erreicht. Für Whowolf ist das kein realistisches Planungsziel.
- **Browser-Teilnehmer zählen nicht als Store-Download.** Die echte Reichweite (Spieler pro Runde) kann deutlich über den Downloads liegen. Dafür lohnt sich eine eigene, datenschutzfreundliche Kennzahl, etwa die Zahl gestarteter Runden am offiziellen Relay.

---

## 7. Empfehlungen zur Positionierung

1. **Nicht mit „erste App, bei der jeder sein Handy nutzt“ werben.** Das stimmt nicht. Besser ist ein Versprechen aus der Kombination, z. B.: *„Werwolf am Tisch. Jeder spielt mit, auch ohne App und ohne Internet. Kostenlos und Open Source.“*
2. **Browser-Beitritt ohne Installation zur Hauptsache machen**, und zwar **auch offline im LAN**: Der Host liefert die Web-App selbst aus. Genau diese Kombination hat außer dem rohen werewolves_game niemand. Wichtig ist der Ablauf „QR scannen, im Spiel“ in wenigen Sekunden.
3. **„Keine Tells“ als erlebbares Merkmal gestalten und testen.** Die Idee gibt es schon auf einem Gerät (Werwolf – Spielleiter). Auf eigenen Geräten mit gleichförmigen Tarnaufgaben, Stille und gleicher Bildschirmhelligkeit ist sie bisher nicht dokumentiert. Bevor damit geworben wird: Awooo, Aouh und 7wolf kurz selbst testen, um auszuschließen, dass sie es schon können.
4. **Zuverlässigkeit vor Funktionsfülle.** Die häufigsten Klagen betreffen Verbindungen, gesperrte Bildschirme und Hintergrundbetrieb. Reconnect, Wake-Lock und eine klare Anzeige „Spieler X verbunden“ sind Pflicht. Das passt zum Leitprinzip in VISION.md („erst muss sich eine Runde richtig gut anfühlen“).
5. **Fair statt Paywall:** keine Werbung, kein Abo, kein Konto, alle Rollen frei. Das ist im Store-Text und in Screenshots ein klarer Kontrast zu Aouh+, MAFIA 374 PRO, Zion Studios und Real Life Apps.
6. **Erzähler mit Charakter, aber nicht als Hauptargument.** Sprecherstimme und Musik sind bei französischen Apps Standard. Whowolf braucht sie, gewinnt damit aber allein nicht. Mögliche Unterschiede: Ton auf allen Geräten, wählbare Stimmungen (gruselig/lustig/dramatisch), erzählte Rückschau am Ende.
7. **Gemischtes Spiel (lokal + remote über Relay) als zweites Alleinstellungsmerkmal** für Stufe 2 aufheben, z. B. „Ein Freund ist krank? Er spielt per Link mit.“ Das hat derzeit kein Wettbewerber.
8. **Die Open-Source-Community gezielt ansprechen:** F-Droid, IzzyOnDroid, selbst hostbares Relay per Docker. werewolves_game zeigt, dass F-Droid-Nutzer so etwas suchen. Kooperation oder Abgrenzung (GPL vs. Apache) bewusst entscheiden.
9. **Sprachen früh: Deutsch, Englisch, Französisch.** Frankreich ist der aktivste Markt (Kartenspiel-Tradition, TV-Show, viele neue Apps). Dort ist aber auch die Konkurrenz am dichtesten.
10. **Eigene Begriffe und Rollentexte beibehalten** (siehe LEGAL.md). Die Wettbewerber verwenden teils die Rollennamen der kommerziellen Editionen. Whowolf sollte das nicht übernehmen, auch wenn es beim Suchmaschinen-Ranking hilft. Für die Store-Suche genügen generische Begriffe wie „Werwolf“ und „Mafia“.

---

## Quellen

**Multi-Device / Tisch**
- Mobile Werewolf: https://play.google.com/store/apps/details?id=fr.skyost.werewolf · https://apps.apple.com/us/app/mobile-werewolf/id1504559806 · https://werewolf.skyost.eu/en/ · https://itsallwidgets.com/mobile-werewolf-the-werewolf-game-on-smartphone
- Awooo: https://apps.apple.com/fr/app/id6758315421 · https://play.google.com/store/apps/details?id=com.matvincensini.lg · https://nearbygames.io/
- Aouh: https://play.google.com/store/apps/details?id=studio.happyapp.aouh · https://apps.apple.com/fr/app/id6759094186 · https://aouh.happyapp.studio/
- Werwolf Gamemaster / 7wolf: https://apps.apple.com/de/app/id6742995790 · https://play.google.com/store/apps/details?id=de.siebenwolf.app
- Werewolf Local Hunt: https://play.google.com/store/apps/details?id=com.melamap.werewolf · https://apps.apple.com/de/app/id6504466828
- MAFIA 374: https://mwm.ai/de/apps/mafia-374/6775567763
- Werewolf – Mafia Offline Game: https://apps.apple.com/app/id6738326023
- Werewolf Offline Party Games: https://apps.apple.com/app/id1536899372
- Mafia – A Party Game: https://play.google.com/store/apps/details?id=com.utsosarkar.mafia

**Single-Device**
- Wolvesville Classic: https://play.google.com/store/apps/details?id=org.faudroids.werewolf · https://apps.apple.com/app/id1322989325
- Mafia Party – Werewolf: https://play.google.com/store/apps/details?id=com.VolantGames.MafiaPartyFree
- Mafia Party – Card Game Dealer: https://play.google.com/store/apps/details?id=com.caddosierra.mafiaparty
- Werewolf Master: https://play.google.com/store/apps/details?id=com.EnesSorucu.werewolf
- Loup Garou: Undercover: https://apps.apple.com/fr/app/id6740009341 · https://play.google.com/store/apps/details?id=xyz.bubbleappstudio.werewolfundercover
- Loup Garou: La Nuit Tombe: https://apps.apple.com/fr/app/id6790552542
- Loup Garou: Night Claw: https://apps.apple.com/fr/app/id6760731403 · https://play.google.com/store/apps/details?id=com.tlstudio.nightclaw
- Werwolf – Spielleiter: https://apps.apple.com/de/app/id6816420702
- Werwolf – Erzähler: https://apps.apple.com/de/app/id1505233252
- Werwolf (hyport): https://play.google.com/store/apps/details?id=de.hyport.werwolf
- Werewolf Moderator (sewookori): https://play.google.com/store/apps/details?id=com.sewookori.werewolf_assistant
- Mafia Without Moderator: https://play.google.com/store/apps/details?id=llc.aves.mafia
- WolfMafia: https://apps.apple.com/mx/app/wolfmafia/id1595972299
- Social Deduction Game (F-Droid): https://f-droid.org/en/packages/io.github.jens_3.socialdeductiongame/
- Werewolf Game (yannashuach): https://play.google.com/store/apps/details?id=com.yannashuach.werewolf
- Lupus Moderator: https://skich.app/games/lupus-moderator

**Online / angrenzend**
- Wolvesville: https://play.google.com/store/apps/details?id=com.werewolfapps.online · https://apps.apple.com/app/id1394503496 · https://raijin.gg/app/2502760/Wolvesville · https://steamspy.com/app/2502760
- Werewolf Online / Loups-Garous en ligne: https://play.google.com/store/apps/details?id=fr.computerdev.werewolves · https://apps.apple.com/FR/app/id1475253502
- Wolfy: https://play.google.com/store/apps/details?id=fr.wolfy.app · https://fr.vikidia.org/wiki/Wolfy · https://ie.trustpilot.com/review/wolfy.fr
- Town of Salem: https://play.google.com/store/apps/details?id=com.blankmediagames.townofsalemthecoven · https://play.google.com/store/apps/details?id=com.BlankMediaGames.TownofSalem2 · https://steambase.io/apps/2140510 · https://raijin.gg/app/2140510/Town_of_Salem_2 · https://steampulse.org/game/334230
- Werewolf (Sharejoy): https://play.google.com/store/apps/details?id=com.sharejoy.werewolf
- Mafia42: https://apps.apple.com/us/app/id947258826
- Among Us: https://play.google.com/store/apps/details?id=com.innersloth.spacemafia · https://www.kitguru.net/desktop-pc/mustafa-mahmoud/among-us-surpasses-3-8-million-concurrent-players-100-million-downloads/ · https://rec0ded88.com/statistics/among-us/
- Suspects: https://play.google.com/store/apps/details?id=com.wildlifestudios.free.online.games.suspects

**Begleit-Apps**
- One Night (Bezier): https://play.google.com/store/apps/details?id=com.mobieos.karan.Wolf_Android14_11_13 · https://apps.apple.com/us/app/id728175611
- Ultimate Werewolf Moderator / Timer / Werewords: https://play.google.com/store/apps/details?id=com.beziergames.uwexmoderator · https://play.google.com/store/apps/details?id=com.beziergames.uwtimer · https://play.google.com/store/apps/details?id=com.beziergames.werewords
- Werwölfe Vollmondnacht: https://play.google.com/store/apps/details?id=com.ravensburgerdigital.werwoelfevollmondnacht · https://apps.apple.com/de/app/id1015385157
- Werwörter: https://apps.apple.com/de/app/id1441535259

**Open Source**
- werewolves_game: https://github.com/davidchilin/werewolves_game · https://f-droid.org/en/packages/io.github.davidchilin.werewolves_game
- AlecM33/Werewolf: https://github.com/AlecM33/Werewolf · https://play-werewolf.app/
- xiong35/werewolf: https://github.com/xiong35/werewolf
- sadrasabouri/mafia: https://github.com/sadrasabouri/mafia
- Night Wolf: https://github.com/hperrin/nightwolf · https://forge.sciactive.com/hperrin/nightwolf
- TableGather: https://github.com/H1ghSyst3m/TableGather
- IamRezaMousavi/Mafia: https://github.com/IamRezaMousavi/Mafia · https://f-droid.org/en/packages/com.github.iamrezamousavi.mafia/
- Benkralex/werwolf-app: https://github.com/Benkralex/werwolf-app
- luismeyer/werwapp: https://github.com/luismeyer/werwapp
- GreyWolfDev/Werewolf (Telegram): https://github.com/GreyWolfDev/Werewolf · lykoss/lykos: https://github.com/lykoss/lykos

**Markt / Verbreitung**
- Jackbox (GDC-Bericht): https://www.thumbsticks.com/how-lockdown-opened-up-jackbox-party-to-a-massive-new-audience/ · https://en.wikipedia.org/wiki/The_Jackbox_Party_Pack
- Splash: https://play.google.com/store/apps/details?id=app.cranberry.splash · https://apps.apple.com/de/app/splash-party-spiele/id6744290388
- Undercover: https://apps.apple.com/fr/app/id946882449
- Loups-Garous de Thiercelieux (Verkaufszahlen, widersprüchlich): https://www.phonandroid.com/?p=2616306 · https://leclaireur.fnac.com/article/467406-7-chiffres-qui-prouvent-que-les-loups-garous-de-thiercelieux-ont-envahi-le-monde/ · https://www.lalibre.be/culture/2024/10/10/gare-aux-loups-garous-de-thiercelieux-FMNBY2MCSFFYROMNXKXXE5RIW4/
