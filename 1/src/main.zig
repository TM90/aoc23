const std = @import("std");

const value_matches: [9][]const u8 = [9][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn retrieveStringNumberStartsWith(sub_line: []const u8) ?u8 {
    for (value_matches, 1..) |match, index| {
        if (std.mem.startsWith(u8, sub_line, match)) {
            return @intCast(index);
        }
    }
    return null;
}

fn retrieveStringNumberEndsWith(sub_line: []const u8) ?u8 {
    for (value_matches, 1..) |match, index| {
        if (std.mem.endsWith(u8, sub_line, match)) {
            return @intCast(index);
        }
    }
    return null;
}

fn getFirstDigit(line: []const u8) u8 {
    var i: u64 = 0;
    while (i < line.len) : (i += 1) {
        switch (line[i]) {
            '0'...'9' => return line[i] - '0',
            else => {
                if (retrieveStringNumberStartsWith(line[i..])) |value| {
                    return value;
                }
                continue;
            },
        }
    }
    return 0;
}

fn getLastDigit(line: []const u8) u8 {
    var i: u64 = line.len - 1;
    while (i >= 0) : (i -= 1) {
        switch (line[i]) {
            '0'...'9' => return line[i] - '0',
            else => {
                if (retrieveStringNumberEndsWith(line[0 .. i + 1])) |value| {
                    return value;
                }
                continue;
            },
        }
    }
    return 0;
}

fn getCorrectionValue(line: []const u8) u8 {
    const first_val = getFirstDigit(line);
    const last_val = getLastDigit(line);
    return 10 * first_val + last_val;
}

pub fn main() !void {
    const path = "input.dat";
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var eof = false;
    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    var sum: u64 = 0;
    while (!eof) {
        file.reader().streamUntilDelimiter(fbs.writer(), '\n', fbs.buffer.len) catch |err| switch (err) {
            error.EndOfStream => eof = true,
            else => |e| return e,
        };

        sum += getCorrectionValue(fbs.getWritten());
        fbs.reset();
    }
    const writer = std.io.getStdOut().writer();
    try writer.print("{d}", .{sum});
}

test "1a" {
    try std.testing.expect(getCorrectionValue("1abc2") == 12);
    try std.testing.expect(getCorrectionValue("pqr3stu8vwx") == 38);
    try std.testing.expect(getCorrectionValue("a1b2c3d4e5f") == 15);
    try std.testing.expect(getCorrectionValue("treb7uchet") == 77);
}

test "1b" {
    try std.testing.expect(getCorrectionValue("two1nine") == 29);
    try std.testing.expect(getCorrectionValue("eightwothree") == 83);
    try std.testing.expect(getCorrectionValue("abcone2threexyz") == 13);
    try std.testing.expect(getCorrectionValue("xtwone3four") == 24);
    try std.testing.expect(getCorrectionValue("4nineeightseven2") == 42);
    try std.testing.expect(getCorrectionValue("zoneight234") == 14);
    try std.testing.expect(getCorrectionValue("7pqrstsixteen") == 76);
}
