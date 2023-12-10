const std = @import("std");

const SchematicNumber = struct {
    number: u64,
    start: u64,
    end: u64,
};

const SchematicSymbol = struct {
    symbol: u8,
    location: u64,
};

const SchematicNumberList = std.MultiArrayList(SchematicNumber);
const SchematicSymbolList = std.MultiArrayList(SchematicSymbol);

fn ValidPart(start: u64, end: u64, symbols: SchematicSymbolList) bool {
    var start_compare: u64 = 0;
    for (symbols.items(.location)) |location| {
        if (start == 0) {
            start_compare = 0;
        } else {
            start_compare = start - 1;
        }
        if (location <= end + 1 and location >= start_compare) {
            return true;
        }
    }
    return false;
}

fn RetrieveSummedPartValues(previous_symbols: SchematicSymbolList, current_line: SchematicLine, next_symbols: SchematicSymbolList) u64 {
    var sum: u64 = 0;
    for (current_line.numbers.items(.number), current_line.numbers.items(.start), current_line.numbers.items(.end)) |number, start, end| {
        if (ValidPart(start, end, current_line.symbols) or
            ValidPart(start, end, previous_symbols) or
            ValidPart(start, end, next_symbols))
        {
            sum += number;
        }
    }
    return sum;
}

const SchematicLine = struct {
    numbers: SchematicNumberList,
    symbols: SchematicSymbolList,

    pub fn from_raw_line(line: []const u8, number_allocator: std.mem.Allocator, symbol_allocator: std.mem.Allocator) !SchematicLine {
        var numbers = SchematicNumberList{};
        var symbols = SchematicSymbolList{};
        var parse_number = false;
        var number: u64 = 0;
        var start: u64 = 0;
        for (line, 0..) |character, index| {
            switch (character) {
                '0'...'9' => {
                    if (parse_number == false) {
                        start = index;
                    }
                    number = number * 10 + (character - '0');
                    parse_number = true;
                },
                '.' => {
                    if (parse_number) {
                        try numbers.append(number_allocator, SchematicNumber{ .number = number, .start = start, .end = index - 1 });
                        parse_number = false;
                        number = 0;
                    }
                },
                '\n', '\r' => {
                    if (parse_number) {
                        try numbers.append(number_allocator, SchematicNumber{ .number = number, .start = start, .end = index - 1 });
                        parse_number = false;
                        number = 0;
                    }
                },
                else => {
                    if (parse_number) {
                        try numbers.append(number_allocator, SchematicNumber{ .number = number, .start = start, .end = index - 1 });
                        parse_number = false;
                        number = 0;
                    }
                    try symbols.append(symbol_allocator, SchematicSymbol{ .symbol = character, .location = index });
                },
            }
        }
        std.log.warn("line: {s}", .{line});
        return SchematicLine{
            .numbers = numbers,
            .symbols = symbols,
        };
    }
    pub fn deinit(self: SchematicLine, number_allocator: std.mem.Allocator, symbol_allocator: std.mem.Allocator) void {
        self.numbers.deinit(number_allocator);
        self.symbols.deinit(symbol_allocator);
    }
    pub fn emptyLine() SchematicLine {
        return SchematicLine{
            .numbers = SchematicNumberList{},
            .symbols = SchematicSymbolList{},
        };
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
    var previous_line = SchematicLine.emptyLine();
    var current_line = SchematicLine.emptyLine();
    var next_line = SchematicLine.emptyLine();
    var sum_1a: u64 = 0;
    while (!eof) {
        var number_gpa = std.heap.GeneralPurposeAllocator(.{}){};
        var symbol_gpa = std.heap.GeneralPurposeAllocator(.{}){};
        file.reader().streamUntilDelimiter(fbs.writer(), '\n', fbs.buffer.len) catch |err| switch (err) {
            error.EndOfStream => eof = true,
            else => |e| return e,
        };
        const line = fbs.getWritten();
        previous_line = current_line;
        current_line = next_line;
        next_line = SchematicLine.from_raw_line(line, number_gpa.allocator(), symbol_gpa.allocator()) catch unreachable;
        sum_1a += RetrieveSummedPartValues(previous_line.symbols, current_line, next_line.symbols);
        fbs.reset();
    }
    sum_1a += RetrieveSummedPartValues(current_line.symbols, next_line, SchematicSymbolList{});
    try stdout.print("Result 1a: {d}\n", .{sum_1a});
    try bw.flush(); // don't forget to flush!
}
