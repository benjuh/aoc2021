# Advent of Code 2021 [ZIG]

This is my solution to the [Advent of Code 2021](https://adventofcode.com/2021) using [Zig](https://ziglang.org/).

## Running

To run the solution, you need to have [Zig](https://ziglang.org/) installed.

```bash
# Running all solutions
zig build run

# Running a specific solution where 1 is the day
zig build run -- 1

# Can also do this. This will run days 1 and 2
zig build run -- 1 2

# Running a range of days. This example runs days 1, 2, 3, and 4
zig build run -- 1-4

# Running all days except for some. This example runs all days EXCEPT 1, 2, and 3
zig build run -- except 1 2 3
```
