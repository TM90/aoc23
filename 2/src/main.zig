const std = @import("std");

const Rgb = struct {
    r: u64,
    g: u64,
    b: u64,

    fn parse(line: []const u8) Rgb {
        var iter = std.mem.splitAny(u8, line, ",");
        var r: u64 = 0;
        var g: u64 = 0;
        var b: u64 = 0;
        while (iter.next()) |element| {
            var value_color_pair = std.mem.splitAny(u8, std.mem.trimLeft(u8, element, " "), " ");
            const value = std.mem.trim(u8, value_color_pair.next().?, " \r\n\t");
            const color = std.mem.trim(u8, value_color_pair.next().?, " \r\n\t");

            std.log.warn("Value: {s}\nColor: {s}", .{ value, color });
            if (std.mem.eql(u8, color, "red")) {
                r = std.fmt.parseInt(u64, value, 10) catch 0;
            } else if (std.mem.eql(u8, color, "green")) {
                g = std.fmt.parseInt(u64, value, 10) catch 0;
            } else if (std.mem.eql(u8, color, "blue")) {
                b = std.fmt.parseInt(u64, value, 10) catch 0;
            }
        }
        return Rgb{ .r = r, .g = g, .b = b };
    }
};

fn valid_game_id(line: []const u8, bag: Rgb) ?u64 {
    var iter = std.mem.splitAny(u8, line, ":");
    const game = iter.next() orelse unreachable;
    var id_iter = std.mem.splitAny(u8, game, " ");
    _ = id_iter.next();
    const game_id = std.fmt.parseInt(u64, id_iter.next().?, 10) catch 0;
    std.log.warn("id: {d}", .{game_id});
    const record = iter.next() orelse unreachable;
    var draws = std.mem.splitAny(u8, record, ";");
    while (draws.next()) |draw| {
        std.log.warn("{s}", .{draw});
        const rgb = Rgb.parse(draw);
        std.log.warn("{} {} {}", .{ rgb.r, rgb.g, rgb.b });
        if (rgb.r > bag.r or rgb.g > bag.g or rgb.b > bag.b) {
            return null;
        }
    }
    return game_id;
}

fn power_minimum_required(line: []const u8) u64 {
    var iter = std.mem.splitAny(u8, line, ":");
    const game = iter.next() orelse unreachable;
    var id_iter = std.mem.splitAny(u8, game, " ");
    _ = id_iter.next();
    const game_id = std.fmt.parseInt(u64, id_iter.next().?, 10) catch 0;
    std.log.warn("id: {d}", .{game_id});
    const record = iter.next() orelse unreachable;
    var minimal_bag = Rgb{ .r = 0, .g = 0, .b = 0 };
    var draws = std.mem.splitAny(u8, record, ";");
    while (draws.next()) |draw| {
        std.log.warn("{s}", .{draw});
        const rgb = Rgb.parse(draw);
        std.log.warn("{} {} {}", .{ rgb.r, rgb.g, rgb.b });
        if (rgb.r > minimal_bag.r) {
            minimal_bag.r = rgb.r;
        }
        if (rgb.g > minimal_bag.g) {
            minimal_bag.g = rgb.g;
        }
        if (rgb.b > minimal_bag.b) {
            minimal_bag.b = rgb.b;
        }
        std.log.warn("{} {} {}", .{ minimal_bag.r, minimal_bag.g, minimal_bag.b });
    }
    std.log.warn("OUT: {} {} {}", .{ minimal_bag.r, minimal_bag.g, minimal_bag.b });
    return minimal_bag.r * minimal_bag.g * minimal_bag.b;
}

pub fn main() !void {
    const bag = Rgb{ .r = 12, .g = 13, .b = 14 };
    const path = "input.dat";
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var eof = false;
    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    var sum_a: u64 = 0;
    var sum_b: u64 = 0;
    while (!eof) {
        file.reader().streamUntilDelimiter(fbs.writer(), '\n', fbs.buffer.len) catch |err| switch (err) {
            error.EndOfStream => eof = true,
            else => |e| return e,
        };
        const line = fbs.getWritten();
        sum_a += valid_game_id(line, bag) orelse 0;
        sum_b += power_minimum_required(line);
        fbs.reset();
    }
    const writer = std.io.getStdOut().writer();
    try writer.print("Result 2a: {d}\n", .{sum_a});
    try writer.print("Result 2b: {d}\n", .{sum_b});
}

test "2b test" {
    try std.testing.expect(power_minimum_required("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green") == 48);
    try std.testing.expect(power_minimum_required("Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue") == 12);
    try std.testing.expect(power_minimum_required("Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red") == 1560);
    try std.testing.expect(power_minimum_required("Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red") == 630);
    try std.testing.expect(power_minimum_required("Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green") == 36);
}
