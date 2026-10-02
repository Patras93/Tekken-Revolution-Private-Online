#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: apply_trace_patch.py <rpcs3-source-dir>")

root = Path(sys.argv[1]).resolve()
vm_h = root / "rpcs3" / "Emu" / "Memory" / "vm.h"
ppu_cpp = root / "rpcs3" / "Emu" / "Cell" / "PPUInterpreter.cpp"
build_sh = root / ".ci" / "build-windows-clang.sh"

def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected exactly one match, got {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")

replace_once(
    vm_h,
    "void ppubreak(ppu_thread& ppu);\n",
    "void ppubreak(ppu_thread& ppu);\n"
    "void patras1993_hp_trace(ppu_thread& ppu, u32 addr, u32 size);\n",
)

replace_once(
    vm_h,
    "\t\tg_base_addr[addr] = value;\n\n"
    "#ifdef RPCS3_HAS_MEMORY_BREAKPOINTS\n"
    "\t\tif (ppu && g_breakpoint_handler.HasBreakpoint(addr, breakpoint_types::bp_write))\n",
    "\t\tg_base_addr[addr] = value;\n\n"
    "#ifdef RPCS3_HAS_MEMORY_BREAKPOINTS\n"
    "\t\tif (ppu && ((addr >= 0x012D9F60 && addr <= 0x012D9F67) || "
    "(addr >= 0x012DC400 && addr <= 0x012DC407)))\n"
    "\t\t{\n"
    "\t\t\tpatras1993_hp_trace(*ppu, addr, 1);\n"
    "\t\t}\n\n"
    "\t\tif (ppu && g_breakpoint_handler.HasBreakpoint(addr, breakpoint_types::bp_write))\n",
)

replace_once(
    vm_h,
    "#ifdef RPCS3_HAS_MEMORY_BREAKPOINTS\n"
    "\t\t\tif (ppu && g_breakpoint_handler.HasBreakpoint(addr, breakpoint_types::bp_write))\n",
    "#ifdef RPCS3_HAS_MEMORY_BREAKPOINTS\n"
    "\t\t\tif (ppu)\n"
    "\t\t\t{\n"
    "\t\t\t\tconst u64 write_end = static_cast<u64>(addr) + sizeof(dest_t) - 1;\n"
    "\t\t\t\tif ((addr <= 0x012D9F67 && write_end >= 0x012D9F60) || "
    "(addr <= 0x012DC407 && write_end >= 0x012DC400))\n"
    "\t\t\t\t{\n"
    "\t\t\t\t\tpatras1993_hp_trace(*ppu, addr, static_cast<u32>(sizeof(dest_t)));\n"
    "\t\t\t\t}\n"
    "\t\t\t}\n\n"
    "\t\t\tif (ppu && g_breakpoint_handler.HasBreakpoint(addr, breakpoint_types::bp_write))\n",
)

replace_once(
    ppu_cpp,
    "void ppubreak(ppu_thread& ppu)\n"
    "{\n",
    "void patras1993_hp_trace(ppu_thread& ppu, u32 addr, u32 size)\n"
    "{\n"
    "\tdebugbp_log.success(\"PATRAS1993_HP_WRITE cia=0x%08x addr=0x%08x size=%u\", ppu.cia, addr, size);\n"
    "}\n\n"
    "void ppubreak(ppu_thread& ppu)\n"
    "{\n",
)

replace_once(
    build_sh,
    "    -DBUILD_RPCS3_TESTS=OFF                            \\\n",
    "    -DHAS_MEMORY_BREAKPOINTS=ON                       \\\n"
    "    -DBUILD_RPCS3_TESTS=OFF                            \\\n",
)

print("Patras1993 HP trace instrumentation applied.")
print("Targets: P1 current HP 0x012D9F60..0x012D9F67, P2 current HP 0x012DC400..0x012DC407")
