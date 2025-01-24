// WallControl Fixture Generator

/*
    Note on coordinates. Unless otherwiser noted, all models are designed with the pegboard
    face as the zy plane, and the x axis aligned to the bottom left edge of the slot and
    pointing away from the wall. These are then rotated for optimal printing.
    TODO: Verify
 */

ITEM = "shelf"; // [shelf, holder, bin, hook]
SPACES = 1;  // [1:8]
DEPTH = 25; // [200];

module __Customizer_Limit__ () {}

// Basic Dimensions
INCH = 25.4;
SLOT_WIDTH = 2.5;
SLOT_HEIGHT = 25.4;
SLOT_SPACING = 1*INCH;
SLOT_VERTICAL_SPACING = 2*INCH;
SHELF_THICKNESS = 1.6;

MOUNT_CONNECTOR_HEIGHT = 20;

TOLERANCE = 0.2;
THICKNESS = 1.6;
BEVEL = 2.4;
SLOP = 0.001;

//SUPPORT_HEIGHT = SLOT_VERTICAL_SPACING - TOLERANCE;
SUPPORT_HEIGHT = SLOT_VERTICAL_SPACING*0.6 - TOLERANCE;
SUPPORT_THICKNESS = SLOT_WIDTH - TOLERANCE;

SUPPORT_BASE_SOCKET_HEIGHT = 5;
SOCKET_TOP_OFFSET = 3; // offset of top of pin from top of mount connector.
MAX_SOCKET_OFFSET = 14;
SUPPORT_BOTTOM_OFFSET = SUPPORT_HEIGHT-SLOT_HEIGHT;

SUPPORT_BLOCK_SIZE = [SUPPORT_THICKNESS*1.5, SUPPORT_HEIGHT, SUPPORT_THICKNESS*3];
PIN_SIZE = [SUPPORT_THICKNESS, SUPPORT_BASE_SOCKET_HEIGHT, SUPPORT_THICKNESS*4];

// Distribute items with given size over a specific span, returning the number of items
function distribution_count(size, gap, span) =
    floor((span + gap) / (size + gap));

// Distribute items with given size over a specific span, returning the offset of the first item
function distribution_offset(size, gap, span) =
    (span - (distribution_count(size, gap, span) * (size + gap) - gap)) / 2;

function sum(v) = [for (p=v) 1]*v;

/*
    Create a beveled block; parameters are the same as cube(), with the addition of a bevel.
    TODO: Allow bevels on different axes to be different by passing array
 */
module beveled_block(size, bevel=THICKNESS/4, center=false) {
    base_size = size - [2*bevel,2*bevel,2*bevel];
    offset = (center==true) ? [0,0,0] : size/2;
    echo(offset=offset);
    translate(offset) hull() {
        cube([size.x, base_size.y, base_size.z], center=true);
        cube([base_size.x, size.y, base_size.z], center=true);
        cube([base_size.x, base_size.y, size.z], center=true);
     }
}
/*
    Wallcontrol mount
 */
module wallcontrol_mount() {
    linear_extrude(2.0) polygon([
        // Supporting hook & connection surface
            [-1.8,-4],[-1.0,-3.5],[-1.4,-2.5],[-1.0,0],[0,0],[0,20.5],
        // Bottom hook
            [-1.5,20.6],[-2.9,20.9],[-1.5,26.5],[-1.2,28.6],[-1.4,32.6],
        // Bottom curve & Back
            [-6.0,32.6],[-7.4,32.4],[-8.75,31.7],[-9.6,31.5],[-10,28],
        // top tab
            [-9.9,16],[-9.5,13],[-5.7,-0.5],[-5.1,-2],[-4.45,-3]]);
}

/*
    Basic WallControll support block with mount and pin socket.

    socket_offset - height of pin socket below the top of the mount connector. Should be
        at least a few mm to prevent the support block from breaking off the mount at the
        top. A higher position (lesss offset) is generally better, as the force on the
        mount will be directed more downward. Sometimes, a better look can be achieved
        with a larger offset setting. Defaults is a few mm below the top of the mount
        connection.
    extra_length - amount of extra length to add to the bottom of the support. This is
        typcially used with a brace, but can be used to create vertically oriented
        fixtures.
 */
