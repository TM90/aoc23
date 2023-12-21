const std = @import("std");
const Stack = std.MultiArrayList(Card);
const Card = struct {
    id: u64,
    winning_numbers: std.ArrayList(u64),
    numbers_you_have: std.ArrayList(u64),
    matches: u64,
    children_start: u64,
    children_end: u64,
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

    pub fn parse(winning_allocator: std.mem.Allocator, you_have_allocator: std.mem.Allocator, line: []const u8, id: u64) Card {
        var split = std.mem.splitScalar(u8, line, ':');
        _ = split.next() orelse "";
        var number_block = split.next() orelse "";
        var split_numbers = std.mem.splitScalar(u8, number_block, '|');
        const winning_number_line = split_numbers.next() orelse "";
        const current_number_line = split_numbers.next() orelse "";
        const winning_numbers = parse_numbers(winning_allocator, winning_number_line);
        const numbers_you_have = parse_numbers(you_have_allocator, current_number_line);
        return Card{
            .id = id,
            .winning_numbers = winning_numbers,
            .numbers_you_have = numbers_you_have,
            .matches = matches(numbers_you_have, winning_numbers),
            .children_start = id + 1,
            .children_end = id + matches(numbers_you_have, winning_numbers) + 1,
        };
    }

    pub fn children_end(self: Card) u64 {
        return self.id + self.matches() + 1;
    }

    pub fn children_start(self: Card) u64 {
        return self.id + 1;
    }

    pub fn matches(numbers_you_have: std.ArrayList(u64), winning_numbers: std.ArrayList(u64)) u64 {
        var sum: u64 = 0;
        for (numbers_you_have.items) |number| {
            for (winning_numbers.items) |winner| {
                if (number == winner) {
                    sum += 1;
                }
            }
        }
        return sum;
    }

    pub fn points(self: Card) u64 {
        const n = self.matches;
        var sum: u64 = 0;
        for (0..n) |value| {
            if (value >= 1) {
                sum += std.math.powi(u64, 2, value - 1) catch unreachable;
            } else {
                sum += 1;
            }
        }
        return sum;
    }
    pub fn deinit(self: Card) void {
        self.numbers_you_have.deinit();
        self.winning_numbers.deinit();
    }
};

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    const path = "input.dat";
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var eof = false;
    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    var sum_1a: u64 = 0;
    var sum_1b: u64 = 0;
    var winning_number_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var current_numbers_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var stack_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var stack = Stack{};
    var id: u64 = 1;
    //defer _ = winning_number_allocator.deinit();
    //defer _ = current_numbers_allocator.deinit();
    while (!eof) {
        file.reader().streamUntilDelimiter(fbs.writer(), '\n', fbs.buffer.len) catch |err| switch (err) {
            error.EndOfStream => eof = true,
            else => |e| return e,
        };
        //std.log.info("{d}", .{(file.getPos() catch unreachable)});
        //file.seekTo(0) catch unreachable;
        const line = fbs.getWritten();
        const card = Card.parse(winning_number_allocator.allocator(), current_numbers_allocator.allocator(), line, id);
        fbs.reset();
        sum_1a += card.points();
        id += 1;
        stack.append(stack_allocator.allocator(), card) catch unreachable;
    }

    var valid_scratchcards_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var valid_scratchcard_ids = std.ArrayList(u64).init(valid_scratchcards_allocator.allocator());
    for (stack.items(.id)) |card_id| {
        valid_scratchcard_ids.insert(0, card_id) catch unreachable;
    }
    while (valid_scratchcard_ids.popOrNull()) |element| {
        sum_1b += 1;
        const card = stack.get(element - 1);
        for (card.children_start..card.children_end) |new_element| {
            //valid_scratchcard_ids.appendSlice(items: []const T)
            valid_scratchcard_ids.append(new_element) catch unreachable;
        }
        if (sum_1b % 10000 == 0) {
            std.log.info("Length scratchpad ids: {d}\n", .{valid_scratchcard_ids.items.len});
        }
    }

    try stdout.print("Result 1a: {d}\n", .{sum_1a});
    try stdout.print("Result 1b: {d}\n", .{sum_1b});
    try bw.flush();
}
