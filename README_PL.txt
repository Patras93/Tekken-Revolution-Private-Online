TEKKEN REVOLUTION PRIVATE ONLINE - PATRAS1993 v2.2.0 RPCN DIRECT

========================================
ARCHITEKTURA v2.2.0
========================================

Tekken Revolution NPUB31250 dziala bez infrastruktury TekkenBTB.

Host:
- prywatny RPCN 1.10.0 / protocol 32,
- Tailscale,
- natywny patch RPCS3,
- brak backendu HTTPS,
- brak launchera/hooka BTB,
- brak domen BTB w Windows HOSTS.

Guest:
- RPCS3,
- Tekken Revolution NPUB31250 01.05,
- Tailscale,
- bezposrednie polaczenie RPCN do adresu Tailscale hosta,
- natywny patch RPCS3.

Backend TCP 443 nie jest wymagany.

========================================
HOST
========================================

1. Zainstaluj i polacz Tailscale.
2. Uruchom jako administrator:
   Host\Setup Patras1993 Host.cmd
3. Uruchom:
   Host\Start Patras1993 Host.cmd
4. Podaj kolezance adres Tailscale 100.x.x.x.

Setup:
- sprawdza RZECZYWISTA wersje rpcn.exe,
- wymaga RPCN 1.10.0 / protocol 32,
- automatycznie naprawia stary RPCN,
- instaluje natywny patch NPUB31250,
- ustawia RPCN hosta na 127.0.0.1,
- usuwa historyczne aliasy BTB z Windows HOSTS,
- otwiera TCP 31313 i UDP 3657,
- nie uruchamia ani nie instaluje backendu HTTPS.

========================================
GUEST
========================================

1. Dolacz do tej samej sieci Tailscale.
2. Uruchom jako administrator:
   Guest\Setup Online Guest.cmd
3. Podaj adres Tailscale hosta.
4. Przy pierwszym polaczeniu utworz konto RPCN na prywatnym serwerze Patras1993.
5. Zamknij RPCS3 i uruchom:
   Guest\Private Match ON.cmd
6. Uruchom:
   Guest\Start Online Guest.cmd

Guest laczy RPCN bezposrednio do:
100.x.x.x:31313

Nie potrzebuje zadnych domen BTB ani backendu 443.

========================================
PRIVATE MATCH
========================================

Preset:
- HP obu graczy nie spada,
- czas rundy jest nieskonczony,
- pierwszego do 5 wygranych rund,
- maksymalnie 9 rund,
- Final Round przy 4:4.

========================================
ZWERYFIKOWANE WERSJE
========================================

RPCS3 preferowany:
0.0.43-20161-96ccd89c

Pelny commit RPCS3:
96ccd89cd6931c32e66ef5c5e4f823e210c24c15

RPCS3 fallback:
0.0.43-20147-dfc0542a

RPCN:
1.10.0
protocol 32

Tekken Revolution:
NPUB31250
01.05

========================================
POTWIERDZONE 2026-10-02
========================================

- prywatny RPCN dziala,
- konto Patras1993 uwierzytelnia sie na prywatnym RPCN,
- Tekken Revolution wchodzi do online,
- Private Match dziala,
- Tailscale host/guest dziala,
- po usunieciu domen BTB z HOSTS gra nadal dziala,
- backend HTTPS 443 nie jest potrzebny do polaczenia online.

Wykryty i naprawiony blad:
rpcn_version.txt wskazywal 1.10.0, ale faktyczny rpcn.exe byl 1.8.7.
Od v2.2.0 Setup i Start sprawdzaja rzeczywista wersje rpcn.exe.

========================================
BACKUP
========================================

Host\Backup Patras1993.cmd

Backup zawiera:
- Host,
- local_rpcn wraz z prywatna baza kont i kluczami,
- local_patch,
- wazne ustawienia RPCS3,
- dev_hdd0\home,
- informacje Tailscale.

Nie zawiera:
- calej gry,
- calego RPCS3,
- backendu HTTPS, bo v2.2.0 go nie uzywa.

Backup jest prywatny: zawiera baze kont RPCN i klucze.

Restore:
Host\Restore Patras1993.cmd

========================================
DOSTEPNOSC
========================================

Skrypty sa tekstowe, klawiaturowe i przygotowane pod NVDA.
Komunikaty podaja stan RPCN, Tailscale i patcha bez potrzeby odczytu elementow graficznych.
