const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 3;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    lines: [][]const u8,
    binary_columns: [][]u1,
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.lines = lines;
    ctx.count = lines.len;
    ctx.binary_columns = get_cols(lines) catch unreachable;
    return ctx;
}

fn get_bit_value(c: u8) u1 {
    return switch (c) {
        '0' => 0,
        '1' => 1,
        else => unreachable,
    };
}

fn get_gamma_and_epsilon(cols: [][]u1) [2]usize {
    var gamma_rate: usize = 0;
    var epsilon_rate: usize = 0;
    for (cols) |col| {
        var ones: usize = 0;
        var zeroes: usize = 0;
        for (col) |bit| {
            if (bit == 1) {
                ones += 1;
            } else {
                zeroes += 1;
            }
        }
        if (ones >= zeroes) {
            gamma_rate = (gamma_rate << 1) | 1;
            epsilon_rate = (epsilon_rate << 1) | 0;
        } else {
            gamma_rate = (gamma_rate << 1) | 0;
            epsilon_rate = (epsilon_rate << 1) | 1;
        }
    }

    return [2]usize{ gamma_rate, epsilon_rate };
}

fn part1() ![]const u8 {
    const ctx = parse();
    const gamma, const epsilon = get_gamma_and_epsilon(ctx.binary_columns);
    return try std.fmt.allocPrint(alloc, "part_1={any}", .{gamma * epsilon});
}

fn get_binary(num: usize) ![]const u8 {
    return try std.fmt.allocPrint(alloc, "{b}", .{num});
}

fn get_cols(lines: [][]const u8) ![][]u1 {
    const cols = alloc.alloc([]u1, lines[0].len) catch unreachable;
    for (cols) |*col| {
        col.* = alloc.alloc(u1, lines.len) catch unreachable;
    }
    for (lines, 0..) |line, i| {
        for (line, 0..) |c, j| {
            cols[j][i] = get_bit_value(c);
        }
    }

    return cols;
}

fn get_most_and_least_common(column: []u1) [2]u8 {
    var ones: usize = 0;
    var zeroes: usize = 0;
    for (column) |bit| {
        if (bit == 1) {
            ones += 1;
        } else {
            zeroes += 1;
        }
    }
    if (ones >= zeroes) {
        return [2]u8{ '1', '0' };
    } else {
        return [2]u8{ '0', '1' };
    }
}

fn get_o2_rating(binaries: [][]const u8, cols: [][]u1, step: usize) ![]const u8 {
    if (binaries.len == 1) return binaries[0];
    const gamma = get_most_and_least_common(cols[step])[0];
    var new_binaries = std.ArrayList([]const u8).init(alloc);
    for (binaries) |binary| {
        if (binary[step] == gamma) {
            try new_binaries.append(binary);
        }
    }
    const new_cols = try get_cols(new_binaries.items);
    return get_o2_rating(new_binaries.items, new_cols, step + 1);
}

fn get_co2_rating(binaries: [][]const u8, cols: [][]u1, step: usize) ![]const u8 {
    if (binaries.len == 1) return binaries[0];
    const epsilon = get_most_and_least_common(cols[step])[1];
    var new_binaries = std.ArrayList([]const u8).init(alloc);
    for (binaries) |binary| {
        if (binary[step] == epsilon) {
            try new_binaries.append(binary);
        }
    }
    const new_cols = try get_cols(new_binaries.items);
    return get_co2_rating(new_binaries.items, new_cols, step + 1);
}

fn part2() ![]const u8 {
    const ctx = parse();
    const o2_rating = try get_o2_rating(ctx.lines, ctx.binary_columns, 0);
    const co2_rating = try get_co2_rating(ctx.lines, ctx.binary_columns, 0);

    const o2 = std.fmt.parseInt(usize, o2_rating, 2) catch unreachable;
    const co2 = std.fmt.parseInt(usize, co2_rating, 2) catch unreachable;

    return try std.fmt.allocPrint(alloc, "part_2={}\n", .{o2 * co2});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    var timer = try Timer.start();
    const p1 = try part1();
    const elapsed: f64 = @floatFromInt(timer.read());

    var timer2 = try Timer.start();
    const p2 = try part2();
    const elapsed2: f64 = @floatFromInt(timer2.read());

    common.run_day(DAY, p1, elapsed, p2, elapsed2, alloc);
}
