const std = @import("std");

const Benchmark = @import("root").Benchmark;
const heapAdd = @import("heap").heapAdd;

fn testLt(i: usize, j: usize) bool {
    return i < j;
}

pub fn benchHeapAdd(io: std.Io) void {
    var bm = Benchmark.init(io);
    var buf: [20]usize = undefined;
    var heap = std.ArrayList(usize).initBuffer(&buf);
    bm.start();
    for (0..10_000_000) |_| {
        heap.clearRetainingCapacity();
        for (0..100) |i| {
            heapAdd(i * 17 % 100, &heap, testLt);
        }
        bm.keep(heap);
    }
    bm.stop();
    std.debug.print("heap: {d} msec/1B\n", .{bm.toMilliseconds()});
}
