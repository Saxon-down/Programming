#!/usr/bin/env python3
import decimal
from decimal import Decimal

def _round(x) :
    # Round away from 0 (so 2.5 -> 3, -2.5 -> -3)
    from math import copysign
    return int(x + 0.5 * copysign(1, x))

x2_5 = round(2.5)   # Built-in 'round' function uses
x3_5 = round(3.5)   # .. Banker's Rounding
# Banker's Rounding rounds to an even least-significant digit
y2_5 = _round(2.5)
y3_5 = _round(3.5)

print(x2_5, y2_5, x3_5, y3_5)

with decimal.localcontext() as ctx :
    ctx.prec = 2
    ctx.rounding = decimal.ROUND_HALF_UP
    # Everything else within this WITH loop will use this
    # local context that we've defined
    print("WITH Loop:")
    print("\tCurrent decimal context: ", decimal.getcontext())
    print("\tRounding: ", decimal.getcontext().rounding)
    print()
# No longer in the localcontext, back to global
print("Current decimal context: ", decimal.getcontext())
print("Current rounding: ", decimal.getcontext().rounding)