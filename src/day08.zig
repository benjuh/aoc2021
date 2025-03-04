const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 8;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    lines: [][]const u8,
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.lines = lines;
    ctx.count = lines.len;
    return ctx;
}

const Output = struct {
    part1: usize,
    part2: usize,
};

fn get_values(ctx: *Context) Output {
    var p1: usize = 0;
    var p2: usize = 0;
    for (ctx.lines) |line| {
        var sections = std.mem.tokenizeAny(u8, line, "|");
        const signals = std.mem.trim(u8, sections.next().?, " ");
        const output = std.mem.trim(u8, sections.next().?, " ");

        var d = std.AutoHashMap(usize, []const u8).init(alloc);
        var sigs = std.mem.tokenizeSequence(u8, signals, " ");
        while (sigs.next()) |signal| {
            if (signal.len == 2 or signal.len == 4) {
                d.put(signal.len, signal) catch unreachable;
            }
        }

        var n = std.ArrayList(u8).init(alloc);
        var outs = std.mem.tokenizeSequence(u8, output, " ");
        while (outs.next()) |o| {
            const len = o.len;
            switch (len) {
                2 => {
                    n.append('1') catch unreachable;
                    p1 += 1;
                },
                3 => {
                    n.append('7') catch unreachable;
                    p1 += 1;
                },
                4 => {
                    n.append('4') catch unreachable;
                    p1 += 1;
                },
                7 => {
                    n.append('8') catch unreachable;
                    p1 += 1;
                },
                5 => {
                    var set = std.AutoHashMap(u8, void).init(alloc);
                    for (o) |c| {
                        set.put(c, {}) catch unreachable;
                    }
                    var and_d2 = std.AutoHashMap(u8, void).init(alloc);
                    var and_d4 = std.AutoHashMap(u8, void).init(alloc);
                    for (d.get(2).?) |c| {
                        if (set.contains(c)) {
                            and_d2.put(c, {}) catch unreachable;
                        }
                    }
                    for (d.get(4).?) |c| {
                        if (set.contains(c)) {
                            and_d4.put(c, {}) catch unreachable;
                        }
                    }
                    if (and_d2.count() == 2) {
                        n.append('3') catch unreachable;
                    } else if (and_d4.count() == 2) {
                        n.append('2') catch unreachable;
                    } else {
                        n.append('5') catch unreachable;
                    }
                },
                else => {
                    var set = std.AutoHashMap(u8, void).init(alloc);
                    for (o) |c| {
                        set.put(c, {}) catch unreachable;
                    }
                    var and_d2 = std.AutoHashMap(u8, void).init(alloc);
                    var and_d4 = std.AutoHashMap(u8, void).init(alloc);
                    for (d.get(2).?) |c| {
                        if (set.contains(c)) {
                            and_d2.put(c, {}) catch unreachable;
                        }
                    }
                    for (d.get(4).?) |c| {
                        if (set.contains(c)) {
                            and_d4.put(c, {}) catch unreachable;
                        }
                    }
                    if (and_d2.count() == 1) {
                        n.append('6') catch unreachable;
                    } else if (and_d4.count() == 4) {
                        n.append('9') catch unreachable;
                    } else {
                        n.append('0') catch unreachable;
                    }
                },
            }
        }
        const n_as_str = n.toOwnedSlice() catch unreachable;
        p2 += std.fmt.parseInt(usize, n_as_str, 10) catch unreachable;
    }

    return Output{ .part1 = p1, .part2 = p2 };
}

fn part1() ![]const u8 {
    const ctx = parse();
    const output = get_values(ctx);
    return try std.fmt.allocPrint(alloc, "part_1={}", .{output.part1});
}

fn part2() ![]const u8 {
    const ctx = parse();
    const output = get_values(ctx);
    return try std.fmt.allocPrint(alloc, "part_2={}", .{output.part2});
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
