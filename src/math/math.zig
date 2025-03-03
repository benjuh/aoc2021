const std = @import("std");

const Point = @Vector(2, i32);

pub fn Manhattan(a: Point, b: Point) i32 {
    return a[0] + a[1] + b[0] + b[1];
}
