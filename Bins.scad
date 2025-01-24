/*************************************/
/* Bin Creating Modules
/*************************************/
//NOMINAL_BIN_WIDTH = 2;
NOMINAL_BIN_WIDTH = 1;
NOMINAL_BIN_HEIGHT = 1;
//BIN_DEPTH = 80;
BIN_DEPTH = 20;

LENGTH = BIN_DEPTH; // two trays per layer
HEIGHT = NOMINAL_BIN_HEIGHT*SLOT_SPACING - TOLERANCE; // 2 trays high in drawer
WIDTH = NOMINAL_BIN_WIDTH*SLOT_SPACING - SLOT_WIDTH - TOLERANCE;

module base_bin(size) {
    difference() {
        //beveled_block([size.x, size.y, size.z+BEVEL], bevel=BEVEL);
        translate([0,0,size.z/2]) bin_block([size.x, size.y, size.z], bevels=[[BEVEL, BEVEL], [0, BEVEL], [BEVEL,0]]);
        children();
        //translate([0,0,size.z/2+THICKNESS]) bin_block([size.x-2*THICKNESS,size.y-2*THICKNESS,size.z-THICKNESS], bevels=[[BEVEL, BEVEL], [0, BEVEL], [BEVEL,0]]);
    }
    //translate([size.x/2,0,size.z-SLIDE_WIDTH-THICKNESS]) slide(size.y);
    //mirror([1,0,0]) translate([size.x/2,0,size.z-SLIDE_WIDTH-THICKNESS]) slide(size.y);
    //translate([0,size.y/2,0]) handle(size);
}


module base_tray(size) {
    base_bin(size) {
        #translate([0,0,THICKNESS]) beveled_block([size.x-2*THICKNESS, size.y-2*THICKNESS, size.z-THICKNESS], bevel=BEVEL);
    }
}

module bin_block(size, bevels=THICKNESS/4) {
    _bevels = (bevels.x == undef) ? [[bevels,bevels],[bevels,bevels],[bevels,bevels]] : bevels;
    offsets = [_bevels.x[0] - _bevels.x[1], _bevels.y[0] - _bevels.y[1], _bevels.z[0] - _bevels.z[1]] * 0.5;
    echo(_bevels=_bevels, offsets=offsets);
    hull() {
        translate([offsets.x, offsets.y, 0]) cube([size.x-sum(_bevels.x), size.y-sum(_bevels.y), size.z], center=true);
        translate([offsets.x, 0, offsets.z]) cube([size.x-sum(_bevels.x), size.y, size.z-sum(_bevels.z)], center=true);
        translate([0, offsets.y, offsets.z]) cube([size.x, size.y-sum(_bevels.y), size.z-sum(_bevels.z)], center=true);
    }
}

module compartment_cutter(size) {
    translate([0,0,THICKNESS+size.y]) beveled_block([size.x, size.y, 2*size.y], bevel=BEVEL, center=true);
    translate([0,0,-SLOP]) mesh_cutter([size.x, size.y-THICKNESS, 2*size.y], hole_size=3, solid_size=THICKNESS);
}

module basic_tray(size) {
    bin_size = [ size.x-2*THICKNESS, size.y - 2*THICKNESS, size.z - THICKNESS ];
    base_bin(size) {
        translate([0,0,0]) compartment_cutter(bin_size);
    }
}

module divided_tray(size) {
    bin_length = (size.x-3*THICKNESS)/2;
    bin_offset = (bin_length + THICKNESS) / 2;
    base_bin(size) {
        translate([bin_offset,0,0]) compartment_cutter([bin_length, size.y-2*THICKNESS]);
        translate([-bin_offset,0,0]) compartment_cutter([bin_length, size.y-2*THICKNESS]);
    }
}

module divided_tray2(size) {
    bin_size = [ size.x-2*THICKNESS, (size.y - 3*THICKNESS) / 2 ];
    bin_offset = [ 0, (bin_size.y + THICKNESS) / 2 ];
    base_bin(size) {
        translate([bin_offset.x, bin_offset.y]) compartment_cutter(bin_size);
        translate([bin_offset.x, -bin_offset.y, 0]) compartment_cutter(bin_size);
    }
}

module quad_tray(size) {
    bin_size = [ for (v = size) v-3*THICKNESS ] / 2;
    bin_offset = [ for (v = bin_size) (v + THICKNESS) / 2 ];
    base_bin(size) {
        translate([bin_offset.x, bin_offset.y, 0]) compartment_cutter(bin_size);
        translate([-bin_offset.x, bin_offset.y, 0]) compartment_cutter(bin_size);
        translate([bin_offset.x, -bin_offset.y, 0]) compartment_cutter(bin_size);
        translate([-bin_offset.x, -bin_offset.y, 0]) compartment_cutter(bin_size);
    }
}

module bin(spaces=1, depth=25, height=25) {
    size = [depth, spaces*SLOT_SPACING-SLOT_WIDTH, height];
    basic_tray(size);

    // create pins for adding supports
    pin_height = SUPPORT_BASE_SOCKET_HEIGHT-TOLERANCE;
    support_size = [size.y+SUPPORT_THICKNESS*5, SUPPORT_THICKNESS-TOLERANCE, pin_height];
    translate([0,-depth/2+SUPPORT_THICKNESS-TOLERANCE,height-pin_height/2]) {
        beveled_block(support_size, center=true);
    }
}

