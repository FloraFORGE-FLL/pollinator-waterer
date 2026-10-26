// Pollinator Waterer
// A five-petal flower dish that holds shallow water for bees, butterflies and
// small birds, on a stem that pushes into the garden soil.
//
//  - Shallow, sloped bowl so insects can walk in and out
//  - Smooth rolled rim, rounded bottom edge and soft notches between petals
//  - Grooves ("petal veins") run from the middle up the walls as footholds
//  - Spiral island in the center sits above the water as a landing pad
//  - Twist lock: push the stem's lugs up the slots under the dish, turn
//    until it clicks
//
// part = "print" lays out both pieces on the bed, ready to slice:
// dish upright (no supports), stem lying on a flat side (supports under the
// point and the peg).

/* [Part to show / export] */
part = "print"; // ["print", "assembled", "dish", "stem"]

/* [Color] */
print_color = "#EFE6D2"; // beige / off-white

/* [Flower shape] */
petals      = 5;
petal_r     = 42;   // radius of each petal lobe
petal_d     = 45;   // distance from center to each lobe's center
center_r    = 50;   // fills in the middle of the flower
notch_round = 6;    // how much the notches between petals are softened (mm)
rim_h       = 22;   // total dish height
wall        = 6;    // rim thickness
floor_t     = 4;    // floor thickness
outer_flare = 0.84; // bottom size vs. top (outer wall flares out like a flower)
bowl_slope  = 0.72; // floor size vs. rim opening (smaller = gentler slope)
smoothness  = 360;  // points around the flower outline

/* [Rounding] */
rim_round_out = 4;  // big roll on the outside of the rim
rim_round_in  = 2;  // smaller roll on the inside (rim_round_out + rim_round_in <= wall)
bottom_round  = 5;  // rounded bottom edge (kept at 45 degrees or steeper so it prints clean)

/* [Grooves] */
groove_r      = 1.4; // groove radius (depth into the surface)
groove_spread = 14;  // degrees between the veins on each petal

/* [Center spiral island] */
island_r_base    = 22;
island_r_top     = 15;
island_round     = 3;   // rounded top edge of the island
island_below_rim = 1;   // island top sits this far below the rim
spiral_turns     = 2.5;
spiral_w         = 1.6; // ridge width
spiral_h         = 1.5; // ridge height

/* [Stem] */
stem_d        = 24;   // across the flats of the octagon
stem_len      = 85;   // straight part
stake_len     = 35;   // centered point that goes into the soil
tip_d         = 3;
layout_gap    = 8;    // space between the two parts on the print bed

/* [Twist lock] */
peg_d      = 16;   // round peg on top of the stem
peg_len    = 12;
lugs       = 3;    // lugs on the peg / slots in the dish
lug_w      = 5;    // lug width
lug_h      = 3.5;  // lug height
lug_out    = 2.5;  // how far the lugs stick out from the peg
lug_z      = 6;    // bottom of the lugs, measured up from the stem shoulder
lug_phase  = 60;   // one lug points straight up when the stem lies on the bed
twist      = 45;   // degrees to turn to lock
lock_click = 0.3;  // detent bump; raise for a firmer click, 0 for none
fit        = 0.4;  // clearance between peg and socket

$fn = 96;

island_top = rim_h - island_below_rim;
stem_total = stake_len + stem_len;        // tip to shoulder (peg sits above this)
lug_r      = peg_d / 2 + lug_out;
lug_deg    = 2 * asin(lug_w / (peg_d + fit));   // lug's angular width where it is widest (at the bore)

// ---------- flower outline as a smooth radius-vs-angle function ----------
function vsum(v, i = 0) = i < len(v) ? v[i] + vsum(v, i + 1) : 0;

// distance from center to the edge of one petal lobe, `phi` degrees off its axis
function lobe_L(phi) =
    let(s = petal_d * sin(phi))
    abs(s) < petal_r ? petal_d * cos(phi) + sqrt(petal_r * petal_r - s * s) : 0;

// smooth max of all lobes and the center circle -> rounded notches
function R_at(t) =
    let(k = ln(2) / notch_round,
        terms = [for (i = [0 : petals - 1]) exp(k * lobe_L(t - i * 360 / petals))])
    ln(exp(k * center_r) + vsum(terms)) / k;

// ---------- dish cross-section ----------
// Each point is [a, b, z]: at angle t it sits at radius a * R_at(t) + b.
function arc(a, cb, cz, r, a0, a1, n) =
    [for (s = [0 : n]) let(ang = a0 + (a1 - a0) * s / n) [a, cb + r * cos(ang), cz + r * sin(ang)]];

