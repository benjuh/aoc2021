const std = @import("std");
const print = std.debug.print;

const BLAZING = "\x1b[38;2;0;0;0m";
const GREEN = "\x1b[32m";
const BRIGHT_GREEN = "\x1b[38;2;0;255;0m";
const RED = "\x1b[31m";
const ORANGE = "\x1b[33m";
const RESET = "\x1b[0m";

const NANOSECONDS_PER_SECOND = 1000000000;
const NANOSECONDS_PER_MILLISECOND = 1000000;
const NANOSECONDS_PER_MICROSECOND = 1000;

pub fn get_ints(comptime T: type, line: []const u8, allocator: std.mem.Allocator, delimiter: []const u8) ![]T {
    var nums = std.ArrayList(T).init(allocator);
    var iter = std.mem.tokenizeAny(u8, line, delimiter);
    while (iter.next()) |num| {
        const n = std.fmt.parseInt(T, num, 10) catch unreachable;
        try nums.append(n);
    }
    return nums.toOwnedSlice();
}

pub fn get_lines(comptime day: usize, allocator: std.mem.Allocator, comptime test_data: bool) [][]const u8 {
    var data: []const u8 = undefined;
    if (test_data) {
        data = @embedFile("data/test/day" ++ std.fmt.comptimePrint("{d}.txt", .{day}));
    } else {
        data = @embedFile("data/day" ++ std.fmt.comptimePrint("{d}.txt", .{day}));
    }
    var lines = std.ArrayList([]const u8).init(allocator);
    var iter = std.mem.splitAny(u8, data, "\n");
    while (iter.next()) |line| {
        const new_line = std.mem.trim(u8, line, " ");
        lines.append(new_line) catch unreachable;
    }
    if (lines.items[lines.items.len - 1].len == 0) _ = lines.pop();
    return lines.items;
}

pub fn get_lines_no_strip(comptime day: usize, allocator: std.mem.Allocator, comptime test_data: bool) [][]const u8 {
    var data: []const u8 = undefined;
    if (test_data) {
        data = @embedFile("data/test/day" ++ std.fmt.comptimePrint("{d}.txt", .{day}));
    } else {
        data = @embedFile("data/day" ++ std.fmt.comptimePrint("{d}.txt", .{day}));
    }
    var lines = std.ArrayList([]const u8).init(allocator);
    var iter = std.mem.splitAny(u8, data, "\n");
    while (iter.next()) |line| lines.append(line) catch unreachable;
    if (lines.items[lines.items.len - 1].len == 0) _ = lines.pop();
    return lines.items;
}

pub fn print_lines(lines: [][]const u8, allocator: std.mem.Allocator) !void {
    var longest: usize = 0;
    for (lines) |line| {
        if (line.len > longest) longest = line.len;
    }
    var cl: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer cl.deinit();
    for (0..longest) |_| {
        try cl.append('-');
    }

    std.debug.print("{s}\n", .{cl.items});
    for (lines) |line| std.debug.print("{s}\n", .{line});
    std.debug.print("{s}\n", .{cl.items});
}

const Part = struct {
    output: []const u8,
    time: f64,

    pub fn to_string(part: Part, allocator: std.mem.Allocator) []const u8 {
        const str = std.fmt.allocPrint(allocator, "{s}{d:.3}{s:<8}{s}\t{s}", .{
            get_color(part),
            get_time_number(part),
            get_time_format(part),
            RESET,
            part.output,
        }) catch unreachable;
        return str;
    }

    fn get_color(part: Part) []const u8 {
        if (part.time < NANOSECONDS_PER_MICROSECOND) return BLAZING;
        if (part.time < NANOSECONDS_PER_MILLISECOND) return BRIGHT_GREEN;
        if (part.time < NANOSECONDS_PER_MILLISECOND * 250) return GREEN;
        if (part.time < NANOSECONDS_PER_SECOND) return ORANGE;
        return RED;
    }

    fn get_time_format(part: Part) []const u8 {
        if (part.time < NANOSECONDS_PER_MICROSECOND) return "ns";
        if (part.time < NANOSECONDS_PER_MILLISECOND) return "µs";
        if (part.time < NANOSECONDS_PER_SECOND) return "ms";
        return "s";
    }

    fn get_time_number(part: Part) f64 {
        if (part.time < NANOSECONDS_PER_MICROSECOND) return part.time;
        if (part.time < NANOSECONDS_PER_MILLISECOND) return part.time / NANOSECONDS_PER_MICROSECOND;
        if (part.time < NANOSECONDS_PER_SECOND) return part.time / NANOSECONDS_PER_MILLISECOND;
        return part.time / NANOSECONDS_PER_SECOND;
    }
};

pub fn run_day(day: usize, part1: []const u8, time1: f64, part2: []const u8, time2: f64, allocator: std.mem.Allocator) void {
    print("\n[ Day {} ] \n", .{day});
    const p1 = Part{ .output = part1, .time = time1 };
    const p2 = Part{ .output = part2, .time = time2 };
    print("{s}\n", .{p1.to_string(allocator)});
    print("{s}\n\n", .{p2.to_string(allocator)});
}
