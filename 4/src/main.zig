const std = @import("std");

const Card = struct {
    winning_numbers: std.ArrayList(u64),
    numbers_you_have: std.ArrayList(u64),

    fn parse_numbers(allocator: std.mem.Allocator, line: []const u8) std.ArrayList(u64) {
        var numbers = std.ArrayList(u64).init(allocator);
        var numbers_raw = std.mem.splitScalar(u8, line, ' ');
        while (numbers_raw.next()) |number_raw| {
            const number = std.mem.trim(u8, number_raw, " \n\r");
            if (std.mem.eql(u8, number, "")) {
                continue;
            }
            numbers.append(std.fmt.parseInt(u64, number, 10) catch unreachable) catch unreachable;
        }
        return numbers;
    }

    pub fn parse(winning_allocator: std.mem.Allocator, you_have_allocator: std.mem.Allocator, line: []const u8) Card {
        var split = std.mem.splitScalar(u8, line, ':');
        _ = split.next() orelse "";
        var number_block = split.next() orelse "";
        var split_numbers = std.mem.splitScalar(u8, number_block, '|');
        const winning_number_line = split_numbers.next() orelse "";
        const current_number_line = split_numbers.next() orelse "";
        const winning_numbers = parse_numbers(winning_allocator, winning_number_line);
        const numbers_you_have = parse_numbers(you_have_allocator, current_number_line);
        return Card{
            .winning_numbers = winning_numbers,
            .numbers_you_have = numbers_you_have,
        };
    }
};

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    const path = "input_simple.dat";
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var eof = false;
    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);

    while (!eof) {
        var winning_number_allocator = std.heap.GeneralPurposeAllocator(.{}){};
        var current_numbers_allocator = std.heap.GeneralPurposeAllocator(.{}){};
        file.reader().streamUntilDelimiter(fbs.writer(), '\n', fbs.buffer.len) catch |err| switch (err) {
            error.EndOfStream => eof = true,
            else => |e| return e,
        };
        const line = fbs.getWritten();
        const card = Card.parse(winning_number_allocator.allocator(), current_numbers_allocator.allocator(), line);
        _ = card;

        fbs.reset();
    }
    try stdout.print("Result 1a:\n", .{});
    try stdout.print("Result 1b:\n", .{});
    try bw.flush();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
