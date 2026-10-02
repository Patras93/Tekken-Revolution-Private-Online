TEKKEN REVOLUTION PRIVATE ONLINE - GUEST
v1.2.1

========================================
CO MUSISZ MIEC
========================================

- RPCS3
- Tekken Revolution NPUB31250
- Tailscale
- ten folder Guest

RPCS3 i Tekken Revolution nie sa czescia tego folderu.

========================================
KROK 1 - TAILSCALE
========================================

Dolacz do tej samej sieci Tailscale co osoba uruchamiajaca hosta.

Host poda Ci swoj adres Tailscale w postaci:
100.x.x.x

========================================
KROK 2 - KONFIGURACJA
========================================

Uruchom:

Setup Online Guest.cmd

jako administrator.

Skrypt poprosi tylko o:
1. adres Tailscale hosta.

Nie musisz podawac sciezki do RPCS3.

Skrypt automatycznie:
- znajdzie rpcs3.exe,
- znajdzie katalog RPCS3,
- sprawdzi Tekken Revolution NPUB31250,
- ustawi polaczenie z hostem,
- przygotuje konfiguracje.

========================================
KROK 3 - KONTO RPCN PATRAS1993
========================================

Konto na oficjalnym RPCN nie jest automatycznie kontem na prywatnym serwerze Patras1993.

Jesli laczysz sie z Patras1993 pierwszy raz:
1. Uruchom RPCS3 po wykonaniu Setup Online Guest.cmd.
2. W ustawieniach RPCN wybierz serwer Patras1993.
3. Utworz osobne konto RPCN na tym serwerze.
4. Zaloguj sie na utworzone konto.

Serwer Patras1993 nie wymaga potwierdzania adresu e-mail.

========================================
KROK 4 - URUCHOMIENIE
========================================

Po skonfigurowaniu i zalogowaniu konta uruchom:

Start Online Guest.cmd

Gra zostanie uruchomiona z wykrytego automatycznie katalogu RPCS3.

========================================
WAZNE
========================================

Guest NIE uruchamia lokalnego:
- backendu,
- RPCN.

Guest laczy sie z hostem przez Tailscale.

Nie kopiuj:
- USRDIR,
- EBOOT.BIN,
- calego RPCS3

do folderu Guest.

========================================
DOSTEPNOSC
========================================

Skrypty sa przygotowane tak, aby konfiguracja byla mozliwa z klawiatury i z NVDA.

========================================
PROBLEM
========================================

Jesli RPCS3 nie zostanie znaleziony:
- upewnij sie, ze rpcs3.exe znajduje sie na lokalnym dysku,
- upewnij sie, ze Tekken Revolution jest zainstalowany jako NPUB31250,
- sprawdz, czy Tailscale jest uruchomiony,
- sprawdz adres Tailscale podany przez hosta.
