TEKKEN REVOLUTION PRIVATE ONLINE - GUEST
v2.2.2 RPCN DIRECT - AKTUALNY RPCS3

========================================
CO MUSISZ MIEC
========================================

- aktualny RPCS3 (stary build 20161 nie jest wymagany)
- Tekken Revolution NPUB31250 01.05
- Tailscale
- folder Guest

RPCS3 i gra nie sa czescia paczki.

========================================
KROK 1 - TAILSCALE
========================================

Dolacz do tej samej sieci Tailscale co host.
Host poda adres:
100.x.x.x

========================================
KROK 2 - SETUP
========================================

Uruchom jako administrator:

Setup Online Guest.cmd

Podaj tylko adres Tailscale hosta.

Skrypt:
- znajdzie RPCS3 z NPUB31250,
- wykryje RPCS3 bez wymuszania starego buildu,
- zainstaluje natywny patch Revolution,
- ustawi RPCN bezposrednio na adres Tailscale hosta,
- zachowa NPID/Password/Token,
- usunie historyczne aliasy BTB z HOSTS,
- nie doda zadnych nowych domen.

========================================
KROK 3 - KONTO RPCN
========================================

Konto oficjalnego RPCN nie jest kontem prywatnego serwera Patras1993.

Przy pierwszym polaczeniu:
1. Uruchom RPCS3.
2. Utworz osobne konto RPCN na serwerze Patras1993.
3. Zaloguj sie.
4. Komunikat "Twoje konto jest prawidlowe" oznacza sukces.

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

Uruchom:

Start Online Guest.cmd

Guest laczy sie bezposrednio:
RPCN -> adres Tailscale hosta -> TCP 31313 / UDP 3657

Backend HTTPS 443, launcher BTB i domeny BTB nie sa potrzebne.

========================================
RPCS3 I PATCH EVENTOW
========================================

Dzialajacy nowszy RPCS3 pozostaw bez zmian.
Setup i Start Guest nie wymuszaja wersji 20161 ani 20147.
Setup NIE nadpisuje odmiennego patcha znajdujacego sie w RPCS3.
Jesli uzywasz wlasnego dzialajacego patcha eventow, pozostanie na miejscu.

Update RPCS3 for Patras1993.cmd:
bezpieczna instrukcja aktualizacji; nie pobiera starej wersji,
nie nadpisuje katalogu emulatora.

Sam numer buildu nie potwierdza zgodnosci.
Sprawdz osobno eventy, logowanie RPCN i walke PvP z drugim graczem.

========================================
DOSTEPNOSC
========================================

Skrypty sa przygotowane do obslugi klawiatura i NVDA.
