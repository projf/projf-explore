#!/usr/bin/env python3

from math import sin, pi

# math.sin works in radians
# 0-90° = 0-π/2 radians

for i in range(64):
    val = pi/(2*64) * i
    res = round(255 * sin(val))
    print("{:02X}".format(res))
