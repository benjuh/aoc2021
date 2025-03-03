const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 5;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    lines: [][]const u8,
    ranges: []Range,
};

const Point = @Vector(2, isize);
const Delta = @Vector(2, isize);

const slope = enum {
    vertical,
    horizontal,
    diagonal,
};

const Range = struct {
    start: Point,
    end: Point,
    slope: slope,

    pub fn init(start: Point, end: Point) Range {
        return Range{
            .start = start,
            .end = end,
            .slope = get_slope(start, end),
        };
    }

    fn get_slope(start: Point, end: Point) slope {
        const start_x: i64 = @intCast(start[0]);
        const start_y: i64 = @intCast(start[1]);
        const end_x: i64 = @intCast(end[0]);
        const end_y: i64 = @intCast(end[1]);
        const dy: i64 = end_y - start_y;
        const dx: i64 = end_x - start_x;
        return switch (dx) {
            0 => slope.vertical,
            else => {
                return switch (dy) {
                    0 => slope.horizontal,
                    else => slope.diagonal,
                };
            },
        };
    }

    fn get_deltas(self: Range) Delta {
        if (self.start[0] < self.end[0] and self.start[1] < self.end[1]) {
            return Delta{ 1, 1 };
        } else if (self.start[0] > self.end[0] and self.start[1] > self.end[1]) {
            return Delta{ -1, -1 };
        } else if (self.start[0] < self.end[0] and self.start[1] > self.end[1]) {
            return Delta{ 1, -1 };
        } else {
            return Delta{ -1, 1 };
        }
    }

    pub fn get_points(self: Range) []Point {
        var points = std.ArrayList(Point).init(alloc);
        const startY = @min(self.start[1], self.end[1]);
        const endY = @max(self.start[1], self.end[1]);
        const startX = @min(self.start[0], self.end[0]);
        const endX = @max(self.start[0], self.end[0]);
        switch (self.slope) {
            slope.vertical => {
                const sy: usize = @intCast(startY);
                const ey: usize = @intCast(endY);
                for (sy..ey + 1) |y| {
                    const yy: isize = @intCast(y);
                    points.append(Point{ startX, yy }) catch unreachable;
                }
            },
            slope.horizontal => {
                const sx: usize = @intCast(startX);
                const ex: usize = @intCast(endX);
                for (sx..ex + 1) |x| {
                    const xx: isize = @intCast(x);
                    points.append(Point{ xx, startY }) catch unreachable;
                }
            },
            slope.diagonal => {
                const deltas = self.get_deltas();
                var p = Point{ self.start[0], self.start[1] };
                const end = Point{ self.end[0], self.end[1] };
                while (p[0] != end[0] and p[1] != end[1]) {
                    points.append(p) catch unreachable;
                    p += deltas;
                }
                points.append(p) catch unreachable;
            },
        }
        return points.toOwnedSlice() catch unreachable;
    }
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.lines = lines;
    ctx.count = lines.len;
    ctx.ranges = alloc.alloc(Range, ctx.count) catch unreachable;
    for (lines, 0..) |line, i| {
        var sections = std.mem.tokenizeAny(u8, line, " -> ");
        const first = sections.next() orelse unreachable;
        const second = sections.next() orelse unreachable;
        var p1 = std.mem.tokenizeScalar(u8, first, ',');
        const s1 = p1.next() orelse unreachable;
        const e1 = p1.next() orelse unreachable;
        var p2 = std.mem.tokenizeScalar(u8, second, ',');
        const s2 = p2.next() orelse unreachable;
        const e2 = p2.next() orelse unreachable;
        ctx.ranges[i] = Range.init(Point{
            std.fmt.parseInt(isize, s1, 10) catch unreachable,
            std.fmt.parseInt(isize, e1, 10) catch unreachable,
        }, Point{
            std.fmt.parseInt(isize, s2, 10) catch unreachable,
            std.fmt.parseInt(isize, e2, 10) catch unreachable,
        });
    }

    return ctx;
}

fn part1() ![]const u8 {
    const ctx = parse();
    var visited = std.AutoHashMap(Point, void).init(alloc);
    var overlaps = std.AutoHashMap(Point, void).init(alloc);

    for (ctx.ranges) |range| {
        if (range.slope != slope.vertical and range.slope != slope.horizontal) {
            continue;
        }

        const points = range.get_points();
        for (points) |point| {
            if (visited.contains(point)) {
                overlaps.put(point, {}) catch unreachable;
            } else {
                visited.put(point, {}) catch unreachable;
            }
        }
    }

    return try std.fmt.allocPrint(alloc, "part_1={}", .{overlaps.count()});
}

fn part2() ![]const u8 {
    const ctx = parse();
    var visited = std.AutoHashMap(Point, void).init(alloc);
    var overlaps = std.AutoHashMap(Point, void).init(alloc);

    for (ctx.ranges) |range| {
        const points = range.get_points();
        for (points) |point| {
            if (visited.contains(point)) {
                overlaps.put(point, {}) catch unreachable;
            } else {
                visited.put(point, {}) catch unreachable;
            }
        }
    }
    return try std.fmt.allocPrint(alloc, "part_1={}", .{overlaps.count()});
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
