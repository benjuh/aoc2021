const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 4;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    count: usize,
    lines: [][]const u8,
    boards: []BoardState,
    called: []u32,
};

const Board = [][]u32;

const BoardState = struct {
    board_rows: Board,
    board_cols: Board,
    called: std.AutoHashMap(u32, void),
};

fn get_cols(board: Board) [][]u32 {
    var cols = alloc.alloc([]u32, board.len) catch unreachable;
    for (cols) |*col| {
        col.* = alloc.alloc(u32, board.len) catch unreachable;
    }
    for (board, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            cols[j][i] = cell;
        }
    }
    return cols;
}

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.lines = lines;
    ctx.count = lines.len;
    ctx.called = common.get_ints(u32, lines[0], alloc, ",") catch unreachable;

    var boards = std.ArrayList(BoardState).init(alloc);
    var i: usize = 2;
    while (i < lines.len) {
        if (lines[i].len == 0) {
            i += 1;
            continue;
        }
        var board = alloc.alloc([]u32, 5) catch unreachable;
        for (0..5) |j| {
            const row = common.get_ints(u32, lines[i + j], alloc, " ") catch unreachable;
            board[j] = row;
        }
        const cols = get_cols(board);
        boards.append(BoardState{
            .board_rows = board,
            .board_cols = cols,
            .called = std.AutoHashMap(u32, void).init(alloc),
        }) catch unreachable;
        i += 5;
    }
    ctx.boards = boards.toOwnedSlice() catch unreachable;

    return ctx;
}

const bingo = struct {
    found: bool,
    score: u32,
};

fn bingo_score(context: *Context, boardIndex: usize) bingo {
    const board_rows = context.boards[boardIndex].board_rows;
    const board_cols = context.boards[boardIndex].board_cols;
    // check rows
    var total: u32 = 0;
    var found_bingo: bool = false;
    for (board_rows) |row| {
        var row_called: bool = true;
        for (row) |cell| {
            if (!context.boards[boardIndex].called.contains(cell)) {
                row_called = false;
                total += cell;
            }
        }
        found_bingo = found_bingo or row_called;
    }
    if (found_bingo) return bingo{ .found = true, .score = total };

    // check cols
    total = 0;
    found_bingo = false;
    for (board_cols) |col| {
        var col_called: bool = true;
        for (col) |cell| {
            if (!context.boards[boardIndex].called.contains(cell)) {
                col_called = false;
                total += cell;
            }
        }
        found_bingo = found_bingo or col_called;
    }
    if (found_bingo) return bingo{ .found = true, .score = total };

    return bingo{ .found = false, .score = total };
}

fn part1() ![]const u8 {
    const ctx = parse();
    var res: usize = 0;

    for (ctx.called) |num| {
        for (ctx.boards, 0..) |_, i| {
            ctx.boards[i].called.put(num, {}) catch unreachable;
            const b = bingo_score(ctx, i);
            if (b.found) {
                res = b.score * num;
                return try std.fmt.allocPrint(alloc, "part_1={}", .{res});
            }
        }
    }

    return try std.fmt.allocPrint(alloc, "part_1={}", .{res});
}

fn part2() ![]const u8 {
    const ctx = parse();
    for (ctx.boards, 0..) |_, i| {
        for (ctx.called) |num| {
            ctx.boards[i].called.put(num, {}) catch unreachable;
        }
    }
    var last_round: usize = ctx.called.len - 1;
    var last_board: usize = 0;
    var found: bool = false;
    while (last_round > 0 and !found) {
        for (ctx.boards, 0..) |_, i| {
            const b = bingo_score(ctx, i);
            if (!b.found) {
                last_board = i;
                found = true;
                last_round += 1;
                break;
            }
            _ = ctx.boards[i].called.remove(ctx.called[last_round]);
        }
        last_round -= 1;
    }

    var total: u32 = 0;
    for (ctx.boards[last_board].board_rows) |row| {
        for (row) |cell| {
            if (!ctx.boards[last_board].called.contains(cell)) {
                total += cell;
            }
        }
    }
    return try std.fmt.allocPrint(alloc, "part_2={}", .{(total - ctx.called[last_round + 1]) * ctx.called[last_round + 1]});
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
