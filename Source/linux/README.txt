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
The original baseline was built without NGX/Streamline; optional native NGX
build support and its current limitations are described below.

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

Experimental native DLSS SR and 2x Frame Generation (Linux, RTX 5060 Ti):
The Linux DLSS SDK is optional. Tested SDK: NVIDIA/DLSS revision
9981c6350dc58c0ce21f024fd65e31e851c31689 (Linux runtime 310.9.16).
SDK source: https://github.com/NVIDIA/DLSS
No SDK binaries are included in this repository.
Build with:
  KYTY_NGX_SDK_DIR="$PWD/Build/sdk/DLSS" bash Tools/linux/build-hybrid.sh
For a new staging directory, add --ngx-sdk Build/sdk/DLSS to stage-hybrid.py.
The starter sets ASTROHYBRID_CUDA_HOLE=1 and defaults the runtime path to
<run directory>/ngx-runtime when ASTROHYBRID_DLSS=1 or ASTROHYBRID_DLSSG=1.
The CUDA range is excluded from Linux guest arena reservations.

Start the experimental PPSA21564 profile (both features):
  bash Tools/linux/run-dlss-experimental.sh -skipIntro
SR only:
  ASTROHYBRID_DLSSG=0 bash Tools/linux/run-dlss-experimental.sh -skipIntro
The regular run-hybrid.sh keeps both features disabled by default.

PPSA21564 has temporal shader 5a34b303576ee324, unlike the Windows patch's
2936e5eca99d75e7. Its 64-byte constants use dwords 0/1 for output size,
2/3 for input size, 7 for the frame counter and 9 for motion-vector use.
The profile enables ASTROHYBRID_DLSS_LEGACY_EXPERIMENT=1 explicitly.
It uses zero jitter; camera samples had zero projection offsets, but moving
scene quality, camera cuts and jitter handling are not fully validated.
ASTROHYBRID_DLSS_DIAGNOSTICS=1 prints camera and rejected-buffer diagnostics.
SR quality selects the NGX preset family; it does not force the game's
render resolution. The game retains its own dynamic resolution decisions.

Native FG uses the direct Vulkan NGX API, not Windows Streamline. It currently
requires SR enabled to capture this profile's temporal inputs. Depth and
motion vectors are copied before later passes can overwrite them. Final
10-bit output is blitted into RGBA16F because the original packed format
lacks storage-image support. NGX writes a separate interpolation image;
the presenter submits it before the corresponding real image. The experimental
starter defaults KYTY_GPU_PRESENT_MODE=Immediate. The presenter spaces the
real image half a measured game-frame interval after its generated image
in non-FIFO modes. First/reset
frames are withheld. Swapchain presentation mode controls display pacing;
2x submissions do not guarantee twice the monitor's refresh rate. HUD
separation, adaptive multipliers, Reflex and multi-frame generation are
not implemented by this Linux backend. It remains experimental.

Local evidence:
- dlss-init.log: actual in-game NGX initialization reports SR available and
  native FG capability 1, initialization result 0x00000001 (success).
- dlss-legacy.log: repeated successful SR evaluations, including
  1920x1080 -> 2432x1368, no reported fallback in the sampled intervals.
- dlss-nativefg.png: visible galaxy map with both features active.
- dlss-nativefg-validation.log: over 1200 successful native FG evaluations;
  validation found a depth/stencil transition error, subsequently corrected.
- dlss-validation-baseline.log: no VUID errors before the pre-existing game
  assert "Duplicated definition name [astro]"; not a completed baseline run.
- dlss-nativefg-validation-fixed.log: over 1500 successfully evaluated and
  presented generated frames after fixing the depth/stencil barrier, with
  the Khronos validation library loaded and no VUID errors observed.
No FPS uplift or long-term stability claim is made from these tests.
Presentation counters measure submissions, not monitor scanout FPS.

The FIFO smoke test stalled heavily on this X11/compositor setup; FIFO is
not the experimental starter default. See dlss-fifo-smoke.log.

Final paced Immediate smoke test: dlss-paced-smoke.log reports over 2100
successful FG evaluations and generated-frame presentations, with SR
1920x1080 -> 2432x1368 and no fallbacks in sampled intervals. The galaxy
map is visible in dlss-paced.png. This is not a controlled FPS benchmark.
