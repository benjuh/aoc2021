const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 11;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const adjacents = [_][2]i32{
    [2]i32{ -1, 0 },
    [2]i32{ 1, 0 },
    [2]i32{ 0, -1 },
    [2]i32{ 0, 1 },
    [2]i32{ -1, -1 },
    [2]i32{ 1, -1 },
    [2]i32{ -1, 1 },
    [2]i32{ 1, 1 },
};

const Point = struct {
    row: usize,
    col: usize,
};

const Context = struct {
    count: usize,
    octopuses: [10][10]u8,
    flashes: usize,

    pub fn step(self: *Context) usize {
        var local_flashes: usize = 0;
        var queue = std.fifo.LinearFifo(Point, .Dynamic).init(alloc);
        var visited = std.AutoHashMap(Point, void).init(alloc);
        for (self.octopuses, 0..) |row, r| {
            for (row, 0..) |_, c| {
                self.octopuses[r][c] += 1;
                if (self.octopuses[r][c] > 9) {
                    self.octopuses[r][c] = 0;
                    local_flashes += 1;
                    queue.writeItem(Point{ .row = r, .col = c }) catch unreachable;
                    visited.put(Point{ .row = r, .col = c }, {}) catch unreachable;
                }
            }
        }

        while (queue.readItem()) |point| {
            visited.put(point, {}) catch unreachable;
            self.flashes += 1;
            for (adjacents) |adjacent| {
                const dr = adjacent[0];
                const dc = adjacent[1];
                const r: i32 = @intCast(point.row);
                const c: i32 = @intCast(point.col);
                const nr = r + dr;
                const nc = c + dc;
                if (nr < 0 or nr >= self.octopuses.len or nc < 0 or nc >= self.octopuses[0].len) {
                    continue;
                }
                const new_row: usize = @intCast(nr);
                const new_col: usize = @intCast(nc);
                if (visited.contains(Point{ .row = new_row, .col = new_col })) {
                    continue;
                }
                self.octopuses[new_row][new_col] += 1;
                if (self.octopuses[new_row][new_col] > 9) {
                    self.octopuses[new_row][new_col] = 0;
                    visited.put(Point{ .row = new_row, .col = new_col }, {}) catch unreachable;
                    local_flashes += 1;
                    queue.writeItem(Point{ .row = new_row, .col = new_col }) catch unreachable;
                }
            }
        }

        return local_flashes;
    }

    pub fn print_octopuses(self: *const Context) void {
        print("\n", .{});
        const green = "\x1b[32m";
        const reset = "\x1b[0m";
        for (self.octopuses) |row| {
            for (row) |cell| {
                if (cell == 0) {
                    print("{s}{d}{s}", .{ green, cell, reset });
                    continue;
                }
                print("{d}", .{cell});
            }
            print("\n", .{});
        }
    }
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    var octopuses: [10][10]u8 = undefined;
    for (lines, 0..) |line, i| {
        for (line, 0..) |c, j| {
            octopuses[i][j] = c - '0';
        }
    }
    ctx.octopuses = octopuses;
    ctx.count = lines.len;
    ctx.flashes = 0;

    return ctx;
}

fn part1() ![]const u8 {
    const ctx = parse();
    const steps = 100;
    for (0..steps) |_| {
        _ = ctx.step();
    }
    return try std.fmt.allocPrint(alloc, "part_1={}", .{ctx.flashes});
}

fn part2() ![]const u8 {
    const ctx = parse();
    var i: usize = 0;
    while (true) {
        i += 1;
        const flashes = ctx.step();
        if (flashes == 100) {
            break;
        }
    }
    return try std.fmt.allocPrint(alloc, "part_2={}", .{i});
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
