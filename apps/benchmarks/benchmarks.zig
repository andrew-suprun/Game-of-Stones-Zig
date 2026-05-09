const std = @import("std");
const Io = std.Io;
const print = std.debug.print;

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

const board_size = @import("config").options.board_size;
const Board = @import("board").Board;

fn boardMaxValue() void {
    var board = Board{};
    for (0..1_000_000_000) |_| {
        std.mem.doNotOptimizeAway(board.maxValue(.first));
    }
}

pub fn main(init: std.process.Init) void {
    const io = init.io;
    print("maxValue: {} sec/1B\n", .{benchmark(io, boardMaxValue)});
}
