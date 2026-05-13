const std = @import("std");

const game = @import("base").game;
const board_size = @import("base").board_size;
const Value = @import("base").Value;
const Board = @import("board").Board;
const Place = @import("board").Place;
const PlaceValue = @import("board").PlaceValue;

pub fn benchBoardClone() void {
    var board = Board{};
    for (0..500_000) |_| {
        const clone = board.clone();
        std.mem.doNotOptimizeAway(clone);
        board = clone.clone();
        std.mem.doNotOptimizeAway(board);
    }
}

pub fn benchUpdateRow() void {
    var board = Board{};
    const table_size = if (game == .Gomoku) 26 else 37;
    var values: [2][table_size]Value = undefined;
    for (0..2) |i| {
        for (0..table_size) |j| {
            values[i][j] = 1;
        }
    }
    for (0..10_000) |_| {
        var clone = board.clone();
        for (0..10) |y| {
            for (0..10) |x| {
                const offset = y * board_size + x;
                clone.updateRow(offset, board_size + 1, 6, values);
            }
        }
        std.mem.doNotOptimizeAway(clone);
    }
}

pub fn benchPlaceStone() void {
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
    for (0..10_000) |_| {
        clone = board.clone();
        for (0..50) |i| {
            clone.placeStone(places.items[2 * i], .first);
            clone.placeStone(places.items[2 * i + 1], .second);
        }
        std.mem.doNotOptimizeAway(clone);
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
        std.mem.doNotOptimizeAway(clone);
        // std.debug.print("{f}\n", .{clone});
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
