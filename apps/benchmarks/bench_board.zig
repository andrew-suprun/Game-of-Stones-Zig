const std = @import("std");

const Value = @import("base").Value;
const Board = @import("board").Board;
const Place = @import("board").Place;
const PlaceValue = @import("board").PlaceValue;

pub fn benchBoardClone() void {
    var board = Board{};
    for (0..5_000_000) |_| {
        const clone = board.clone();
        std.mem.doNotOptimizeAway(clone);
        board = clone.clone();
        std.mem.doNotOptimizeAway(board);
    }
}

pub fn benchRollout() void {
    var board = Board{};
    const place1 = Place.init("j10") catch unreachable;
    board.placeStone(place1, .first);
    const place2 = Place.init("i9") catch unreachable;
    board.placeStone(place2, .second);
    const place3 = Place.init("i10") catch unreachable;
    board.placeStone(place3, .first);
    var buf: [20]PlaceValue = undefined;
    var heap: std.ArrayList(PlaceValue) = .initBuffer(&buf);
    for (0..1_000) |_| {
        var clone = board.clone();
        for (0..50) |_| {
            heap.clearRetainingCapacity();
            clone.topPlaces(.first, &heap);
            clone.placeStone(heap.items[0].place, .first);
            heap.clearRetainingCapacity();
            clone.topPlaces(.first, &heap);
            clone.placeStone(heap.items[0].place, .second);
        }
        std.mem.doNotOptimizeAway(clone);
    }
}

pub fn benchTopPlaces() void {
    var board = Board{};
    var buf: [20]PlaceValue = undefined;
    var places: std.ArrayList(PlaceValue) = .initBuffer(&buf);
    for (0..1_000_000) |_| {
        places.clearRetainingCapacity();
        board.topPlaces(.first, &places);
        std.mem.doNotOptimizeAway(places);
    }
}

pub fn benchBoardMaxValue() void {
    var board = Board{};
    for (0..1_000_000_000) |_| {
        std.mem.doNotOptimizeAway(board.maxValue(.first));
    }
}