module support(socket_offset=SOCKET_TOP_OFFSET, depth=0, extra_length=0) {
    // support mount//    mount_offset = 8.75;
    ////    SUPPORT_THICKNESS = SLOT_WIDTH - TOLERANCE;
    ////    slide_length = BIN_DEPTH - 2*BEVEL;
    //mirror([0,1,0]) rotate([0,90,0]) translate([-8.1099,11,0]) import("WallControlMount2.stl");
    wallcontrol_mount();
    pin_y_offset = MOUNT_CONNECTOR_HEIGHT-PIN_SIZE.y-socket_offset;

    size = SUPPORT_BLOCK_SIZE + [0,extra_length,0];
    // support base
    difference() {
        translate([0,-SUPPORT_BOTTOM_OFFSET-extra_length,0]) cube(size);
        translate([0,pin_y_offset,-TOLERANCE]) cube(PIN_SIZE);
    }
}

/*
    Create a triangular brace of the given size
 */
module brace(size) {
    t = THICKNESS;
    a = atan((size.x-2*THICKNESS) / (size.y-THICKNESS));
    echo(a=a);
    inner_triangle = [[2*THICKNESS,-THICKNESS],[2*THICKNESS,-size.y+t/sin(a)],[size.x-t/cos(a),-t]];
    difference() {
        linear_extrude(height=size.z) {
            polygon([[0,0],[0,-size.y],[2*THICKNESS,-size.y],[size.x,-THICKNESS],[size.x,0]]);
        }
        if (inner_triangle[1].y < inner_triangle[0].y) {
            translate([0,0,SUPPORT_THICKNESS]) linear_extrude(height=size.z) polygon(inner_triangle);
        }
    }
}

/*
    Create a support braced on the bottom by an angled beam

    depth - how far out the brace comes from the support
    brace_height - height of brace. Increase for stronger support
 */
module braced_support(socket_offset=SOCKET_TOP_OFFSET, depth=10, brace_height=SUPPORT_BOTTOM_OFFSET, extra_support=0) {
    support(socket_offset=socket_offset, depth=depth, extra_length=extra_support);
    brace_size = [depth+SUPPORT_BLOCK_SIZE.x, brace_height+extra_support, SUPPORT_BLOCK_SIZE.z];
    brace(brace_size);
}

/**
 Creates a square array of square prisms that fit into a cube of the
 specified size. The prisms are parallel to the Z-axis. The bounding cube is
 centered on the z axis and rises up from the x/y plane.
*/
module mesh_cutter(size, hole_size=2, solid_size) {
    d = hole_size + solid_size;
    counts = [ for (i = [0,1]) distribution_count(hole_size, solid_size, size[i]) ];
    offsets = [ for (i = [0,1]) distribution_offset(hole_size, solid_size, size[i]) - size[i]/2 ];
    echo(size=hole_size, gap=solid_size, spans=size, counts=counts, offsets=offsets);
    echo(check_x=counts.x*hole_size + (counts.x-1)*solid_size + 2*offsets.x, check_y=counts.y*hole_size + (counts.y-1)*solid_size + 2*offsets.y);
    for (i = [0:(counts.x-1)]) {
        for (j = [0:(counts.y-1)]) {
            translate([offsets.x + d*i, offsets.y + d*j]) cube([hole_size, hole_size, size.z]);
        }
    }
}

/*
  Creates a support pin in the correct positon to fit the support

  Gadgets are attached to the support using a pin that fits in the socket
  on the support. These will typically come from the outside edge of the
  spport, allowing the gadget to be larger than the space between the
  supports.
 */
module support_pin(socket_offset=SOCKET_TOP_OFFSET) {
    pin_y_offset = MOUNT_CONNECTOR_HEIGHT-PIN_SIZE.y-socket_offset;
    pin_width = SUPPORT_BLOCK_SIZE.z+BEVEL;
    translate([0,pin_y_offset,-BEVEL]) {
        beveled_block([SUPPORT_THICKNESS-TOLERANCE, SUPPORT_BASE_SOCKET_HEIGHT-TOLERANCE, pin_width]);
    }
}

module simple_pin(socket_offset=SOCKET_TOP_OFFSET) {
    pin_y_offset = MOUNT_CONNECTOR_HEIGHT-PIN_SIZE.y-socket_offset -0.25*PIN_SIZE.y;
    pin_head_size = [SUPPORT_BLOCK_SIZE.x,PIN_SIZE.y*1.5,BEVEL];
    support_pin();
    translate([0,pin_y_offset,-pin_head_size.z]) cube(pin_head_size);
}

