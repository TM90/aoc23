const std = @import("std");
const XtoYmap = std.AutoHashMap(u64, u64);

const Almanac = struct {
    seeds: std.ArrayList(u64),
    seed_to_soil: XtoYmap,
    soil_to_fertilizer: XtoYmap,
    fertilizer_to_water: XtoYmap,
    water_to_ligth: XtoYmap,
    light_to_temperature: XtoYmap,
    temperature_to_humidity: XtoYmap,
    humidity_to_location: XtoYmap,

    fn parseSeeds(seeds_section: []const u8) std.ArrayList(u8) {
        _ = seeds_section;
    }

    fn parseDestinationSourceMap(seed_to_soil_section: []const u8) std.AutoHashMap(u64, u64) {
        _ = seed_to_soil_section;
    }

    pub fn parse(file_content: []const u8, allocator: std.mem.Allocator) Almanac {
        _ = file_content;
        _ = allocator;
    }
};

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    const path = "input.dat";
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var file_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = file_allocator.deinit();
    var file_content = file.reader().readAllAlloc(file_allocator.allocator(), 8_000_000) catch unreachable;
    defer file_allocator.allocator().free(file_content);
    var iterator = std.mem.splitSequence(u8, file_content, "\n\n");

    while (iterator.next()) |element| {
        try stdout.print("Element:\n{s}\n", .{element});
    }
    // try stdout.print("{s}\n", .{file_content});
    try stdout.print("Result 5a: \n", .{});
    try stdout.print("Result 5b: \n", .{});

    try bw.flush(); // don't forget to flush!
}
