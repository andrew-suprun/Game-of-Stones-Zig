const std = @import("std");

const Benchmark = @import("root").Benchmark;
const game = @import("base").game;
const board_size = @import("base").board_size;
const Value = @import("base").Value;
const Board = @import("board").Board;
const Place = @import("board").Place;
const PlaceValue = @import("board").PlaceValue;

pub fn benchClone(io: std.Io) void {
    var bm = Benchmark.init(io);
    var board = Board{};
    for (0..500_000) |_| {
        bm.start();
        const clone = board.clone();
        bm.keep(clone);
        board = clone.clone();
        bm.keep(board);
        bm.stop();
    }
    std.debug.print("clone:      {:5} msec/1M\n", .{bm.toMilliseconds()});
}

pub fn benchUpdateRow(io: std.Io) void {
    var bm = Benchmark.init(io);
    var board = Board{};
    bm.start();
    for (0..10_000) |_| {
        var clone = board.clone();
        for (0..10) |y| {
            for (0..10) |x| {
                clone.updateRow(y * board_size + x, board_size + 1, 6, .first);
            }
        }
        bm.keep(clone);
    }
    bm.stop();
    std.debug.print("updateRow:  {:5} msec/1M\n", .{bm.toMilliseconds()});
}

pub fn benchPlaceStone(io: std.Io) void {
    var bm = Benchmark.init(io);
    var board = Board{};
    const place1 = Place.init("j10") catch unreachable;
    board.placeStone(place1, .first);
    const place2 = Place.init("i9") catch unreachable;
    board.placeStone(place2, .second);
    const place3 = Place.init("i10") catch unreachable;
    board.placeStone(place3, .first);
    var buf: [20]PlaceValue = undefined;
    var heap: std.ArrayList(PlaceValue) = .initBuffer(&buf);
    var place_buf: [100]Place = undefined;
    var places: std.ArrayList(Place) = .initBuffer(&place_buf);
    var clone = board.clone();
    for (0..50) |_| {
        heap.clearRetainingCapacity();
        clone.topPlaces(.first, &heap);
        places.appendAssumeCapacity(heap.items[0].place);
        clone.placeStone(heap.items[0].place, .first);
        heap.clearRetainingCapacity();
        clone.topPlaces(.second, &heap);
        places.appendAssumeCapacity(heap.items[0].place);
        clone.placeStone(heap.items[0].place, .second);
    }
    bm.start();
    for (0..10_000) |_| {
        clone = board.clone();
        for (0..50) |i| {
            clone.placeStone(places.items[2 * i], .first);
            clone.placeStone(places.items[2 * i + 1], .second);
        }
        bm.keep(clone);
    }
    bm.stop();
    std.debug.print("placeStone: {:5} msec/1M\n", .{bm.toMilliseconds()});
}

pub fn benchRollout(io: std.Io) void {
    var bm = Benchmark.init(io);
    var board = Board{};
    const place1 = Place.init("j10") catch unreachable;
    board.placeStone(place1, .first);
    const place2 = Place.init("i9") catch unreachable;
    board.placeStone(place2, .second);
    const place3 = Place.init("i10") catch unreachable;
    board.placeStone(place3, .first);
    var buf: [20]PlaceValue = undefined;
    var heap: std.ArrayList(PlaceValue) = .initBuffer(&buf);
    bm.start();
    for (0..10_000) |_| {
        var clone = board.clone();
        for (0..50) |_| {
            heap.clearRetainingCapacity();
            clone.topPlaces(.first, &heap);
            clone.placeStone(heap.items[0].place, .first);
            heap.clearRetainingCapacity();
            clone.topPlaces(.second, &heap);
            clone.placeStone(heap.items[0].place, .second);
        }
        bm.keep(clone);
    }
    bm.stop();
    std.debug.print("rollout:    {:5} msec/1M\n", .{bm.toMilliseconds()});
}

pub fn benchTopPlaces(io: std.Io) void {
    var bm = Benchmark.init(io);
    var board = Board{};
    var buf: [20]PlaceValue = undefined;
    var places: std.ArrayList(PlaceValue) = .initBuffer(&buf);
    bm.start();
    for (0..1_000_000) |_| {
        places.clearRetainingCapacity();
        board.topPlaces(.first, &places);
        bm.keep(places);
    }
    bm.stop();
    std.debug.print("topPlaces:  {:5} msec/1M\n", .{bm.toMilliseconds()});
}

pub fn benchMaxValue(io: std.Io) void {
    var bm = Benchmark.init(io);
    var board = Board{};
    bm.start();
    for (0..1_000_000_000) |_| {
        bm.keep(board.maxValue(.first));
    }
    bm.stop();
    std.debug.print("maxValue:   {:5} msec/1B\n", .{bm.toMilliseconds()});
}