/*
    Creates a spacer to combine two specialty supports into a single
    structure that is fairly stable horizontally.

    spaces - number of spaces between the support slots
 */
module support_spacer(spaces=1, socket_offset=SOCKET_TOP_OFFSET) {
    echo(spaces=spaces);
    pin_y_offset = MOUNT_CONNECTOR_HEIGHT-PIN_SIZE.y-socket_offset;
    shoulder = THICKNESS;
    spacer_width = spaces*SLOT_SPACING - SLOT_WIDTH;
    spacer_size = [SUPPORT_THICKNESS-TOLERANCE,SUPPORT_BASE_SOCKET_HEIGHT-TOLERANCE+2*shoulder,spacer_width];

    translate([0,0,-spacer_size.z/2]) {
        translate([0,0,spacer_size.z/2]) support_pin(socket_offset=socket_offset);
        mirror([0,0,1]) translate([0,0,spacer_size.z/2]) support_pin(socket_offset=socket_offset);
        translate([0,pin_y_offset-shoulder,-spacer_size.z/2]) {
            cube(spacer_size);
        }
    }
}

module oriented_support_spacer(spaces=1, socket_offset=SOCKET_TOP_OFFSET) {
    rotate([0,-90,0]) support_spacer(spaces=spaces, socket_offset=socket_offset);
}

module oriented_ensemble() {
    translate([0.5*INCH-SLOT_WIDTH/2,0,0]) rotate([0,90,0]) support(1);
    mirror([1,0,0]) translate([0.5*INCH-SLOT_WIDTH/2,0,0]) rotate([0,90,0]) support(1);
    translate([0,-HEIGHT,LENGTH/2+THICKNESS]) rotate([0,0,0]) basic_tray([LENGTH,WIDTH,HEIGHT]);
}

/*
    Creates a tool holder - basically, a rectangular ring that has pins for
    adding suppports.

    Requires two standard supports, one mirrored.

    spaces - number of spaces between support slots
    depth - how far the tool holder extends from the supports
 */
module tool_holder(spaces, depth) {
    holder_thickness = 2*THICKNESS;
    holder_height = SUPPORT_BASE_SOCKET_HEIGHT-TOLERANCE;
    size=[depth, spaces*SLOT_SPACING-SLOT_WIDTH-2*holder_thickness];
    bevel = THICKNESS/4;
    translate([0,holder_height/2,0]) difference() {
        beveled_block([size.x+2*holder_thickness, holder_height, size.y+2*holder_thickness], center=true);
        cube([size.x, holder_height*2, size.y], center=true);
        translate([0,holder_height-bevel,0]) beveled_block([size.x+2*bevel, holder_height, size.y+2*bevel], center=true);
        //translate([0,-holder_height+bevel,0]) beveled_block([size.x+2*bevel, holder_height, size.y+2*bevel], center=true);
    }

    support_size = [SUPPORT_THICKNESS-TOLERANCE, holder_height,size.y+SUPPORT_THICKNESS*8];
    translate([support_size.x/2-size.x/2-holder_thickness,support_size.y/2,0]) {
        beveled_block(support_size, center=true);
        translate([(holder_thickness-support_size.x)/2,support_size.y,0]) cube([holder_thickness, support_size.y*2, size.y+2*holder_thickness], center=true);
    }
}

/*
    Creates a shelf, optionally, with a lip to keep items contained.

    Requires two standard supports, one mirrored.

    spaces - number of spaces between support slots. The shelf will extensd beyond this for
                half a space, allowing for continuous shelving
    depth - how far the shelf extends from the supports
    lip_height - height of lip, or 0 for no lip

    TODO: allow exact shelf size and calculate spacing
 */
module shelf(spaces, depth, lip_height=0) {
    thickness = THICKNESS;
    height = SUPPORT_BASE_SOCKET_HEIGHT-TOLERANCE;
    shelf_thickness = thickness + lip_height;
    size=[depth, spaces*(SLOT_SPACING+1)-TOLERANCE];
    bevel = THICKNESS/4;

    // create the basic shelf slab
    translate([0,0,-(size.y+SLOT_SPACING)/2]) {
        difference() {
            beveled_block([size.x, shelf_thickness, size.y+SLOT_SPACING]);
            translate([thickness*3,0,thickness]) cube([size.x-4*thickness, lip_height, size.y+SLOT_SPACING-2*thickness]);
            gap_length = spaces*SLOT_SPACING+SLOT_WIDTH;
            translate([0,0,(size.y+SLOT_SPACING)/2-gap_length/2]) cube([thickness*2+3*TOLERANCE,shelf_thickness,gap_length]);
        }
    }
    //translate([-size.x/2+thickness*1.5,shelf_thickness/2,0]) cube([SUPPORT_THICKNESS*1.5, shelf_thickness, size.y], center=true);

