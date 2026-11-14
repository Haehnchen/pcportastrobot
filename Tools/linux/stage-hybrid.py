"""Stage an isolated Linux Hybrid run from a converted Linux game directory."""
import argparse
from pathlib import Path
import shutil
import subprocess

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--source", type=Path, default=root / "Build/RunLinux21564")
parser.add_argument("--output", type=Path, default=root / "Build/RunLinuxHybrid")
args = parser.parse_args()
source = args.source.resolve()
output = args.output.resolve()
host = root / "Build/linux-hybrid-host/core/libs/libs"
gpu = root / "Build/linux-kyty/libkyty_gpu.so"
fresh = ("libc.prx", "libkernel.prx", "libScePad.prx", "libAstroHybridHost.prx")
shims = ("libSceAgc.prx", "libSceAgcDriver.prx", "libSceVideoOut.prx")
for required in (source / "AstroBot", source / "app0", gpu, *(host / name for name in fresh)):
    if not required.exists():
        parser.error(f"missing {required}; complete the hybrid build first")
if output.exists():
    parser.error(f"output already exists: {output}; choose a new directory")
(output / "libs").mkdir(parents=True)
shutil.copy2(source / "AstroBot", output / "AstroBot")
shutil.copytree(source / "app0", output / "app0", symlinks=True)
for item in (source / "libs").glob("*.prx"):
    if item.name not in fresh + shims:
        (output / "libs" / item.name).symlink_to(item.resolve())
for name in fresh:
    shutil.copy2(host / name, output / "libs" / name)
shutil.copy2(gpu, output / "libs" / gpu.name)
work = output / "shim-build"
work.mkdir()
for name in shims:
    assembly = '.section .note.GNU-stack,"",@progbits\n.text\n'
    if name == "libSceAgcDriver.prx":
        for nid, target in (("doCCHPPfxkI", "AstroHybridHostHdr_nid_no_patch"),
                            ("KMphJjTcNgk", "AstroHybridNoteReportedToneMapPeak_nid_no_patch")):
            assembly += f'.globl "{nid}"\n"{nid}":\n jmp {target}@PLT\n'
    asm = work / (name + ".S")
    asm.write_text(assembly)
    subprocess.run(["cc", "-shared", "-fPIC", str(asm), "-o", str(output / "libs" / name),
                    "-Wl,--no-as-needed", "-L" + str(output / "libs"), "-lkyty_gpu",
                    "-l:libAstroHybridHost.prx", "-Wl,-rpath,$ORIGIN", "-Wl,-z,defs"], check=True)
print(f"Staged {output}; GPU loader and game startup still require validation.")
