const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 12;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    lines: [][]const u8,
    graph: std.AutoHashMap(i64, *std.ArrayList(i64)),

    pub fn count_paths(self: *Context, cave: i64, seen: i64, cache: *std.AutoHashMap(i64, i64), allowDoubleVisit: i64) i64 {
        if (cave == END_CAVE_ID) {
            return 1;
        }
        var new_seen = seen;
        var new_dbl = allowDoubleVisit;
        if (cave >= MIN_SMALL_CAVE_ID) {
            if (@rem(seen, cave) == 0) {
                if (allowDoubleVisit == -1) {
                    return 0;
                }
                new_dbl = -1;
            } else {
                new_seen *= cave;
            }
        }
        var total: i64 = 0;
        for (self.graph.get(cave).?.items) |neighbor| {
            const cacheKey: i64 = (neighbor + 1) * new_seen * new_dbl;
            if (!cache.contains(cacheKey)) {
                const count = self.count_paths(neighbor, new_seen, cache, new_dbl);
                cache.put(cacheKey, count) catch unreachable;
            }
            total += cache.get(cacheKey).?;
        }

        return total;
    }
};

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    ctx.lines = common.get_lines(DAY, alloc, IS_TEST);
    var bigIndex: i64 = 1;
    var smallIndex: i64 = 21;
    var graph = std.AutoHashMap(i64, *std.ArrayList(i64)).init(alloc);
    var id_lookup = std.StringHashMap(i64).init(alloc);
    for (ctx.lines) |line| {
        var parts = std.mem.tokenizeScalar(u8, line, '-');
        const left = parts.next().?;
        const right = parts.next().?;
        const cave_names = [2][]const u8{ left, right };
        for (cave_names) |u| {
            if (!id_lookup.contains(u)) {
                const cave = get_cave_id(u, bigIndex, smallIndex);
                smallIndex = cave.small_prime_index;
                bigIndex = cave.big_prime_index;
                id_lookup.put(u, cave.id) catch unreachable;
                const list = alloc.create(std.ArrayList(i64)) catch unreachable;
                list.* = std.ArrayList(i64).init(alloc);
                graph.put(cave.id, list) catch unreachable;
            }
        }
        const fromId = id_lookup.get(left).?;
        const toId = id_lookup.get(right).?;

        if (toId != START_CAVE_ID and fromId != END_CAVE_ID) {
            graph.get(fromId).?.append(toId) catch unreachable;
        }

        if (toId != END_CAVE_ID and fromId != START_CAVE_ID) {
            graph.get(toId).?.append(fromId) catch unreachable;
        }
    }
    ctx.graph = graph;
    return ctx;
}

fn part1() ![]const u8 {
    const ctx = parse();
    const allowDoubleVisit: i64 = -1;
    const cave = START_CAVE_ID;
    const seen = cave;
    var cache = std.AutoHashMap(i64, i64).init(alloc);
    const res = ctx.count_paths(cave, seen, &cache, allowDoubleVisit);
    return try std.fmt.allocPrint(alloc, "part_1={}", .{res});
}

fn part2() ![]const u8 {
    const ctx = parse();
    const allowDoubleVisit: i64 = 1;
    const cave = START_CAVE_ID;
    const seen = cave;
    var cache = std.AutoHashMap(i64, i64).init(alloc);
    const res = ctx.count_paths(cave, seen, &cache, allowDoubleVisit);
    return try std.fmt.allocPrint(alloc, "part_2={}", .{res});
}
const START_CAVE_ID: i64 = 1;
const END_CAVE_ID: i64 = 2;
const MIN_SMALL_CAVE_ID: i64 = 79; // The prime at index 21 is 79
const Cave = struct {
    id: i64,
    big_prime_index: i64,
    small_prime_index: i64,
};
pub fn get_cave_id(name: []const u8, bigPrimeIndex: i64, smallPrimeIndex: i64) Cave {
    const primes = [100]i64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521, 523, 541 };
    var cave_id: i64 = 0;
    var smallIndex: i64 = smallPrimeIndex;
    var bigIndex: i64 = bigPrimeIndex;
    if (std.mem.eql(u8, name, "start")) {
        cave_id = START_CAVE_ID;
    } else if (std.mem.eql(u8, name, "end")) {
        cave_id = END_CAVE_ID;
    } else if (name[0] > 90) {
        const casted: usize = @intCast(smallPrimeIndex);
        cave_id = primes[casted];
        smallIndex += 1;
    } else {
        const casted: usize = @intCast(bigPrimeIndex);
        cave_id = primes[casted];
        bigIndex += 1;
    }
    return Cave{
        .id = cave_id,
        .big_prime_index = bigIndex,
        .small_prime_index = smallIndex,
    };
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
