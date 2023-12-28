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

    fn parseSeeds(seeds_section: []const u8, allocator: std.mem.Allocator) std.ArrayList(u64) {
        var seeds = std.ArrayList(u64).init(allocator);
        var seeds_record = std.mem.splitScalar(u8, seeds_section, ':');
        _ = seeds_record.next() orelse unreachable;
        var seeds_raw = seeds_record.next() orelse unreachable;
        seeds_raw = std.mem.trim(u8, seeds_raw, " \r\n");
        var seeds_iterator = std.mem.splitScalar(u8, seeds_raw, ' ');
        while (seeds_iterator.next()) |element| {
            const value = std.mem.trim(u8, element, " \r\n");
            seeds.append(std.fmt.parseInt(u64, value, 10) catch unreachable) catch unreachable;
        }
        return seeds;
    }

    fn parseDestinationSourceMap(seed_to_soil_section: []const u8, allocator: std.mem.Allocator) XtoYmap {
        _ = seed_to_soil_section;
        var map = XtoYmap.init(allocator);
        return map;
    }

    pub fn parse(file_content: []const u8, allocator: std.mem.Allocator) Almanac {
        var iterator = std.mem.splitSequence(u8, file_content, "\n\n");
        return Almanac{
            .seeds = parseSeeds(iterator.next() orelse unreachable, allocator),
            .seed_to_soil = parseDestinationSourceMap(iterator.next() orelse unreachable, allocator),
            .soil_to_fertilizer = parseDestinationSourceMap(iterator.next() orelse unreachable, allocator),
            .fertilizer_to_water = parseDestinationSourceMap(iterator.next() orelse unreachable, allocator),
            .water_to_ligth = parseDestinationSourceMap(iterator.next() orelse unreachable, allocator),
            .light_to_temperature = parseDestinationSourceMap(iterator.next() orelse unreachable, allocator),
            .temperature_to_humidity = parseDestinationSourceMap(iterator.next() orelse unreachable, allocator),
            .humidity_to_location = parseDestinationSourceMap(iterator.next() orelse unreachable, allocator),
        };
    }
    pub fn deinit(self: *Almanac) void {
        self.seeds.deinit();
        self.seed_to_soil.deinit();
        self.soil_to_fertilizer.deinit();
        self.fertilizer_to_water.deinit();
        self.water_to_ligth.deinit();
        self.light_to_temperature.deinit();
        self.temperature_to_humidity.deinit();
        self.humidity_to_location.deinit();
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
    var almanac_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = almanac_allocator.deinit();
    var almanac = Almanac.parse(file_content, almanac_allocator.allocator());
    defer almanac.deinit();
    for (almanac.seeds.items) |element| {
        try stdout.print("{d}\n", .{element});
    }
    // try stdout.print("{s}\n", .{file_content});
    try stdout.print("Result 5a: \n", .{});
    try stdout.print("Result 5b: \n", .{});

    try bw.flush(); // don't forget to flush!
}
