const std = @import("std");

const Value = @import("base").Value;
const board_size = @import("base").board_size;
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

pub fn benchPlaceStone() void {
    var board = Board{};
    var s: Value = 0;
    const place = Place.init("j10") catch unreachable;
    for (0..1_000_000_000) |_| {
        board.placeStone(place, .first);
        s += board.value;
        std.mem.doNotOptimizeAway(s);
    }
}

pub fn benchBoardMaxValue() void {
    var board = Board{};
    for (0..1_000_000_000) |_| {
        std.mem.doNotOptimizeAway(board.maxValue(.first));
    }
}
