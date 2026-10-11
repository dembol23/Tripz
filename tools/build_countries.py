#!/usr/bin/env python3
"""Builds countries.json for Tripz from Natural Earth 1:50m Admin 0 Countries.

Natural Earth is public domain: https://www.naturalearthdata.com/about/terms-of-use/

Usage:
    curl -L -o ne_50m_admin_0_countries.geojson \
      https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_admin_0_countries.geojson
    python3 tools/build_countries.py ne_50m_admin_0_countries.geojson countries.json

Output format (version 1), compact on purpose:/Users/wiktordembny/Downloads/countries.json
    {"version": 1, "scale": 1000, "source": "...",
     "countries": [{"code": "CH",
                    "polygons": [ [ [x,y,x,y,...],   <- outer ring
                                    [x,y,x,y,...] ], <- hole (optional)
                                  ... ]}]}
Coordinates are integers: degrees * scale, as longitude then latitude.
Rings are open (the closing point is not repeated).
"""
import json
import math
import sys

SCALE = 1000          # 0.001 degree is roughly 110 m
TOLERANCE_DEG = 0.003 # simplification, roughly 330 m


def valid_code(value):
    return isinstance(value, str) and len(value) == 2 and value.isalpha()


def point_segment_distance(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    length_sq = dx * dx + dy * dy
    if length_sq == 0:
        return math.hypot(p[0] - a[0], p[1] - a[1])
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / length_sq))
    return math.hypot(p[0] - (a[0] + t * dx), p[1] - (a[1] + t * dy))


def simplify(points, tolerance):
    """Iterative Ramer-Douglas-Peucker, keeping both ends."""
    if len(points) <= 2:
        return points
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        first, last = stack.pop()
        if last - first < 2:
            continue
        far_i, far_d = first, 0.0
        for i in range(first + 1, last):
            d = point_segment_distance(points[i], points[first], points[last])
            if d > far_d:
                far_i, far_d = i, d
        if far_d > tolerance:
            keep[far_i] = True
            stack.append((first, far_i))
            stack.append((far_i, last))
    return [p for p, k in zip(points, keep) if k]


def process_ring(ring):
    pts = [tuple(p[:2]) for p in ring]
    if len(pts) > 1 and pts[0] == pts[-1]:
        pts = pts[:-1]                       # open ring
    pts = simplify(pts, TOLERANCE_DEG)
    quantized = []
    for lon, lat in pts:
        q = (round(lon * SCALE), round(lat * SCALE))
        if not quantized or quantized[-1] != q:
            quantized.append(q)
    if len(quantized) > 1 and quantized[0] == quantized[-1]:
        quantized.pop()
    return quantized if len(quantized) >= 3 else None


def main(src, dst):
    with open(src) as f:
        data = json.load(f)

    by_code = {}
    skipped = []
    for feature in data["features"]:
        props = feature["properties"]
        code = props["ISO_A2_EH"]            # plain ISO_A2 is -99 for France, Norway...
        if not valid_code(code):
            skipped.append(props["NAME"])
            continue
        geometry = feature["geometry"]
        polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" \
            else [geometry["coordinates"]]
        for polygon in polygons:
            rings = [process_ring(r) for r in polygon]
            if rings[0] is None:
                continue                      # outer ring vanished: tiny speck
            rings = [rings[0]] + [r for r in rings[1:] if r is not None]
            by_code.setdefault(code, []).append(
                [[c for point in r for c in point] for r in rings]
            )

    countries = [{"code": c, "polygons": by_code[c]} for c in sorted(by_code)]
    out = {
        "version": 1,
        "scale": SCALE,
        "source": "Natural Earth 1:50m Admin 0 Countries (public domain)",
        "countries": countries,
    }
    with open(dst, "w") as f:
        json.dump(out, f, separators=(",", ":"))

    vertices = sum(len(r) // 2 for c in countries for p in c["polygons"] for r in p)
    print(f"countries: {len(countries)}  polygons: {sum(len(c['polygons']) for c in countries)}"
          f"  vertices: {vertices}")
    print("skipped (no ISO code):", ", ".join(skipped))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