R_typ  = 80;  // typical outline radius, used to match the curves to the wall angles
lean   = atan(R_typ * (1 - outer_flare) / rim_h);                         // outer wall lean
drop   = atan((rim_h - floor_t) / (R_typ * (1 - bowl_slope)));            // inner wall slope
rb     = bottom_round;
ro     = rim_round_out;
ri     = rim_round_in;
chamfer_b = -rb + rb * cos(45) - rb * (1 - sin(45));                      // 45-degree start on the bed

// top of the inside wall (where the inner rim roll ends), used by the grooves
in_top_b = -wall + ri + ri * cos(90 + drop);
in_top_z = rim_h - ri + ri * sin(90 + drop);

profile = concat(
    [[0.2, 0, 0]],
    [[outer_flare, chamfer_b, 0]],                                        // 45-degree foot
    arc(outer_flare, -rb, rb, rb, -45, -lean, 8),                         // rounded bottom edge
    arc(1, -ro, rim_h - ro, ro, -lean, 90, 24),                           // big outer roll
    arc(1, -wall + ri, rim_h - ri, ri, 90, 90 + drop, 10),                // inner roll
    [[bowl_slope, -wall * bowl_slope, floor_t]],                          // where wall meets floor
    [[0.2, 0, floor_t]]
);

module dish_body() {
    n = smoothness;
    m = len(profile);
    Rs  = [for (i = [0 : n - 1]) R_at(i * 360 / n)];
    pts = [for (j = [0 : m - 1]) for (i = [0 : n - 1])
              let(p = profile[j], t = i * 360 / n, r = p[0] * Rs[i] + p[1])
              [r * cos(t), r * sin(t), p[2]]];
    faces = [for (j = [0 : m - 1]) for (i = [0 : n - 1])
                let(j2 = (j + 1) % m, i2 = (i + 1) % n,
                    a = j * n + i, b = j2 * n + i, c = j2 * n + i2, d = j * n + i2)
                each [[a, b, c], [a, c, d]]];
    polyhedron(pts, faces, convexity = 6);
}

// ---------- grooves ----------
// One vein: runs across the floor, then climbs the sloped wall
module groove(a) {
    R  = R_at(a);
    r0 = island_r_base + 2;
    rf = bowl_slope * (R - wall);              // where floor meets wall
    rt = R + in_top_b;                         // top of the inside wall
    f  = 0.85;                                 // how far up the wall to go
    rw = rf + (rt - rf) * f;
    zw = floor_t + (in_top_z - floor_t) * f;
    rotate(a) {
        capsule([r0, 0, floor_t], [rf, 0, floor_t], groove_r);
        capsule([rf, 0, floor_t], [rw, 0, zw], groove_r);
    }
}

// rounded rod between two points (sphere ends + cylinder)
module capsule(p1, p2, r) {
    v = p2 - p1;
    L = norm(v);
    translate(p1) {
        sphere(r, $fn = 16);
        rotate([0, acos(v[2] / L), atan2(v[1], v[0])]) cylinder(r = r, h = L, $fn = 16);
    }
    translate(p2) sphere(r, $fn = 16);
}

module grooves() {
    step = 360 / petals;
    for (i = [0 : petals - 1]) {
        a = i * step;
        for (p = [-groove_spread, 0, groove_spread]) groove(a + p);
        groove(a + step / 2);                  // vein between petals
    }
}

// ---------- center island ----------
module spiral2d() {
    t0 = 70;
    t1 = spiral_turns * 360;
    b  = (island_r_top - island_round - spiral_w) / t1;
    n  = 240;
    outer = [for (i = [0 : n])      let(t = t0 + (t1 - t0) * i / n, r = b * t + spiral_w / 2) [r * cos(t), r * sin(t)]];
    inner = [for (i = [n : -1 : 0]) let(t = t0 + (t1 - t0) * i / n, r = b * t - spiral_w / 2) [r * cos(t), r * sin(t)]];
    polygon(concat(outer, inner));
    circle(r = 1.6, $fn = 24);                 // center dot
}

module island() {
    rr = island_round;
    rotate_extrude() polygon(concat(
        [[0, 0], [island_r_base, 0], [island_r_base, floor_t]],
        [for (s = [0 : 10]) let(ang = s * 90 / 10)
            [island_r_top - rr + rr * cos(ang), island_top - rr + rr * sin(ang)]],
        [[0, island_top]]
    ));
    translate([0, 0, island_top - 0.01])
        linear_extrude(spiral_h + 0.01) spiral2d();
}

