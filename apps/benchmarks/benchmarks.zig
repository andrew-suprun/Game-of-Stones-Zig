const std = @import("std");
const Io = std.Io;

pub fn benchmark(io: Io, comptime func: fn () void) f64 {
    var minDur: i96 = std.math.maxInt(i96);
    for (0..5) |_| {
        const start = Io.Clock.awake.now(io).nanoseconds;
        func();
        const dur = Io.Clock.awake.now(io).nanoseconds - start;
        if (minDur > dur) {
            minDur = dur;
        }
    }
    return @as(f64, @floatFromInt(minDur)) / std.time.ns_per_s;
}

const Board = @import("board").Board;

fn benchmarkMaxValue() void {
    const board = Board{};
    for (0..1_000_000) |_| {
        const firstMax = board.maxValue(.first);
        const secondMax = board.maxValue(.second);
        std.mem.doNotOptimizeAway(firstMax);
        std.mem.doNotOptimizeAway(secondMax);
    }
}

pub fn main(init: std.process.Init) void {
    const time = benchmark(init.io, benchmarkMaxValue);
    std.debug.print("maxValue: {} sec/1M\n", .{time});
}
