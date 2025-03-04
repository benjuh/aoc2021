const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 9;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    lines: [][]const u8,
    width: usize,
    height: usize,
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.lines = lines;
    ctx.height = lines.len;
    ctx.width = lines[0].len;

    return ctx;
}

const directions = [_][2]i32{
    [2]i32{ 0, 1 },
    [2]i32{ 0, -1 },
    [2]i32{ 1, 0 },
    [2]i32{ -1, 0 },
};

fn check_adjacent(ctx: *Context, row: usize, col: usize) bool {
    var is_lowest: bool = true;
    const value = ctx.lines[row][col] - '0';
    for (directions) |dir| {
        const r: i32 = @intCast(row);
        const c: i32 = @intCast(col);
        const new_row: i32 = r + dir[0];
        const new_col: i32 = c + dir[1];
        if (new_row < 0 or new_row >= ctx.height or new_col < 0 or new_col >= ctx.width) {
            continue;
        }
        const nr: usize = @intCast(new_row);
        const nc: usize = @intCast(new_col);
        const adj_value = ctx.lines[nr][nc] - '0';
        if (adj_value <= value) {
            is_lowest = false;
            break;
        }
    }

    return is_lowest;
}

const Point = @Vector(2, i32);
fn get_basin(ctx: *Context, row: i32, col: i32, visited: *std.AutoHashMap(Point, void)) std.AutoHashMap(Point, void) {
    var basin = std.AutoHashMap(Point, void).init(alloc);
    var queue = std.fifo.LinearFifo(Point, .Dynamic).init(alloc);

    queue.writeItem(Point{ row, col }) catch unreachable;
    basin.put(Point{ row, col }, {}) catch unreachable;
    visited.put(Point{ row, col }, {}) catch unreachable;

    while (queue.readItem()) |point| {
        for (directions) |dir| {
            const r: i32 = @intCast(point[0]);
            const c: i32 = @intCast(point[1]);
            const new_row: i32 = r + dir[0];
            const new_col: i32 = c + dir[1];
            if (new_row < 0 or new_row >= ctx.height or new_col < 0 or new_col >= ctx.width) {
                continue;
            }
            if (visited.get(Point{ new_row, new_col })) |_| {
                continue;
            }
            if (basin.get(Point{ new_row, new_col })) |_| {
                continue;
            }
            const nr: usize = @intCast(new_row);
            const nc: usize = @intCast(new_col);
            if (ctx.lines[nr][nc] == '9') {
                continue;
            }
            queue.writeItem(Point{ new_row, new_col }) catch unreachable;
            visited.put(Point{ new_row, new_col }, {}) catch unreachable;
            basin.put(Point{ new_row, new_col }, {}) catch unreachable;
        }
    }
    return basin;
}

fn part1() ![]const u8 {
    const ctx = parse();
    var sum: usize = 0;
    for (ctx.lines, 0..) |line, row| {
        for (line, 0..) |value, col| {
            if (check_adjacent(ctx, row, col)) {
                sum += 1 + (value - '0');
            }
        }
    }
    return try std.fmt.allocPrint(alloc, "part_1={}", .{sum});
}

fn part2() ![]const u8 {
    const ctx = parse();
    var basin_sizes = std.ArrayList(usize).init(alloc);
    var visited = std.AutoHashMap(Point, void).init(alloc);
    for (ctx.lines, 0..) |line, row| {
        for (line, 0..) |value, col| {
            if (value == '9') continue;
            const c: i32 = @intCast(col);
            const r: i32 = @intCast(row);
            if (visited.get(Point{ r, c })) |_| {
                continue;
            }
            const basin = get_basin(ctx, r, c, &visited);
            basin_sizes.append(basin.count()) catch unreachable;
        }
    }
    const basins = basin_sizes.toOwnedSlice() catch unreachable;
    std.mem.sort(usize, basins, {}, std.sort.desc(usize));

    const res = basins[0] * basins[1] * basins[2];
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