// ---------- twist-lock socket ----------
// Round bore for the peg; per lug, a straight entry slot up from the bottom,
// then a channel that turns `twist` degrees. The channel floor ramps up into a
// small bump just before the end, so the lug clicks into a snug pocket.
module sector(r, a0, a1)
    polygon(concat([[0, 0]], [for (i = [0 : 8]) let(t = a0 + (a1 - a0) * i / 8) r * [cos(t), sin(t)]]));

slot_half = lug_deg / 2 + 2;   // half width of the entry slot, degrees

// channel floor height at `t` degrees past the entry slot
function chan_floor(t) =
    let(r0 = slot_half,                   // ramp starts once the lug leaves the slot
        rp = twist - lug_deg / 2,         // bump peak, just behind the locked lug
        lo = lug_z - fit / 2)
    t <= r0 ? lo :
    t <= rp ? lo + (lug_z + lock_click - lo) * (t - r0) / (rp - r0) :
    lug_z - 0.05;                         // pocket the lug drops into

module socket() {
    bore = peg_d + fit;
    rch  = lug_r + fit / 2;
    ztop = lug_z + lug_h + fit / 2;
    step = 1.5;
    // bore with a 45-degree roof so it prints without support
    translate([0, 0, -0.01]) cylinder(d = bore, h = peg_len + 0.5);
    translate([0, 0, peg_len + 0.49]) cylinder(d1 = bore, d2 = 4, h = (bore - 4) / 2);
    for (i = [0 : lugs - 1]) rotate(lug_phase + i * 360 / lugs) {
        translate([0, 0, -0.01]) linear_extrude(ztop + 0.01) sector(rch, -slot_half, slot_half);
        n = ceil((twist + lug_deg / 2 + 2 + slot_half) / step);
        for (k = [0 : n - 1]) {
            t0 = -slot_half + k * step;
            zb = chan_floor(t0 + step / 2);
            translate([0, 0, zb]) linear_extrude(ztop - zb) sector(rch, t0, t0 + step + 0.01);
        }
    }
}

module dish() {
    difference() {
        union() {
            dish_body();
            island();
        }
        grooves();
        socket();
    }
}

// ---------- stem: runs up the z axis, stake tip at z = 0, peg on top ----------
module oct(d) rotate(22.5) circle(r = d / 2 / cos(22.5), $fn = 8);

module peg() {
    cylinder(d = peg_d, h = peg_len - 1);
    translate([0, 0, peg_len - 1.01]) cylinder(d1 = peg_d, d2 = peg_d - 2, h = 1.01);   // lead-in
    for (i = [0 : lugs - 1]) rotate(lug_phase + i * 360 / lugs)
        translate([0, 0, lug_z]) intersection() {
            cylinder(r = lug_r, h = lug_h);
            translate([0, -lug_w / 2, 0]) cube([lug_r + 1, lug_w, lug_h]);
        }
}

module stem() {
    hull() {                                   // centered point
        linear_extrude(0.01) oct(tip_d);
        translate([0, 0, stake_len]) linear_extrude(0.01) oct(stem_d);
    }
    translate([0, 0, stake_len - 0.01]) linear_extrude(stem_len + 0.01) oct(stem_d);
    translate([0, 0, stem_total - 0.01]) peg();
}

// stem laid on a flat side, running along y, centered at the origin
// (needs supports under the point and the peg)
module stem_lying() {
    translate([0, 0, stem_d / 2])
        rotate([0, 0, 90]) rotate([0, 90, 0])
            translate([0, 0, -(stem_total + peg_len) / 2]) stem();
}

// ---------- print layout ----------
// The stem lies along the flatter side of the flower (the side with a notch
// between two petals); the pair is centered on the origin.
dish_min_x = min([for (i = [0 : 359]) R_at(i) * cos(i)]);
dish_max_x = R_at(0);
stem_x     = dish_min_x - layout_gap - stem_d / 2;
layout_dx  = -((stem_x - stem_d / 2) + dish_max_x) / 2;

// ---------- output ----------
color(print_color) {
    if (part == "print") {
        translate([layout_dx, 0, 0]) {
            dish();
            translate([stem_x, 0, 0]) stem_lying();
        }
    } else if (part == "dish") {
        dish();
    } else if (part == "stem") {
        stem_lying();
    } else {
        dish();
        translate([0, 0, -stem_total]) rotate(twist) stem();   // shown locked
    }
}
