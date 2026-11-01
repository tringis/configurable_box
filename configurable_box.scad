include <boxes.scad>

// What to generate
generate = 3; // [1:Base, 2:Lid, 3:Both]

// Internal width of box
width_inner = 60;

// Internal bength of box
length_inner = 60;

// Internal height of bottom of box
base_height_internal = 120;

// Internal height of the top/lid of the box
lid_height_internal = 72;

// Height of the lip to generate
overlap_height = 12;

// Thickness of the outer wall
wall_thickness = 2.4;

// How curved to make the corners
radius = 6; // [1:10]

// Tolerance between lid and lip
tolerance = 0.25;

// Ratio of lip to regular wall thickness
lip_thickness_ratio = 0.5;

/* [Hole pattern] */

// Where to cut circular holes (in the bottom of the base and/or the top of the lid)
holes = 0; // [0:None, 1:Base, 2:Lid, 3:Both]

// Layout of the holes
hole_layout = 1; // [0:Square grid, 1:Hexagonal grid]

// Diameter of each hole
hole_diameter = 5;

// Center-to-center distance between neighbouring holes
hole_spacing = 8;

// Minimum distance from the holes to the flat area's edge (the area inside the rounded corners)
hole_margin = 2;

// Number of segments used for each circle
hole_segments = 32; // [8:128]

/* [Hidden] */

height_inner = base_height_internal + lid_height_internal;

lip_thickness = wall_thickness * lip_thickness_ratio;

width_outer = width_inner + wall_thickness*2;
length_outer = length_inner + wall_thickness*2;
height_outer = height_inner + wall_thickness*2;

module lip(tol = 0) {
    difference() {
        // The outside shell
        roundedCube(
            [width_inner+lip_thickness+tol*2,length_inner+lip_thickness+tol*2,overlap_height*2],
            radius,
            center=true
        );
        // The inside cavity
        roundedCube(
            [width_inner-tol,length_inner-tol,overlap_height*2-wall_thickness/2],
            radius,
            center=true
        );
        // Slice off the top
        translate(v=[0,0,overlap_height+tol]) 
            cube([width_outer+1, length_outer+1,overlap_height], center=true);
        // Slice off the bottom
        translate(v=[0,0,-overlap_height-tol]) 
            cube([width_outer+1, length_outer+1,overlap_height], center=true);
    } 
}

module openBox(height) {
    other_height = height_outer-height;
    cut_height = height_outer/2-other_height/2;
     
    difference() {
        // The outside shell
        roundedCube([width_outer,length_outer,height_outer],radius,center=true);
        // The inside cavity
        roundedCube([width_inner,length_inner,height_inner],radius,center=true);
        // Cut the top off
        translate(v=[0,0,cut_height]) cube([width_outer+1,length_outer+1,other_height],center=true);
        }
}

// Centers of the holes, laid out symmetrically inside an area of the
// given size. In the hexagonal layout every other row has one hole
// less, which shifts it half a spacing relative to its neighbours.
function holeCenters(area_w, area_l) =
    let(
        row_pitch = hole_layout == 1 ? hole_spacing * sqrt(3) / 2 : hole_spacing,
        cols = floor((area_w - hole_diameter) / hole_spacing) + 1,
        rows = floor((area_l - hole_diameter) / row_pitch) + 1
    )
    (area_w < hole_diameter || area_l < hole_diameter) ? [] : [
        for (r = [0 : rows - 1])
            let(n = (hole_layout == 1 && r % 2 == 1) ? cols - 1 : cols)
            for (c = [0 : 1 : n - 1])
                [(c - (n - 1) / 2) * hole_spacing, (r - (rows - 1) / 2) * row_pitch]
    ];

// Cylinders that cut the hole pattern through the floor at z=0. The
// holes are kept within the flat part of the floor, i.e. away from the
// rounded edges of the inner cavity.
module holePattern() {
    assert(hole_spacing > hole_diameter, "hole_spacing must be larger than hole_diameter");
    area_w = width_inner - 2*radius - 2*hole_margin;
    area_l = length_inner - 2*radius - 2*hole_margin;
    for (p = holeCenters(area_w, area_l))
        translate([p[0], p[1], -1])
            cylinder(d=hole_diameter, h=wall_thickness+2, $fn=hole_segments);
}

module base() {
    base_height_outer = base_height_internal + wall_thickness;

    difference() {
        union() {
            translate(v=[0,0,height_outer/2])
                openBox(base_height_outer);
            // The -0.01 is designed to ensure the lip intersects with the
            // box so they generate a complete 2-manifold object.
            translate(v=[0,0,base_height_outer + overlap_height/2 - .01]) lip();
        }
        if (holes == 1 || holes == 3) holePattern();
    }
}

module lid() {
    lid_height_outer = lid_height_internal + wall_thickness;

    difference() {
        translate(v=[0,0,height_outer/2])
            openBox(lid_height_outer);
        translate(v=[0,0,lid_height_outer - overlap_height/2]) lip(tolerance);
        if (holes >= 2) holePattern();
    }
}


offset = (generate == 3) ? (width_outer/2)+5 : 0;

if ((generate % 2) == 1) {
    translate(v=[offset,0,0]) base();
}

if (generate >= 2) {
    translate(v=[-offset,0,0]) lid();
}
