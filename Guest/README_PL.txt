TEKKEN REVOLUTION PRIVATE ONLINE - GUEST
v2.2.1 RPCN DIRECT - TAILSCALE HOTFIX

========================================
CO MUSISZ MIEC
========================================

- RPCS3 0.0.43-20161-96ccd89c (preferowany)
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
- sprawdzi obslugiwany build RPCS3,
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
