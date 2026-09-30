TEKKEN REVOLUTION PRIVATE ONLINE v1.2.0

========================================
CO JEST W PACZCE
========================================

Paczka zawiera tylko nasze pliki serwera i narzedzia.
Nie zawiera RPCS3 ani plikow gry Tekken Revolution.

Zawartosc:
- local_backend - backend prywatnego online
- local_rpcn - lokalny RPCN
- modules - nasze moduly
- patches - nasze patche
- Guest - konfiguracja dla osoby dolaczajacej
- skrypty Host
- README_PL.txt

========================================
HOST - TWOJ KOMPUTER
========================================

1. Zainstaluj i uruchom Tailscale.
2. Uruchom:
   Setup Online Host.cmd
   jako administrator.
3. Uruchom:
   Start Tekken Revolution Online Host.cmd
4. Odczytaj swoj adres Tailscale 100.x.x.x.
5. Podaj ten adres kolezance.

Host uruchamia backend i RPCN.
Nie trzeba przenosic RPCS3 do folderu serwera.

========================================
GUEST - KOMPUTER KOLEZANKI
========================================

Kolezanka potrzebuje:
- wlasnej instalacji RPCS3,
- wlasnej kopii Tekken Revolution NPUB31250,
- Tailscale,
- folderu Guest z tej paczki.

1. Dolacz do tej samej sieci Tailscale co host.
2. Uruchom:
   Guest\Setup Online Guest.cmd
   jako administrator.
3. Podaj adres Tailscale hosta, np. 100.x.x.x.
4. Skrypt AUTOMATYCZNIE SZUKA RPCS3.
   Nie trzeba podawac sciezki do rpcs3.exe.
5. Skrypt sprawdza obecność Tekken Revolution NPUB31250.
6. Po konfiguracji uruchom:
   Guest\Start Online Guest.cmd

Guest nie uruchamia lokalnego backendu ani lokalnego RPCN.
Laczy sie z hostem przez Tailscale.

========================================
WYMAGANIA
========================================

- Windows
- RPCS3
- Tekken Revolution NPUB31250
- Tailscale
- uprawnienia administratora podczas konfiguracji

RPCS3 i Tekken Revolution NIE sa czescia tego repozytorium.

========================================
SCIEZKI
========================================

RPCS3 moze znajdowac sie w dowolnym miejscu.
Paczka serwera moze znajdowac sie w dowolnym miejscu.
Nie sa wymagane stale sciezki typu E:\tr\... .

========================================
AKTUALIZACJE
========================================

Aktualizacje serwera, patchy i narzedzi sa dostarczane przez repozytorium.
Nie trzeba kopiowac calego katalogu USRDIR do paczki serwera.

========================================
TRYB ONLINE
========================================

Host = backend + RPCN + Tailscale.
Guest = RPCS3 + Tekken Revolution + Tailscale.

Docelowo system obsluguje prywatna gre online oraz nasz tryb Practice online.
