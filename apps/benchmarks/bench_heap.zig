const std = @import("std");

const heapAdd = @import("heap").heapAdd;

fn testLess(i: usize, j: usize) bool {
    return i < j;
}

pub fn benchHeapAdd() void {
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
