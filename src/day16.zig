const std = @import("std");
const print = std.debug.print;
const common = @import("common.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

const DAY = 16;
const IS_TEST = false;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();
var alloc: std.mem.Allocator = undefined;

const Context = struct {
    hexadecimal: []const u8,
    binary: []const u8,
};

const Packet = struct {
    version: u8 = 0,
    id: u8 = 0,
    value: usize = 0,
};

pub fn toBinary(char: u8) []const u8 {
    return switch (char) {
        '0' => "0000",
        '1' => "0001",
        '2' => "0010",
        '3' => "0011",
        '4' => "0100",
        '5' => "0101",
        '6' => "0110",
        '7' => "0111",
        '8' => "1000",
        '9' => "1001",
        'A' => "1010",
        'B' => "1011",
        'C' => "1100",
        'D' => "1101",
        'E' => "1110",
        'F' => "1111",
        else => {
            @panic("invalid character");
        },
    };
}

fn parse() *Context {
    var ctx = alloc.create(Context) catch unreachable;
    const lines = common.get_lines(DAY, alloc, IS_TEST);
    ctx.hexadecimal = lines[0];
    var binary_string = std.ArrayList(u8).init(alloc);
    for (lines[0]) |c| {
        binary_string.appendSlice(toBinary(c)) catch unreachable;
    }
    ctx.binary = binary_string.toOwnedSlice() catch unreachable;
    binary_string.deinit();
    return ctx;
}

const PacketInfo = struct {
    version_sum: usize = 0,
    literal_value: usize = 0,
    bits_read: usize = 0,
};

fn handlePacket(packet: []const u8, version_total: *usize) PacketInfo {
    const version = std.fmt.parseInt(usize, packet[0..3], 2) catch {
        @panic("invalid version");
    };

    const type_id = std.fmt.parseInt(usize, packet[3..6], 2) catch {
        @panic("invalid type_id");
    };

    var read: usize = 6;
    switch (type_id) {
        4 => {
            var bits = std.ArrayList(u8).init(alloc);
            var i: usize = 6;
            while (i < packet.len) {
                const five_bits = packet[i .. i + 5];
                read += 5;
                bits.appendSlice(five_bits[1..]) catch unreachable;
                i += 5;

                if (five_bits[0] == '0') {
                    break;
                }
            }

            const bit_string = bits.toOwnedSlice() catch unreachable;
            const literal_value = std.fmt.parseInt(usize, bit_string, 2) catch {
                @panic("error parsing literal value");
            };
            version_total.* += version;
            return PacketInfo{
                .version_sum = version,
                .literal_value = literal_value,
                .bits_read = read,
            };
        },
        else => {
            const op_id = std.fmt.parseInt(usize, packet[6..7], 2) catch {
                @panic("invalid op_id");
            };
            read += 1;
            var bits_to_read: usize = 0;
            switch (op_id) {
                0 => bits_to_read = 15,
                1 => bits_to_read = 11,
                else => @panic("invalid op_id"),
            }
            const raw_length = packet[7 .. 7 + bits_to_read];
            read += bits_to_read;
            var length = std.fmt.parseInt(usize, raw_length, 2) catch {
                @panic("error parsing op length");
            };
            var literal_values = std.ArrayList(usize).init(alloc);
            switch (op_id) {
                0 => {
                    while (length > 0) {
                        const packet_info = handlePacket(packet[read..], version_total);
                        read += packet_info.bits_read;
                        length -= packet_info.bits_read;
                        literal_values.append(packet_info.literal_value) catch unreachable;
                    }
                },
                1 => {
                    while (length > 0) {
                        const packet_info = handlePacket(packet[read..], version_total);
                        read += packet_info.bits_read;
                        length -= 1;
                        literal_values.append(packet_info.literal_value) catch unreachable;
                    }
                },
                else => {
                    @panic("invalid op_id");
                },
            }
            version_total.* += version;
            const values = literal_values.toOwnedSlice() catch unreachable;
            switch (type_id) {
                0 => {
                    return PacketInfo{
                        .version_sum = version_total.*,
                        .literal_value = sumSlice(values),
                        .bits_read = read,
                    };
                },
                1 => {
                    return PacketInfo{
                        .version_sum = version_total.*,
                        .literal_value = multiplySlice(values),
                        .bits_read = read,
                    };
                },
                2 => {
                    return PacketInfo{
                        .version_sum = version_total.*,
                        .literal_value = minInt(values),
                        .bits_read = read,
                    };
                },
                3 => {
                    return PacketInfo{
                        .version_sum = version_total.*,
                        .literal_value = maxInt(values),
                        .bits_read = read,
                    };
                },
                5 => {
                    var res: usize = 0;
                    if (values[0] > values[1]) res = 1;
                    return PacketInfo{
                        .version_sum = version_total.*,
                        .literal_value = res,
                        .bits_read = read,
                    };
                },
                6 => {
                    var res: usize = 0;
                    if (values[0] < values[1]) res = 1;
                    return PacketInfo{
                        .version_sum = version_total.*,
                        .literal_value = res,
                        .bits_read = read,
                    };
                },
                7 => {
                    var res: usize = 0;
                    if (values[0] == values[1]) res = 1;
                    return PacketInfo{
                        .version_sum = version_total.*,
                        .literal_value = res,
                        .bits_read = read,
                    };
                },
                else => {
                    @panic("invalid type_id");
                },
            }
        },
    }
}

fn sumSlice(slice: []usize) usize {
    var sum: usize = 0;
    for (slice) |v| {
        sum += v;
    }
    return sum;
}

fn multiplySlice(slice: []usize) usize {
    var product: usize = 1;
    for (slice) |v| {
        product *= v;
    }
    return product;
}

fn minInt(slice: []usize) usize {
    var min: usize = std.math.maxInt(usize);
    for (slice) |v| {
        min = @min(min, v);
    }
    return min;
}

fn maxInt(slice: []usize) usize {
    var max: usize = 0;
    for (slice) |v| {
        max = @max(max, v);
    }
    return max;
}

fn part1() ![]const u8 {
    const ctx = parse();
    var version_total: usize = 0;
    _ = handlePacket(ctx.binary, &version_total);
    return try std.fmt.allocPrint(alloc, "part_1={}", .{version_total});
}

fn part2() ![]const u8 {
    const ctx = parse();
    var version_total: usize = 0;
    const packet_info = handlePacket(ctx.binary, &version_total);

    return try std.fmt.allocPrint(alloc, "part_2={}", .{packet_info.literal_value});
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