    // create pins for adding supports
    support_size = [SUPPORT_THICKNESS-TOLERANCE, height, SLOT_SPACING/2+SLOT_WIDTH/2+TOLERANCE+3*thickness];
    translate([support_size.x/2,shelf_thickness-height/2,-(size.y+SLOT_SPACING)/2+support_size.z/2]) beveled_block(support_size, center=true);
    translate([support_size.x/2,shelf_thickness-height/2,+(size.y+SLOT_SPACING)/2-support_size.z/2]) beveled_block(support_size, center=true);
    //-(size.y+SLOT_SPACING-2*thickness)/2-
    echo(spaces=spaces, SLOT_SPACING=SLOT_SPACING, SLOT_WIDTH=SLOT_WIDTH, offset=-(spaces*SLOT_SPACING/2+SLOT_WIDTH/2));
    //translate([-1.5,-12,-(spaces*SLOT_SPACING/2)-SLOT_WIDTH/2]) cube([1.5,25,SLOT_WIDTH]);
    //translate([-1.5,-12,+(spaces*SLOT_SPACING/2)-SLOT_WIDTH/2]) cube([1.5,25,SLOT_WIDTH]);
}

module supports(depth= 0) {
    translate([-17,12,0]) support(socket_offset = SOCKET_OFFSET, depth = 0);
    translate([-25,12,0]) mirror([1, 0, 0]) support(socket_offset = SOCKET_OFFSET, depth = 0);
}

module hook(depth=10, lip=4, shelf_thickness=0, extra_support=0) {
    stop_width = THICKNESS;
    braced_support(socket_offset=MAX_SOCKET_OFFSET, depth=depth, extra_support=extra_support);

    // end stop
    translate([depth+SUPPORT_BLOCK_SIZE.x-THICKNESS,0,0]) cube([stop_width,lip,SUPPORT_BLOCK_SIZE.z]);
}

module legacy_mini_shelf_support() {
    stop_size = 3;
    shelf_size = [82.6,5.7,8*INCH];
    hook(depth=shelf_size.x+THICKNESS+TOLERANCE, lip=stop_size, shelf_thickness=shelf_size.y, extra_support=8);
    translate([SUPPORT_BLOCK_SIZE.x,shelf_size.y+TOLERANCE,0]) cube([stop_size,THICKNESS,SUPPORT_BLOCK_SIZE.z]);
}

module mirror_pair() {
    translate([2,0,0]) children();
    mirror([1,0,0]) translate([2,0,0]) children();
}

module spacer(spaces=1) {
    oriented_support_spacer(spaces=spaces);
}

module oriented_shelf(spaces, depth, lip_height=0) {
    translate([depth*1/2,0,0]) rotate([90,0,0]) shelf(spaces, depth, lip_height);
}

module oriented_tool_holder(spaces, depth) {
    rotate([90,0,0]) tool_holder(spaces, depth);
}

module complete_legacy_mini_shelf_support() {
    translate([-34,0,0]) rotate([0,0,-90]) legacy_mini_shelf_support();
    translate([0,-18,0]) mirror([1,0,0]) rotate([0,0,-90]) legacy_mini_shelf_support();
    //rotate([0,0,-90]) translate([0,-14.5,0]) spacer(spaces=6);
}

module round_hook(d=3, length=30) {
//    side = (d/2) * 2 / (sqrt(4 + 2*sqrt(2)));
    side = (d/2) * 2 / (sqrt(4 + 2*sqrt(2)));
    z_offset = side * (1 /2+ 1/sqrt(2));
    support(depth=0);
    translate([d/2,0,z_offset]) rotate([0,90,30]) rotate([0,0,45/2]) {
        cylinder(r=d/2, h=length, $fn=8);
        translate([0,0,length]) sphere(r=1.08*d/2, $fn=8);
    }
}


//support_pin();
//oriented_ensemble();
//braced_support(extra_support=10, depth=40);
//tool_holder(spaces=1,depth=40);
//oriented_shelf(spaces=1, depth=30, lip_height=1);
//complete_legacy_mini_shelf_support();
round_hook();
//simple_pin();
