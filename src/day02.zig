const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 2;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    lines: [][]const u8,
    commands: []Command,
    registers: [2]i64 = [_]i64{ 0, 0 },
};

const Command = struct {
    dir: dir,
    val: i32,
};

const dir = enum {
    up,
    down,
    forward,

    pub fn get_dir(str: []const u8) dir {
        return switch (str[0]) {
            'f' => .forward,
            'u' => .up,
            'd' => .down,
            else => unreachable,
        };
    }
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.lines = lines;
    ctx.count = lines.len;
    ctx.commands = alloc.alloc(Command, ctx.count) catch unreachable;
    ctx.registers[0] = 0;
    ctx.registers[1] = 0;

    for (lines, 0..) |line, i| {
        var sections = std.mem.splitAny(u8, line, " ");
        const first = sections.next() orelse unreachable;
        const second = sections.next() orelse unreachable;
        const d = dir.get_dir(first);
        const val = std.fmt.parseInt(i32, second, 10) catch unreachable;
        ctx.commands[i] = Command{ .dir = d, .val = val };
    }

    return ctx;
}

fn part1() ![]const u8 {
    const ctx = parse();
    for (ctx.commands) |cmd| {
        const d = cmd.dir;
        const val = cmd.val;
        switch (d) {
            .up => ctx.registers[0] -= val,
            .down => ctx.registers[0] += val,
            .forward => ctx.registers[1] += val,
        }
    }
    const res: i64 = ctx.registers[0] * ctx.registers[1];
    return try std.fmt.allocPrint(alloc, "part_1={}", .{res});
}

fn part2() ![]const u8 {
    const ctx = parse();
    var aim: i64 = 0;
    var depth: i64 = 0;
    for (ctx.commands) |cmd| {
        const d = cmd.dir;
        const val = cmd.val;
        switch (d) {
            .up => {
                aim -= val;
            },
            .down => {
                aim += val;
            },
            .forward => {
                ctx.registers[1] += val;
                depth += aim * val;
            },
        }
    }

    const res: i64 = ctx.registers[1] * depth;
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
