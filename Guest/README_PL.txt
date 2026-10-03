TEKKEN REVOLUTION PRIVATE ONLINE - GUEST
v2.2.0 RPCN DIRECT + PATRAS TEKKEN TUNNEL

========================================
CO MUSISZ MIEC
========================================

- RPCS3 0.0.43-20161-96ccd89c (preferowany)
- Tekken Revolution NPUB31250 01.05
- Patras Tekken Client Native
- folder Guest

RPCS3 i gra nie sa czescia paczki.
Tailscale NIE jest potrzebny.

========================================
KROK 1 - PATRAS TEKKEN CLIENT
========================================

Uruchom Patras Tekken Client.exe.

Przy pierwszej konfiguracji:
- aktywuj swoje darmowe konto zrok,
- wklej kod PTT1 otrzymany od Patras1993,
- wskaz rpcs3.exe,
- wykonaj Konfiguracja pierwszy raz.

Do normalnej gry:
- uruchom Client,
- nacisnij Polacz albo Uruchom Tekken.

Client tworzy lokalne konce tunelu:
TCP 127.0.0.1:31313
UDP 127.0.0.1:3657

========================================
KROK 2 - SETUP GUEST
========================================

Uruchom jako administrator:

Setup Online Guest.cmd

Skrypt:
- NIE pyta o adres hosta,
- NIE uzywa Tailscale,
- znajdzie RPCS3 z NPUB31250,
- sprawdzi obslugiwany build RPCS3,
- zainstaluje natywny patch Revolution,
- ustawi RPCN na 127.0.0.1,
- zachowa NPID/Password/Token,
- usunie historyczne aliasy BTB z HOSTS,
- nie doda zadnych nowych domen.

========================================
KROK 3 - KONTO RPCN
========================================

Konto oficjalnego RPCN nie jest kontem prywatnego serwera Patras1993.

Przy pierwszym polaczeniu:
1. Polacz Patras Tekken Client z Patras1993.
2. Uruchom RPCS3.
3. Utworz osobne konto RPCN na serwerze Patras1993.
4. Zaloguj sie.
5. Komunikat "Twoje konto jest prawidlowe" oznacza sukces.

========================================
KROK 4 - PRIVATE MATCH
========================================

Zamknij RPCS3 i uruchom:

Private Match ON.cmd

Preset:
- HP obu graczy nie spada,
- nieskonczony czas,
- pierwszego do 5 rund,
- maksymalnie 9 rund,
- Final Round przy 4:4.

========================================
KROK 5 - START
========================================

Najpierw Patras Tekken Client musi byc POLACZONY.

Nastepnie uruchom:

Start Online Guest.cmd

Guest laczy sie:
RPCS3 -> 127.0.0.1 -> Patras Tekken Client -> zrok -> Patras1993 Host
TCP 31313 / UDP 3657

Start sprawdza lokalnie:
- TCP 31313,
- UDP 3657.

Backend HTTPS 443, launcher BTB, domeny BTB i Tailscale nie sa potrzebne.

========================================
RPCS3
========================================

Preferowany:
0.0.43-20161-96ccd89c

Fallback:
0.0.43-20147-dfc0542a

Updater:
Update RPCS3 for Patras1993.cmd

========================================
DOSTEPNOSC
========================================

Skrypty sa przygotowane do obslugi klawiatura i NVDA.
