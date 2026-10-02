TEKKEN REVOLUTION PRIVATE ONLINE - PATRAS1993 v2.1.0 STABLE

========================================
CEL
========================================

Prywatny serwer Tekken Revolution NPUB31250.
BTB nie jest uruchamiany jako serwer ani launcher.
BTB pozostaje wyłącznie wzorcem kompatybilności.

Host:
- własny RPCN,
- własny backend,
- Tailscale,
- lokalne patche/moduły.

Guest:
- własny RPCS3,
- własna kopia Tekken Revolution NPUB31250,
- Tailscale,
- połączenie bezpośrednio do hosta.

========================================
WAŻNE
========================================

Nie usuwamy ani nie modyfikujemy instalacji BTB.
Nie jest potrzebny BTB Launcher.

Gra nadal używa nazw endpointów wymaganych przez obecny moduł
kompatybilności:
- patch.tekkenbtb.online
- rpcn.tekkenbtb.online

Guest wpisuje te nazwy lokalnie do hosts i kieruje je na adres
Tailscale hosta. Oznacza to, że ruch idzie do naszego komputera,
a nie do serwera BTB.

To jest etap niezależności infrastruktury. Później możemy usunąć
same nazwy BTB dopiero po potwierdzeniu, że moduł gry pozwala na
zmianę endpointów.

========================================
HOST
========================================

Repo najlepiej umieścić wewnątrz:

E:\instalacje gier\rpcs3-v0.0.43-20146-4d88114c_win64

1. Zainstaluj Tailscale.
2. Uruchom:
   Host\Setup Patras1993 Host.cmd
   jako administrator.
3. Uruchom:
   Host\Start Patras1993 Host.cmd
4. Odczytaj adres Tailscale 100.x.x.x.
5. Podaj go koleżance.

Setup:
- pilnuje RPCN 1.10.0 (protocol 32),
- w razie potrzeby pobiera oficjalny rpcn-win.zip 1.10.0,
- zachowuje lokalna konfiguracje i certyfikaty RPCN,
- tworzy/wybiera lokalny certyfikat backendu,
- otwiera TCP 443,
- otwiera TCP 31313,
- otwiera UDP 3657,
- ignoruje Kosz i katalogi systemowe przy wykrywaniu RPCS3,
- wybiera tylko instalacje RPCS3 zawierajaca NPUB31250.

Aktualny zestaw Host:
- Setup Patras1993 Host.cmd/.ps1,
- Start Patras1993 Host.cmd/.ps1,
- Start Patras1993 Host Silent.cmd,
- Stop Patras1993 Host.cmd/.ps1,
- Diagnose Patras1993.cmd/.ps1,
- Private Match ON.cmd,
- Private Match OFF.cmd,
- Set Private Match Rules.ps1.

Usuniete jako przestarzale:
- osobne Practice Online Health ON/OFF,
- osobne P1 Health Shield ON/OFF,
- skaner P1 Health,
- narzedzia testowe Decrypt Revolution EBOOT.

========================================
GUEST
========================================

1. Obie osoby muszą być w tej samej sieci Tailscale.
2. Uruchom:
   Guest\Setup Online Guest.cmd
   jako administrator.
3. Podaj adres Tailscale hosta.
4. Skrypt wykryje RPCS3 i zapisze jego ścieżkę.
5. Przed uruchomieniem gry zamknij RPCS3 i wlacz:
   Guest\Private Match ON.cmd
6. Uruchom:
   Guest\Start Online Guest.cmd

Private Match jest wspolnym presetem dla obu graczy:
- HP obu graczy nie spada,
- czas rundy jest nieskonczony,
- wygrana meczu wymaga 5 rund,
- maksymalnie 9 rund,
- Final Round przy 4:4.

========================================
RPCS3
========================================

Docelowa instalacja użytkownika:

E:\instalacje gier\rpcs3-v0.0.43-20146-4d88114c_win64

Repo nie zawiera RPCS3 ani plików gry.

Gra:
dev_hdd0\game\NPUB31250

========================================
STATUS v2.1.0 STABLE
========================================

Gotowe:
- lokalny RPCN,
- lokalny backend,
- backend dostępny na interfejsach sieciowych,
- Host setup,
- Host start,
- Guest zapisujący konfigurację,
- Guest start bez ręcznego wpisywania ścieżki RPCS3,
- Tailscale jako transport host <-> guest.

Wymagana para:
- RPCS3 0.0.43-20147-dfc0542a,
- RPCN 1.10.0,
- RPCN protocol 32.

Potwierdzone end-to-end 2026-10-02:
- certyfikat/backend HTTPS dziala w zestawie host/guest,
- logowanie do prywatnego RPCN dziala,
- pobieranie danych Revolution dziala,
- obaj klienci wchodza do online,
- pokoj prywatny dziala,
- gra host/guest dziala,
- Private Match dziala w realnym tescie z kolezanka.

Nie testujemy TK5DR, Tekken 6 ani Tag 2 w tym projekcie.


========================================
POTWIERDZONE 2026-10-01
========================================

RPCN 1.10.0 / protocol 32: POTWIERDZONE.
RPCS3: konto RPCN prawidlowe na lokalnym serwerze Patras1993.
TCP 31313 i UDP 3657: nasluchuja.


========================================
AKTUALIZACJA 2026-10-02
========================================

Host zostal uproszczony do jednego presetu Private Match.
Stare osobne przelaczniki zdrowia zostaly usuniete.
Host Start pokazuje adres Tailscale IPv4.
Host Diagnose sprawdza Tailscale, nasluch RPCN TCP 31313 i regule Windows Firewall.
Eksperymentalny P1 Health Shield zostal usuniety z patcha.


========================================
BACKUP STANU SERWERA
========================================

Stabilna galaz stable-v2.1.0 i paczki v2.1.0 zachowuja kod oraz konfiguracje bazowa.
Nie sa kopia zywej bazy kont utworzonych pozniej na prywatnym RPCN.

Aby zachowac aktualny stan hosta, uruchom:

Host\Backup Patras1993.cmd

Skrypt zatrzymuje hosta i tworzy:
Backups\Patras1993-Full-Backup-RRRRMMDD-GGMMSS.zip

Backup zawiera:
- caly local_rpcn, w tym runtimeowa baze kont RPCN i klucze,
- local_backend i local_patch,
- host_config.json,
- wazne ustawienia RPCS3,
- dev_hdd0\home,
- certyfikat backendu z kluczem prywatnym,
- informacje o aktualnym Tailscale.

Backup NIE zawiera calej gry ani calego RPCS3.

Aby odtworzyc ostatni backup:
Host\Restore Patras1993.cmd

Po Restore uruchom Setup Patras1993 Host.cmd jako administrator,
a potem Start Patras1993 Host.cmd.

Folder Backups i prywatne runtimeowe pliki RPCN sa ignorowane przez Git,
zeby baza kont i klucze nie trafily przypadkiem do repozytorium.
