// 1. Private
// 2. Sergeant
// 3. Captain
// 4. Lieutenant
// 5. Major
// 6. Brigadier
// 7. General

const std = @import("std");

const Private = struct { sergeant: *Sergeant };
const Sergeant = struct { sergeant: *Captain };
const Captain = struct { sergeant: *Lieutenant };
const Lieutenant = struct { sergeant: *Major };
const Major = struct { sergeant: *Brigadier };
const Brigadier = struct { id: u8 };

pub fn main() void {}
