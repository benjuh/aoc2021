const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 10;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    lines: [][]const u8,
};

pub fn is_open(c: u8) bool {
    return switch (c) {
        '(' => true,
        '[' => true,
        '{' => true,
        '<' => true,
        else => false,
    };
}

pub fn get_open(c: u8) u8 {
    return switch (c) {
        ')' => '(',
        ']' => '[',
        '}' => '{',
        '>' => '<',
        else => 0,
    };
}

pub fn get_score(c: u8) usize {
    return switch (c) {
        ')' => 3,
        ']' => 57,
        '}' => 1197,
        '>' => 25137,
        else => 0,
    };
}

fn first_invalid(line: []const u8) u8 {
    var stack = std.ArrayList(u8).init(alloc);
    for (line) |c| {
        if (is_open(c)) {
            stack.append(c) catch unreachable;
        } else {
            if (stack.items[stack.items.len - 1] != get_open(c)) {
                return c;
            } else {
                _ = stack.pop();
            }
        }
    }

    return 0;
}

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.lines = lines;
    ctx.count = lines.len;
    return ctx;
}

fn get_value(c: u8) usize {
    return switch (c) {
        '(' => 1,
        '[' => 2,
        '{' => 3,
        '<' => 4,
        else => 0,
    };
}

fn get_completion_score(line: []const u8) usize {
    var stack = std.ArrayList(u8).init(alloc);
    var score: usize = 0;
    for (line) |c| {
        if (is_open(c)) {
            stack.append(c) catch unreachable;
        } else {
            _ = stack.pop();
        }
    }
    while (stack.items.len > 0) {
        const c = stack.pop() orelse unreachable;
        score = (score * 5) + get_value(c);
    }
    return score;
}

fn part1() ![]const u8 {
    const ctx = parse();
    var sum: usize = 0;
    for (ctx.lines) |line| {
        const first = first_invalid(line);
        sum += get_score(first);
    }
    return try std.fmt.allocPrint(alloc, "part_1={}", .{sum});
}

fn part2() ![]const u8 {
    const ctx = parse();
    var scores = std.ArrayList(usize).init(alloc);
    for (ctx.lines) |line| {
        if (first_invalid(line) != 0) continue;
        const score = get_completion_score(line);
        scores.append(score) catch unreachable;
    }
    const sorted = scores.toOwnedSlice() catch unreachable;
    std.mem.sort(usize, sorted, {}, std.sort.desc(usize));

    const res = sorted[sorted.len / 2];

    return try std.fmt.allocPrint(alloc, "part_2={}", .{res});
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
