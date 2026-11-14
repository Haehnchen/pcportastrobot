"""Find the initial 60 Hz step block in a writable segment of a converted ELF."""
from pathlib import Path
import struct
import sys

data = Path(sys.argv[1]).read_bytes()
if data[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<H", data, 16)[0] != 2:
    sys.exit("Expected a converted little-endian ELF64 executable")
offset = struct.unpack_from("<Q", data, 32)[0]
size, count = struct.unpack_from("<HH", data, 54)
pattern = struct.pack("<dfIQ", 60.0, 1.0 / 60.0, 0, 16666)
candidates = []
for index in range(count):
    kind, flags, start, address, _, length, _, _ = struct.unpack_from("<IIQQQQQQ", data, offset + index * size)
    if kind != 1 or flags & 6 != 6:
        continue
    position = start
    while True:
        position = data.find(pattern, position, start + length)
        if position < 0:
            break
        candidates.append(address + position - start)
        position += len(pattern)
if len(candidates) != 1:
    sys.exit(f"Expected one game-step candidate, found {len(candidates)}; correction disabled")
print(hex(candidates[0]))
