const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 15;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    lines: [][]u8,
    start: Point,
    end: Point,
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    var new_lines = alloc.alloc([]u8, lines.len) catch unreachable;
    for (new_lines) |*row| {
        row.* = alloc.alloc(u8, lines[0].len) catch unreachable;
    }
    for (new_lines, 0..) |row, y| {
        for (row, 0..) |_, x| {
            new_lines[y][x] = lines[y][x];
        }
    }
    ctx.lines = new_lines;
    ctx.count = lines.len;
    ctx.start = Point{ .x = 0, .y = 0 };
    ctx.end = Point{ .x = @intCast(ctx.count - 1), .y = @intCast(ctx.count - 1) };
    return ctx;
}

fn parse_int(char: u8) usize {
    return char - '0';
}

const directions = [4][2]i32{
    [2]i32{ 0, 1 },
    [2]i32{ 0, -1 },
    [2]i32{ 1, 0 },
    [2]i32{ -1, 0 },
};

const Point = struct {
    x: i32,
    y: i32,
};

const Path = struct {
    risk: usize,
    node: Point,
};

fn pathfind(ctx: *Context, grid: [][]u8) usize {
    var visited = std.AutoHashMap(Point, void).init(alloc);
    var pq = std.PriorityQueue(Path, void, less_than).init(alloc, {});
    const start_risk = parse_int(grid[@intCast(ctx.start.y)][@intCast(ctx.start.x)]);

    pq.add(Path{ .risk = start_risk, .node = ctx.start }) catch unreachable;

    while (pq.count() > 0) {
        const path = pq.remove();
        const node = path.node;
        const risk = path.risk;
        if (node.x == ctx.end.x and node.y == ctx.end.y) {
            return risk - start_risk;
        }

        if (visited.contains(node)) {
            continue;
        }
        for (directions) |dir| {
            const dx = dir[0];
            const dy = dir[1];
            const new_x = node.x + dx;
            const new_y = node.y + dy;
            if (new_x >= grid[0].len or new_x < 0 or new_y >= grid.len or new_y < 0) {
                continue;
            }
            const xx: usize = @intCast(new_x);
            const yy: usize = @intCast(new_y);
            const next_risk = risk + parse_int(grid[yy][xx]);
            const next = Point{ .x = new_x, .y = new_y };
            pq.add(Path{ .risk = next_risk, .node = next }) catch unreachable;
        }
        visited.put(node, {}) catch unreachable;
    }

    return std.math.maxInt(usize);
}

fn less_than(context: void, a: Path, b: Path) std.math.Order {
    _ = context;
    return std.math.order(a.risk, b.risk);
}

fn part1() ![]const u8 {
    const ctx = parse();
    const res = pathfind(ctx, ctx.lines);
    return try std.fmt.allocPrint(alloc, "part_1={}", .{res});
}

fn part2() ![]const u8 {
    const ctx = parse();
    const new_grid = try get_bigger_grid(ctx.lines, 5);
    ctx.end = Point{ .x = @intCast(new_grid[0].len - 1), .y = @intCast(new_grid.len - 1) };
    const res = pathfind(ctx, new_grid);
    return try std.fmt.allocPrint(alloc, "part_2={}", .{res});
}

fn get_bigger_grid(grid: [][]u8, multiplier: usize) ![][]u8 {
    var new_grid = try alloc.alloc([]u8, grid.len * multiplier);
    for (new_grid) |*row| {
        row.* = try alloc.alloc(u8, grid[0].len * multiplier);
    }

    for (new_grid, 0..) |row, y| {
        for (row, 0..) |_, x| {
            if (x < grid.len and y < grid[0].len) {
                new_grid[y][x] = grid[y][x];
            } else if (x < grid.len) {
                const old_index = (y % grid.len);
                var new_risk: u8 = @intCast((((grid[old_index][x] - '0') + (y / grid.len))) % 9);
                if (new_risk == 0) {
                    new_risk = 9;
                }
                new_grid[y][x] = new_risk + '0';
            } else if (y < grid[0].len) {
                const old_index = (x % grid[0].len);
                var new_risk: u8 = @intCast((((grid[y][old_index] - '0') + (x / grid[0].len)) % 9));
                if (new_risk == 0) {
                    new_risk = 9;
                }
                new_grid[y][x] = new_risk + '0';
            } else {
                const old_x = x % grid[0].len;
                const old_y = y % grid.len;
                const additive_y: u8 = @intCast(x / grid[0].len);
                const additive_x: u8 = @intCast(y / grid.len);
                var new_risk: u8 = @intCast((((grid[old_y][old_x] - '0') + (additive_y + additive_x)) % 9));
                if (new_risk == 0) {
                    new_risk = 9;
                }
                new_grid[y][x] = new_risk + '0';
            }
        }
    }

    return new_grid;
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
