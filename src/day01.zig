const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 1;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    nums: []u64,
    lines: [][]const u8,
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    var nums = alloc.alloc(u64, lines.len) catch unreachable;
    for (lines, 0..) |line, i| {
        nums[i] = std.fmt.parseInt(u64, line, 10) catch unreachable;
    }
    ctx.lines = lines;
    ctx.nums = nums;
    ctx.count = nums.len;

    return ctx;
}

fn part1() ![]const u8 {
    const ctx = parse();
    var increasing: usize = 0;
    for (ctx.nums[1..], 1..) |num, i| {
        if (num > ctx.nums[i - 1]) {
            increasing += 1;
        }
    }
    return try std.fmt.allocPrint(alloc, "part_1={}", .{increasing});
}

fn part2() ![]const u8 {
    const ctx = parse();
    var sums = alloc.alloc(usize, ctx.count - 2) catch unreachable;
    for (ctx.nums[2..], 2..) |num, i| {
        sums[i - 2] = ctx.nums[i - 2] + ctx.nums[i - 1] + num;
    }
    var increasing: usize = 0;
    for (sums[1..], 1..) |sum, i| {
        if (sum > sums[i - 1]) {
            increasing += 1;
        }
    }

    return try std.fmt.allocPrint(alloc, "part_2={}", .{increasing});
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
