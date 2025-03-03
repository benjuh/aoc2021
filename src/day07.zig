const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 7;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    lines: [][]const u8,
    positions: []i64,
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.lines = lines;
    ctx.count = lines.len;
    ctx.positions = common.get_ints(i64, lines[0], alloc, ",") catch unreachable;

    return ctx;
}

fn total_fuel(ctx: *Context, alignment: i64) usize {
    var total: usize = 0;
    for (ctx.positions) |pos| {
        total += @abs(pos - alignment);
    }

    return total;
}

fn total_fuel_2(ctx: *Context, alignment: i64) usize {
    var total: usize = 0;
    for (ctx.positions) |pos| {
        const n = @abs(pos - alignment);
        const numerator = n * (n + 1);
        const denominator = 2;
        total += @divFloor(numerator, denominator);
    }
    return total;
}

fn part1() ![]const u8 {
    const ctx = parse();
    var min_fuel: usize = std.math.maxInt(usize);
    for (ctx.positions) |pos| {
        min_fuel = @min(min_fuel, total_fuel(ctx, pos));
    }
    return try std.fmt.allocPrint(alloc, "part_1={}", .{min_fuel});
}

fn part2() ![]const u8 {
    const ctx = parse();
    var min_fuel: usize = std.math.maxInt(usize);
    const statistics = stats(ctx);
    for (statistics.min..statistics.max + 1) |p| {
        const pos: i64 = @intCast(p);
        min_fuel = @min(min_fuel, total_fuel_2(ctx, pos));
    }
    return try std.fmt.allocPrint(alloc, "part_2={}", .{min_fuel});
}

const Stats = struct {
    min: usize,
    max: usize,
};

fn stats(ctx: *Context) Stats {
    var min: usize = std.math.maxInt(usize);
    var max: usize = 0;
    for (ctx.positions) |p| {
        const pos: usize = @intCast(p);
        min = @min(min, pos);
        max = @max(max, pos);
    }

    return Stats{
        .min = min,
        .max = max,
    };
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
