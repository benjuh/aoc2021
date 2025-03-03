const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 6;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    lines: [][]const u8,
    nums: []u4,
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.lines = lines;
    ctx.count = lines.len;
    const nums = common.get_ints(u4, lines[0], alloc, ",") catch unreachable;
    ctx.nums = nums;

    return ctx;
}

fn get_lanternfish(ctx: *Context, days: usize) usize {
    var states = std.AutoHashMap(u4, usize).init(alloc);

    for (0..9) |i| {
        const i_u4: u4 = @intCast(i);
        states.put(i_u4, 0) catch unreachable;
    }

    for (ctx.nums) |num| {
        if (!states.contains(num)) {
            states.put(num, 0) catch unreachable;
        }
        states.put(num, states.get(num).? + 1) catch unreachable;
    }

    var next_states = std.AutoHashMap(u4, usize).init(alloc);
    for (0..days) |_| {
        next_states.put(0, states.get(1).?) catch unreachable;
        next_states.put(1, states.get(2).?) catch unreachable;
        next_states.put(2, states.get(3).?) catch unreachable;
        next_states.put(3, states.get(4).?) catch unreachable;
        next_states.put(4, states.get(5).?) catch unreachable;
        next_states.put(5, states.get(6).?) catch unreachable;
        next_states.put(6, states.get(7).?) catch unreachable;
        next_states.put(7, states.get(8).?) catch unreachable;
        next_states.put(8, states.get(0).?) catch unreachable;

        if (states.get(0).? > 0) {
            next_states.put(6, next_states.get(6).? + states.get(0).?) catch unreachable;
        }

        states = next_states;
        next_states = std.AutoHashMap(u4, usize).init(alloc);
    }

    var lanternfish: usize = 0;
    var it = states.iterator();
    while (it.next()) |kv| {
        lanternfish += kv.value_ptr.*;
    }

    return lanternfish;
}

fn part1() ![]const u8 {
    const ctx = parse();
    const lanternfish = get_lanternfish(ctx, 80);
    return try std.fmt.allocPrint(alloc, "part_1={}", .{lanternfish});
}

fn part2() ![]const u8 {
    const ctx = parse();
    const lanternfish = get_lanternfish(ctx, 256);
    return try std.fmt.allocPrint(alloc, "part_2={}", .{lanternfish});
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
