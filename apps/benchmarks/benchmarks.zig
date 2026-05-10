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

fn testLess(i: usize, j: usize) bool {
    return i < j;
}

fn heapAdd() void {
    var buf: [20]usize = undefined;
    var heap = std.ArrayList(usize).initBuffer(&buf);
    for (0..1_000_000) |_| {
        heap.clearRetainingCapacity();
        for (0..100) |i| {
            heapAdd(i * 17 % 100, &heap, testLess);
        }
        std.mem.doNotOptimizeAway(heap);
    }
}

const board_size = @import("base").options.board_size;
const Board = @import("board").Board;

fn boardMaxValue() void {
    var board = Board{};
    for (0..1_000_000_000) |_| {
        std.mem.doNotOptimizeAway(board.maxValue(.first));
    }
}

fn boardClone() void {
    var board = Board{};
    for (0..10_000_000) |_| {
        std.mem.doNotOptimizeAway(board.clone());
    }
}

pub fn main(init: std.process.Init) void {
    const io = init.io;
    print("--- heap ---\n", .{});
    print("heap:     {:.3} sec/1B\n", .{benchmark(io, heapAdd)});
    print("--- Board ---\n", .{});
    print("maxValue: {:.3} sec/1B\n", .{benchmark(io, boardMaxValue)});
    print("clone:    {:.3} sec/10M\n", .{benchmark(io, boardClone)});
}
