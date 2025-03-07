const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 14;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    template: []const u8,
    rules: std.StringHashMap(u8),
    initial_pair_counts: std.StringHashMap(usize),
};

const Step = struct {
    polymer: []const u8,
    freq_count: [26]usize,
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    var rules = std.StringHashMap(u8).init(alloc);
    const template = lines[0];
    for (lines[2..]) |line| {
        var parts = std.mem.splitSequence(u8, line, " -> ");
        const key = parts.next().?;
        const value = parts.next().?[0];
        rules.put(key, value) catch unreachable;
    }
    ctx.template = template;
    ctx.rules = rules;
    ctx.initial_pair_counts = get_pair_counts(rules, template);
    return ctx;
}

fn get_pair_counts(rules: std.StringHashMap(u8), template: []const u8) std.StringHashMap(usize) {
    var pair_counts = std.StringHashMap(usize).init(alloc);
    var it = rules.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        pair_counts.put(key, 0) catch unreachable;
    }
    if (template.len == 0) return pair_counts;
    for (0..template.len - 1) |i| {
        const pair = std.fmt.allocPrint(alloc, "{c}{c}", .{ template[i], template[i + 1] }) catch unreachable;
        pair_counts.put(pair, pair_counts.get(pair).? + 1) catch unreachable;
    }

    return pair_counts;
}

fn get_polymer(pair_counts: std.StringHashMap(usize), letterCounts: *[26]usize, ctx: *Context) std.StringHashMap(usize) {
    var new_pair_counts = get_pair_counts(ctx.rules, "");

    var it = pair_counts.iterator();
    while (it.next()) |entry| {
        const pair = entry.key_ptr.*;
        const count = entry.value_ptr.*;
        const middle = ctx.rules.get(pair).?;
        const np1 = std.fmt.allocPrint(alloc, "{c}{c}", .{ pair[0], middle }) catch unreachable;
        const np2 = std.fmt.allocPrint(alloc, "{c}{c}", .{ middle, pair[1] }) catch unreachable;
        new_pair_counts.put(np1, new_pair_counts.get(np1).? + count) catch unreachable;
        new_pair_counts.put(np2, new_pair_counts.get(np2).? + count) catch unreachable;
        letterCounts.*[middle - 'A'] += count;
    }

    return new_pair_counts;
}

fn get_result(freq_count: [26]usize) usize {
    var max: usize = 0;
    var min: usize = std.math.maxInt(usize);
    for (freq_count) |count| {
        if (count > max) {
            max = count;
        }
        if (count < min and count > 0) {
            min = count;
        }
    }
    return max - min;
}

fn part1() ![]const u8 {
    const ctx = parse();
    var pair_counts = ctx.initial_pair_counts;
    var freq_count: [26]usize = @splat(0);
    for (0..10) |_| {
        pair_counts = get_polymer(pair_counts, &freq_count, ctx);
    }
    const result = get_result(freq_count);
    return try std.fmt.allocPrint(alloc, "part_1={}", .{result + 1});
}

fn part2() ![]const u8 {
    const ctx = parse();
    var pair_counts = ctx.initial_pair_counts;
    var freq_count: [26]usize = @splat(0);
    for (0..40) |_| {
        pair_counts = get_polymer(pair_counts, &freq_count, ctx);
    }
    const result = get_result(freq_count);
    return try std.fmt.allocPrint(alloc, "part_2={}", .{result + 1});
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
