const std = @import("std");
const day01 = @import("day01.zig");
const day02 = @import("day02.zig");
const day03 = @import("day03.zig");
const day04 = @import("day04.zig");
const day05 = @import("day05.zig");
const day06 = @import("day06.zig");
const day07 = @import("day07.zig");
const day08 = @import("day08.zig");
const day09 = @import("day09.zig");
const day10 = @import("day10.zig");
const day11 = @import("day11.zig");
const day12 = @import("day12.zig");
const day13 = @import("day13.zig");
const day14 = @import("day14.zig");
const day15 = @import("day15.zig");
const day16 = @import("day16.zig");
const day17 = @import("day17.zig");
const day18 = @import("day18.zig");
const day19 = @import("day19.zig");
const day20 = @import("day20.zig");
const day21 = @import("day21.zig");
const day22 = @import("day22.zig");
const day23 = @import("day23.zig");
const day24 = @import("day24.zig");
const day25 = @import("day25.zig");
const print = std.debug.print;
pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const day = std.os.argv;
    if (day.len == 1) {
        try run_all_days();
    } else {
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);
        if (std.mem.eql(u8, args[1], "completed")) {
            print("No days completed yet!\n", .{});
            return;
        }
        if (std.mem.containsAtLeast(u8, args[1], 1, "-")) {
            const index = std.mem.indexOf(u8, args[1], "-").?;
            const left = args[1][0..index];
            const right = args[1][index + 1 ..];
            var left_num = std.fmt.parseInt(u8, left, 10) catch unreachable;
            const right_num = std.fmt.parseInt(u8, right, 10) catch unreachable;
            while (left_num <= right_num) : (left_num += 1) {
                try run_day(left_num);
            }
            return;
        }

        if (std.mem.eql(u8, args[1], "except")) {
            var do_not_run = std.AutoArrayHashMap(u8, void).init(allocator);
            for (args[2..]) |arg| {
                const val = try std.fmt.parseInt(u8, arg, 10);
                try do_not_run.put(val, {});
            }

            for (1..26) |i| {
                const j: u8 = @intCast(i);
                if (!do_not_run.contains(j)) {
                    print("Running day {d}\n", .{j});
                    try run_day(j);
                }
            }
            return;
        }

        for (args) |arg| {
            const day_num = std.fmt.parseInt(u8, arg, 10) catch continue;
            try run_day(day_num);
        }
    }
}

fn run_day(day_num: u8) !void {
    switch (day_num) {
        1 => try day01.main(),
        2 => try day02.main(),
        3 => try day03.main(),
        4 => try day04.main(),
        5 => try day05.main(),
        6 => try day06.main(),
        7 => try day07.main(),
        8 => try day08.main(),
        9 => try day09.main(),
        10 => try day10.main(),
        11 => try day11.main(),
        12 => try day12.main(),
        13 => try day13.main(),
        14 => try day14.main(),
        15 => try day15.main(),
        16 => try day16.main(),
        17 => try day17.main(),
        18 => try day18.main(),
        19 => try day19.main(),
        20 => try day20.main(),
        21 => try day21.main(),
        22 => try day22.main(),
        23 => try day23.main(),
        24 => try day24.main(),
        25 => try day25.main(),
        else => {
            print("Invalid day number: {}\n", .{day_num});
            return error.InvalidDay;
        },
    }
}

fn run_all_days() !void {
    try day01.main();
    try day02.main();
    try day03.main();
    try day04.main();
    try day05.main();
    try day06.main();
    try day07.main();
    try day08.main();
    try day09.main();
    try day10.main();
    try day11.main();
    try day12.main();
    try day13.main();
    try day14.main();
    try day15.main();
    try day16.main();
    try day17.main();
    try day18.main();
    try day19.main();
    try day20.main();
    try day21.main();
    try day22.main();
    try day23.main();
    try day24.main();
    try day25.main();
}
