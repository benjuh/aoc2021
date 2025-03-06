const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 13;
const IS_TEST = false;

const X = 120;
const Y = 121;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    grid: *std.AutoHashMap(Dot, void),
    folds: []Fold,
    min_x: usize,
    max_x: usize,
    min_y: usize,
    max_y: usize,

    pub fn fold_up(self: *Context, at: usize) void {
        var it = self.grid.iterator();
        while (it.next()) |entry| {
            const key = entry.key_ptr.*;
            if (key.y <= at) {
                continue;
            }
            const x = key.x;
            const y = at - (key.y - at);
            _ = self.grid.remove(key);
            const new_dot = Dot{
                .x = x,
                .y = y,
            };
            self.grid.put(new_dot, {}) catch unreachable;
        }
        self.max_y = at - 1;
    }

    pub fn fold_left(self: *Context, at: usize) void {
        var it = self.grid.iterator();
        while (it.next()) |entry| {
            const key = entry.key_ptr.*;
            if (key.x <= at) {
                continue;
            }
            const x = at - (key.x - at);
            const y = key.y;
            _ = self.grid.remove(key);
            const new_dot = Dot{
                .x = x,
                .y = y,
            };
            self.grid.put(new_dot, {}) catch unreachable;
        }
        self.max_x = at - 1;
    }

    pub fn print_grid(self: *Context) void {
        print("\n", .{});
        for (self.min_y..self.max_y + 1) |y| {
            for (self.min_x..self.max_x + 1) |x| {
                const key = Dot{ .x = x, .y = y };
                if (self.grid.get(key)) |_| {
                    print("#", .{});
                } else {
                    print(".", .{});
                }
            }
            print("\n", .{});
        }
    }
};

const Fold = struct {
    axis: u8,
    at: usize,
};

const Dot = struct {
    y: usize,
    x: usize,
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    const grid = alloc.create(std.AutoHashMap(Dot, void)) catch unreachable;
    grid.* = std.AutoHashMap(Dot, void).init(alloc);
    var folds = std.ArrayList(Fold).init(alloc);
    var min_x: usize = std.math.maxInt(usize);
    var max_x: usize = 0;
    var min_y: usize = std.math.maxInt(usize);
    var max_y: usize = 0;

    var is_done_with_grid = false;
    for (lines) |line| {
        if (line.len == 0) {
            is_done_with_grid = true;
            continue;
        }

        if (!is_done_with_grid) {
            var sections = std.mem.tokenizeScalar(u8, line, ',');
            const x = std.fmt.parseInt(usize, sections.next().?, 10) catch unreachable;
            const y = std.fmt.parseInt(usize, sections.next().?, 10) catch unreachable;
            grid.put(Dot{ .x = x, .y = y }, void{}) catch unreachable;
            min_x = @min(min_x, x);
            max_x = @max(max_x, x);
            min_y = @min(min_y, y);
            max_y = @max(max_y, y);
        } else {
            var sections = std.mem.tokenizeScalar(u8, line, '=');
            const axis = sections.next().?;
            const fold_at = std.fmt.parseInt(usize, sections.next().?, 10) catch unreachable;
            folds.append(Fold{ .axis = axis[axis.len - 1], .at = fold_at }) catch unreachable;
        }
    }
    ctx.min_y = min_y;
    ctx.max_y = max_y;
    ctx.min_x = min_x;
    ctx.max_x = max_x;
    ctx.grid = grid;
    ctx.folds = folds.toOwnedSlice() catch unreachable;
    return ctx;
}
fn part1() ![]const u8 {
    const ctx = parse();
    for (ctx.folds, 0..) |fold, i| {
        if (i == 1) {
            break;
        }
        if (fold.axis == X) {
            ctx.fold_left(fold.at);
        } else {
            ctx.fold_up(fold.at);
        }
    }
    return try std.fmt.allocPrint(alloc, "part_1={}", .{ctx.grid.count()});
}

fn part2() ![]const u8 {
    const ctx = parse();
    for (ctx.folds) |fold| {
        if (fold.axis == X) {
            ctx.fold_left(fold.at);
        } else {
            ctx.fold_up(fold.at);
        }
    }
    ctx.print_grid();
    return try std.fmt.allocPrint(alloc, "part_2={s}", .{"LGHEGUEJ"});
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
