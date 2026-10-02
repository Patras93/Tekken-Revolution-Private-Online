# Patras1993 RPCS3 Candidate Trace

Diagnostic-only experiment for Tekken Revolution NPUB31250 01.05.

## Important

The old addresses below are **NOT confirmed current-health fields**:

- P1 candidate: guest `0x012D9F74`
- P2 counterpart: guest `0x012DC414`

A stronger cross-check showed that this region belongs to the player/position block and the original
`100 -> 15` observation is not sufficient to identify HP. Do not use these addresses for an
Infinite Health patch.

The workflow is manual-only until `Host/Find Revolution P1 Health.ps1` v2 identifies a field that:

1. decreases only when P1 is damaged,
2. resets at the next round,
3. has the mirrored P2 offset,
4. decreases only when P2 is damaged.

After the real current-health addresses are confirmed, retarget the tracer and use the logged PPU
`cia` to find the exact native damage instruction.

Pinned upstream:
- RPCS3 0.0.43-20147-dfc0542a
- commit dfc0542a9fbf9a23b0b8aa526ff0e8430127719f
