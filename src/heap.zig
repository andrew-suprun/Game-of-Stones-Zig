const std = @import("std");
const ArrayList = std.ArrayList;

pub fn heapAdd(item: anytype, heap: *ArrayList(@TypeOf(item)), comptime less: fn (@TypeOf(item), @TypeOf(item)) bool) void {
    if (heap.items.len == heap.capacity) {
        if (!less(heap.items[0], item)) return;

        heap.items[0] = item;
        siftDown(@TypeOf(item), heap, less);
        return;
    }
    heap.appendAssumeCapacity(item) catch unreachable;
    siftUp(@TypeOf(item), heap, less);
}

fn siftUp(comptime T: type, heap: *ArrayList(T), comptime less: fn (T, T) bool) void {
    var child_idx = heap.items.len - 1;
    const child = heap.items[child_idx];
    while (child_idx > 0 and less(child, heap.items[(child_idx - 1) / 2])) {
        const parent_idx = (child_idx - 1) / 2;
        heap.items[child_idx] = heap.items[parent_idx];
        child_idx = parent_idx;
    }
    heap.items[child_idx] = child;
}

fn siftDown(comptime T: type, heap: *ArrayList(T), comptime less: fn (T, T) bool) void {
    var idx: usize = 0;
    const elem = heap.items[idx];
    while (true) {
        var first = idx;
        const left_child_idx = idx * 2 + 1;
        if (left_child_idx < heap.items.len and less(heap.items[left_child_idx], elem)) {
            first = left_child_idx;
        }
        const right_child_idx = idx * 2 + 2;
        if (right_child_idx < heap.items.len and
            less(heap.items[right_child_idx], elem) and
            less(heap.items[right_child_idx], heap.items[left_child_idx]))
        {
            first = right_child_idx;
        }
        if (idx == first) break;

        heap.items[idx] = heap.items[first];
        idx = first;
    }
    heap.items[idx] = elem;
}

fn testLess(i: usize, j: usize) bool {
    return i < j;
}

test heapAdd {
    var buf: [20]usize = undefined;
    var heap = ArrayList(usize).initBuffer(&buf);

    for (0..100) |i| {
        const v: usize = i * 17 % 100;
        heapAdd(v, &heap, testLess);
    }

    const items = heap.items;
    for (1..20) |i| {
        const parent = items[(i - 1) / 2];
        const child = items[i];
        std.debug.print("t: i: {} p: {}, c: {}\n", .{ i, parent, child });
        try std.testing.expect(parent < child);
    }
}

// Benchmark
const benchmark = @import("benchmark.zig").benchmark;

fn heapBench() void {
    var buf: [20]usize = undefined;
    var heap = ArrayList(usize).initBuffer(&buf);
    for (0..1_000_000) |_| {
        heap.clearRetainingCapacity();
        for (0..100) |i| {
            heapAdd(i * 17 % 100, &heap, testLess);
        }
        std.mem.doNotOptimizeAway(heap);
    }
}

pub fn main(init: std.process.Init) !void {
    std.debug.print("heapAdd: {d:.5} sec\n", .{benchmark(init.io, heapBench)});
}
