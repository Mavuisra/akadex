"""HyperLogLog minimal (p=8 → 256 registres ≈ 256 octets).

Suffisant pour estimer les visiteurs uniques d’un cours sans stocker
chaque ID. Erreur relative typique ~1–2 % pour des cardinaux modérés.
"""

from __future__ import annotations

import hashlib
import math
import struct

# 2^8 registres — compact et assez précis pour des cours.
HLL_P = 8
HLL_M = 1 << HLL_P
# Constante classique Flajolet pour m >= 128.
HLL_ALPHA = 0.7213 / (1.0 + 1.079 / HLL_M)


def _hash64(value: str) -> int:
    digest = hashlib.sha256(value.encode('utf-8')).digest()
    return struct.unpack('>Q', digest[:8])[0]


def empty_sketch() -> bytearray:
    return bytearray(HLL_M)


def merge_register(sketch: bytearray | bytes, value: str) -> bytearray:
    """Ajoute un identifiant visiteur ; retourne le sketch mis à jour."""
    buf = bytearray(sketch) if sketch else empty_sketch()
    if len(buf) != HLL_M:
        buf = empty_sketch()
    h = _hash64(value)
    idx = h & (HLL_M - 1)
    w = h >> HLL_P
    width = 64 - HLL_P
    if w == 0:
        rho = width + 1
    else:
        # Nombre de zéros de tête + 1 (définition HyperLogLog).
        rho = width - w.bit_length() + 1
    rho = min(255, max(1, rho))
    if rho > buf[idx]:
        buf[idx] = rho
    return buf


def estimate(sketch: bytes | bytearray | None) -> int:
    """Cardinalité estimée (visiteurs uniques)."""
    if not sketch:
        return 0
    buf = bytes(sketch)
    if len(buf) != HLL_M:
        return 0
    inv_sum = 0.0
    zeros = 0
    for reg in buf:
        inv_sum += math.pow(2.0, -reg)
        if reg == 0:
            zeros += 1
    if inv_sum <= 0:
        return 0
    raw = HLL_ALPHA * (HLL_M ** 2) / inv_sum
    # Correction petits cardinaux (LinearCounting).
    if raw <= 2.5 * HLL_M and zeros > 0:
        return max(0, int(round(HLL_M * math.log(HLL_M / zeros))))
    return max(0, int(round(raw)))
