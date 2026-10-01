TEKKEN REVOLUTION PRIVATE ONLINE - PATRAS1993 v2.0

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
- otwiera UDP 3657.

========================================
GUEST
========================================

1. Obie osoby muszą być w tej samej sieci Tailscale.
2. Uruchom:
   Guest\Setup Online Guest.cmd
   jako administrator.
3. Podaj adres Tailscale hosta.
4. Skrypt wykryje RPCS3 i zapisze jego ścieżkę.
5. Uruchom:
   Guest\Start Online Guest.cmd

========================================
RPCS3
========================================

Docelowa instalacja użytkownika:

E:\instalacje gier\rpcs3-v0.0.43-20146-4d88114c_win64

Repo nie zawiera RPCS3 ani plików gry.

Gra:
dev_hdd0\game\NPUB31250

========================================
STATUS v2.0
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

Do przetestowania:
- certyfikat HTTPS na hoście,
- logowanie RPCN: POTWIERDZONE,
- pobieranie danych Revolution,
- wejście obu klientów do online,
- pokój prywatny,
- gra host/guest.

Nie testujemy TK5DR, Tekken 6 ani Tag 2 w tym projekcie.


========================================
POTWIERDZONE 2026-10-01
========================================

RPCN 1.10.0 / protocol 32: POTWIERDZONE.
RPCS3: konto RPCN prawidlowe na lokalnym serwerze Patras1993.
TCP 31313 i UDP 3657: nasluchuja.
