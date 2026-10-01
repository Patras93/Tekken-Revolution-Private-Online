# Patras1993 RPCS3 HP Trace

Offline-only diagnostic build recipe for Tekken Revolution NPUB31250 01.05.

Pinned upstream:
- RPCS3 0.0.43-20147-dfc0542a
- commit dfc0542a9fbf9a23b0b8aa526ff0e8430127719f

Trace targets:
- P1 current-health candidate: guest 0x012D9F74
- P2 counterpart: guest 0x012DC414

The diagnostic RPCS3 logs every PPU Interpreter write overlapping either 4-byte field:

`PATRAS1993_HP_WRITE cia=0x........ addr=0x........ size=...`

The normal Patras1993 RPCS3 installation is not modified. This build is only for finding the exact game instruction that updates HP, after which the final gameplay change belongs in the normal RPCS3 patch YAML.
