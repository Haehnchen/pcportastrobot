Experimental native AstroHybrid Linux port

These patches apply AFTER the complete existing Windows hybrid series:

AnyPS5 base: 319621ba2e578bd053b0baba2877fe70520e0737
  git am --keep-cr <repo>/Source/anyps5/*.patch
  git apply <repo>/Source/linux/anyps5-hybrid-linux.patch

KytyPS5 base: u59-windows-20261024-int21
  git am --keep-cr <repo>/Source/kyty-hybrid/*.patch
  git apply <repo>/Source/linux/kyty-hybrid-linux.patch

Initialize recursive submodules in both source trees. Build dependencies
include Clang, Ninja, CMake, glslang-tools and Linux audio/window headers.
Expected checkout directories: Tools/AnyPS5 and Tools/kyty-int21.
Build: bash Tools/linux/build-hybrid.sh

This is work in progress, not the previously demonstrated AnyPS5 renderer.
The initial changes add an ELF shared-library target, System V lazy binding,
NID symbol aliases, dlopen/dlsym host loading and Linux memory-map checks
for the optional game-step correction. No claim of a running Kyty hybrid
on Linux until shared-library build, loader checks and a game run pass.
The game-step address must be verified for the actual dump before enabling
the correction; the Windows version's default address is not portable
between different game versions.

Validation, 2026-11-14
----------------------
libkyty_gpu.so builds and links with -z defs. ldd -r reports no unresolved
symbols. A startup-loaded library export test resolves all 101 NIDs,
accepts ABI 1.5 and rejects ABI 2. Load it as an ELF dependency (as the
staging shims do): late dlopen into Python failed its static TLS allocation.

The host libc/kernel/pad/HybridHost builds and NID patching completed.
The native hybrid run reports "Kyty renderer running", uses RTX 5060 Ti,
and renders the PlayStation Studios logo and the animated loading tunnel.
Screenshots in Build/RunLinuxHybrid: kyty-first.png, kyty-later.png,
kyty-speed.png (56/58 FPS overlay snapshots of loading, not a benchmark).

Linux adoption of donated guest ranges and chained SIGSEGV/SIGBUS fault
handling are implemented. Optional Windows DLSS diagnostics are guarded;
NGX/Streamline features are NOT built into this Linux library.

Stage: python3 Tools/linux/stage-hybrid.py
Start: bash Tools/linux/run-hybrid.sh
The existing run.sh still selects the standalone AnyPS5 bootstrap.
The Hybrid starter detects the unique writable ELF 60 Hz step block;
for this PPSA21564 dump it is 0x93d4040. The runtime checks the live values
and logs "game rate 60, real-time step on". Sound synchronization has not
been independently measured. Commit-epoch fast path is enabled.

Remaining issue: hybrid-visual.log stops later at ObjectDefinitionContext.cpp:89,
"Duplicated definition name [space_station_asteroid_b]", with the base and
~asteroid_mblue assets named. No assert bypass or asset removal was applied.
Stable title/menu/gameplay and long-term signal-chain behavior still need
validation. Logs and screenshots are local Build artifacts, not shipped.

Latest retest: hybrid-speed.log enables real-time step and the commit-epoch
fast path. It reaches the space scene (kyty-scene.png, 59 FPS overlay
snapshot) without repeating the object-definition assert during that test.
The earlier assert is still considered intermittent/unresolved, not fixed.
Tools/linux/run.sh now delegates to run-hybrid.sh; run-anyps5.sh retains
an explicit standalone-renderer comparison path.
