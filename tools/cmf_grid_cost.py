"""Offline model of the grid fog's outline tracing: how many outline points a Velen-like mask gives per layer, and how
many survive the half-pixel thinning. A model of the shipped ActionScript (same distance field, same marching squares,
same thinning rule), not a Flash timing: Flash time is read from the 'grid id=' log line (dec/dist/squares/buckets/trace).
"""
import math
import sys
import numpy as np

TOL = 0.25 / 12  # map units, as _cmfGridTol


def mask(n=1294, seed=5):
    rng = np.random.default_rng(seed)
    m = np.zeros((n, n), bool)
    for _ in range(60):  # roads and clearings walked across the map
        x, y = rng.integers(100, n - 100, 2)
        heading = rng.uniform(0, 6.28)
        for _ in range(rng.integers(150, 500)):
            heading += rng.normal(0, 0.15)
            x, y = int(x + 2 * math.cos(heading)), int(y + 2 * math.sin(heading))
            if not (3 < x < n - 3 and 3 < y < n - 3):
                break
            m[y - 1:y + 2, x - 1:x + 2] = True
            if rng.random() < 0.01 and 20 < x < n - 20 and 20 < y < n - 20:
                r = rng.integers(4, 14)
                yy, xx = np.ogrid[-r:r + 1, -r:r + 1]
                m[y - r:y + r + 1, x - r:x + r + 1] |= (xx * xx + yy * yy <= r * r)
    return m


def edt(m):
    """Exact Euclidean distance to the nearest True cell (Felzenszwalb, two passes)."""
    inf = 1e20

    def one(f):
        n = len(f)
        d = np.empty(n)
        v = np.zeros(n, int)
        z = np.empty(n + 1)
        k = 0
        z[0], z[1] = -inf, inf
        for q in range(1, n):
            while True:
                s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k])
                if s <= z[k] and k > 0:
                    k -= 1
                else:
                    break
            k += 1
            v[k] = q
            z[k], z[k + 1] = s, inf
        k = 0
        for q in range(n):
            while z[k + 1] < q:
                k += 1
            d[q] = (q - v[k]) ** 2 + f[v[k]]
        return d
    g = np.where(m, 0.0, inf)
    g = np.apply_along_axis(one, 0, g)
    g = np.apply_along_axis(one, 1, g)
    return np.sqrt(g)


def loops(dist, limit):
    """Marching squares outlines at one limit, as lists of points (cell units)."""
    h, w = dist.shape
    big = dist > limit
    kind = big[:-1, :-1] * 8 + big[:-1, 1:] * 4 + big[1:, 1:] * 2 + big[1:, :-1] * 1
    links = {}

    def point(eid):
        cell, down = divmod(eid, 2)
        r, c = divmod(cell, w)
        a = dist[r, c]
        b = dist[r + 1, c] if down else dist[r, c + 1]
        f = min(1, max(0, (limit - a) / (b - a))) if b != a else .5
        return (c, r + f) if down else (c + f, r)

    def link(a, b):
        links.setdefault(a, []).append(b)
        links.setdefault(b, []).append(a)
    for r, c in zip(*np.nonzero((kind != 0) & (kind != 15))):
        cell = r * w + c
        top, bottom, left, right = cell * 2, (cell + w) * 2, cell * 2 + 1, (cell + 1) * 2 + 1
        k = kind[r, c]
        if k in (1, 14): link(left, bottom)
        elif k in (2, 13): link(bottom, right)
        elif k in (3, 12): link(left, right)
        elif k in (4, 11): link(top, right)
        elif k in (6, 9): link(top, bottom)
        elif k in (7, 8): link(left, top)
        elif k == 5: link(left, top); link(bottom, right)
        else: link(top, right); link(left, bottom)
    seen, out = set(), []
    for start in links:
        if start in seen:
            continue
        pts, prev, cur, closed = [], -1, start, True
        pts.append(point(cur))
        while cur not in seen:
            seen.add(cur)
            pair = links[cur]
            if len(pair) < 2:
                closed = False
                break
            nxt = pair[0] if pair[0] != prev else pair[1]
            prev, cur = cur, nxt
            pts.append(point(cur))
        out.append((pts, closed))
    return out


def thin(pts, tol):
    m = len(pts)
    if m < 8:
        return m
    kept, anchor, i = 2, 0, 1
    while i < m - 1:
        dx, dy = pts[i + 1][0] - pts[anchor][0], pts[i + 1][1] - pts[anchor][1]
        length = math.hypot(dx, dy)
        ok = length > 0 and all(abs((pts[k][0] - pts[anchor][0]) * dy - (pts[k][1] - pts[anchor][1]) * dx) <= tol * length
                                for k in range(anchor + 1, i + 1))
        if not ok:
            kept += 1
            anchor = i
        i += 1
    return kept


def main(argv):
    cell_units = float(argv[1]) if len(argv) > 1 else 3.2  # map units per cell at zoom 1 (assumed; see PR)
    n = 1294
    soft, layers = 15.0, 128
    m = mask(n)
    print("mask n=%d clear cells=%d (%.1f%%)" % (n, m.sum(), 100 * m.mean()))
    d = edt(m)
    total = kept = 0
    for j in range(0, layers + 1, 16):
        limit = 0.5 + j * (soft - 0.5) / layers
        pts = loops(d, limit)
        p = sum(len(a) for a, _ in pts)
        k = sum(thin(a, TOL / cell_units) if c else len(a) for a, c in pts)
        total, kept = total + p, kept + k
        print("layer %3d limit %5.2f cells: %6d points, %6d kept after thinning (%.0f%%)" % (j, limit, p, k, 100 * k / max(p, 1)))
    print("sampled layers: %d points -> %d (%.0f%% kept) at %.1f map units per cell; tolerance %.4f units = %.4f cells"
          % (total, kept, 100 * kept / total, cell_units, TOL, TOL / cell_units))


if __name__ == "__main__":
    main(sys.argv)
