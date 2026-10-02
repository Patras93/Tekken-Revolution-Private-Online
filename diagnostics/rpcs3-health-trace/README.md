# Patras1993 RPCS3 Health Trace

Diagnostic-only build for Tekken Revolution NPUB31250 01.05.

Confirmed from mirrored raw P1/P2 captures:

- P1 current HP copy A: guest `0x012D9F60`
- P1 current HP copy B: guest `0x012D9F64`
- P1 max HP: guest `0x012D9F6C`
- P1 health percent: guest `0x012D9F76`
- P2 current HP copy A: guest `0x012DC400`
- P2 current HP copy B: guest `0x012DC404`
- P2 max HP: guest `0x012DC40C`
- P2 health percent: guest `0x012DC416`

The four captured states were internally consistent:
- full health = 160 and percent = 100,
- 11 HP -> 6 percent,
- 136 HP -> 85 percent,
- 127 HP -> 79 percent,
- 21 HP -> 13 percent.

The diagnostic RPCS3 logs every PPU Interpreter write overlapping either current-HP pair:

`PATRAS1993_HP_WRITE cia=0x........ addr=0x........ size=...`

Pinned upstream:
- RPCS3 0.0.43-20147-dfc0542a
- commit dfc0542a9fbf9a23b0b8aa526ff0e8430127719f

Use PPU Interpreter while tracing. The final gameplay patch must target the game instruction, not freeze guest RAM.
