const std = @import("std");
const Io = std.Io;
const print = std.debug.print;

const heap = @import("bench_heap.zig");
const board = @import("bench_board.zig");

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

pub fn main(init: std.process.Init) void {
    const io = init.io;
    print("--- heap ---\n", .{});
    print("heap: {:.3} sec/1B\n", .{benchmark(io, heap.benchHeapAdd)});
    print("--- Board ---\n", .{});
    print("clone:        {:.3} sec/10M\n", .{benchmark(io, board.benchBoardClone)});
    print("benchRollout: {:.3} sec/100K\n", .{benchmark(io, board.benchRollout)});
    print("maxValue:     {:.3} sec/1B\n", .{benchmark(io, board.benchBoardMaxValue)});
}
