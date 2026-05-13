const std = @import("std");
const Io = std.Io;
const print = std.debug.print;

const heap = @import("heap_bench.zig");
const board = @import("board_bench.zig");

pub const Benchmark = struct {
    io: std.Io,
    acc: i96 = 0,
    started: i96 = 0,

    pub fn init(io: std.Io) Benchmark {
        return Benchmark{ .io = io };
    }

    pub inline fn start(self: *Benchmark) void {
        self.started = Io.Clock.awake.now(self.io).nanoseconds;
    }

    pub inline fn stop(self: *Benchmark) void {
        self.acc += Io.Clock.awake.now(self.io).nanoseconds - self.started;
    }

    pub inline fn keep(_: *Benchmark, value: anytype) void {
        std.mem.doNotOptimizeAway(value);
    }

    pub inline fn toSeconds(self: Benchmark) i64 {
        return @intCast(@divTrunc(self.acc, std.time.s_per_ms));
    }

    pub inline fn toMilliseconds(self: Benchmark) i64 {
        return @intCast(@divTrunc(self.acc, std.time.ns_per_ms));
    }

    pub inline fn toMicroseconds(self: Benchmark) i64 {
        return @intCast(@divTrunc(self.acc, std.time.ns_per_us));
    }
};

pub fn main(init: std.process.Init) void {
    const io = init.io;
    print("--- heap ---\n", .{});
    heap.benchHeapAdd(io);
    print("\n--- Board ---\n", .{});
    board.benchClone(io);
    board.benchUpdateRow(io);
    board.benchPlaceStone(io);
    board.benchRollout(io);
    board.benchTopPlaces(io);
    board.benchMaxValue(io);
}
