const std = @import("std");

const base = @import("base");
const board_size = base.board_size;
const game = base.game;
const Value = base.Value;
const Player = base.Player;
const heapAdd = @import("heap").heapAdd;

pub const Board = @This();
const win_stones = if (game == .Gomoku) 5 else 6;
const Stone = enum(u8) { none, black, white = win_stones };
const n_places = board_size * board_size;
const value_table_size = win_stones * win_stones + 1;
const max_places = 32;
const win = 5000;
const inf = 8000;
const score_table = Board.scoreTable();
const value_table = Board.valueTable();

pub const Place = struct {
    offset: usize,

    pub fn init(text: []const u8) error{ParseError}!Place {
        if (text.len < 2 or text.len > 3) return error.ParseError;
        if (text[0] < 'a' or text[0] > 't') return error.ParseError;
        const x: usize = text[0] - 'a';
        const y1: usize = std.fmt.parseUnsigned(usize, text[1..], 10) catch return error.ParseError;
        return .{ .offset = (y1 - 1) * board_size + x };
    }

    pub fn format(self: Place, w: *std.Io.Writer) std.Io.Writer.Error!void {
        const x = self.offset % board_size;
        const y = self.offset / board_size + 1;
        try w.print("{c}{d}", .{ @as(u8, @intCast(x)) + 'a', y });
    }
};

pub const PlaceValue = struct {
    place: Place,
    value: Value,

    pub fn format(self: PlaceValue, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print("PlaceValue {f} {d}", .{ self.place, self.value });
    }
};

fn less(a: PlaceValue, b: PlaceValue) bool {
    return a.value < b.value;
}

value: Value = 0,
places: [n_places]Stone = [1]Stone{.none} ** (n_places),
values: [2][n_places]Value = values_blk: {
    const size: isize = @intCast(board_size);
    var values = [1][n_places]Value{[1]Value{0} ** (n_places)} ** 2;
    for (0..board_size) |yy| {
        const y: isize = @intCast(yy);
        const v = @min(win_stones, y + 1, size - y);
        for (0..board_size) |xx| {
            const x: isize = @intCast(xx);
            const stones: isize = win_stones;
            const h: isize = @min(stones, x + 1, size - x);
            const m: isize = @min(x + 1, y + 1, size - x, size - y);
            const t1 = @max(0, @min(stones, m, size - stones + 1 - y + x, size - stones + 1 - x + y));
            const t2 = @max(0, @min(stones, m, 2 * size - 1 - stones + 1 - y - x, x + y - stones + 2));
            const total: Value = v + h + t1 + t2;
            values[0][y * board_size + x] = total;
            values[1][y * board_size + x] = total;
        }
    }
    break :values_blk values;
},

pub fn topPlaces(self: *Board, comptime turn: Player, places: *std.ArrayList(PlaceValue)) void {
    for (0..n_places) |offset| {
        const value = self.values[@intFromEnum(turn)][offset];
        if (self.places[offset] == .none and value > 0) {
            const place_value = PlaceValue{ .place = Place{ .offset = offset }, .value = value };
            heapAdd(place_value, places, less);
        }
    }
}

pub fn placeStone(self: *Board, place: Place, turn: Player) void {
    const scores = Board.value_table[@intFromEnum(turn)];

    const x = place.offset % board_size;
    const y = place.offset / board_size;

    if (turn == .first) {
        self.value += self.values[@intFromEnum(Player.first)][place.offset];
    } else {
        self.value -= self.values[@intFromEnum(Player.second)][place.offset];
    }

    {
        const x_start = if (x + 1 > win_stones) x + 1 - win_stones else 0;
        const x_end = @min(x + win_stones, board_size) - win_stones + 1;
        const n = x_end - x_start;
        self.updateRow(y * board_size + x_start, 1, n, scores);
    }

    {
        const y_start = if (y + 1 > win_stones) y + 1 - win_stones else 0;
        const y_end = @min(y + win_stones, board_size) - win_stones + 1;
        const n = y_end - y_start;
        self.updateRow(y_start * board_size + x, board_size, n, scores);
    }

    const m = 1 + @min(x, y, board_size - 1 - x, board_size - 1 - y);

    const c1 = board_size + 1 + x;
    const c2 = win_stones + y;
    const c3 = board_size + 1 + y;
    const c4 = win_stones + x;
    if (c1 >= c2 and c3 >= c4) {
        const n = @min(win_stones, m, c1 - c2, c3 - c4);
        const mn = @min(x, y, win_stones - 1);
        const x_start = x - mn;
        const y_start = y - mn;
        self.updateRow(y_start * board_size + x_start, board_size + 1, n, scores);
    }

    const c5 = win_stones + x + y;
    const c6 = x + y + 2;
    if (2 * board_size >= c5 and c6 >= win_stones) {
        const n = @min(win_stones, m, 2 * board_size - c5, c6 - win_stones);
        const mn = @min(board_size - 1 - x, y, win_stones - 1);
        const x_start = x + mn;
        const y_start = y - mn;
        self.updateRow(y_start * board_size + x_start, board_size - 1, n, scores);
    }

    self.places[place.offset] = if (turn == .first) .black else .white;
}

fn updateRow(self: *Board, start: usize, delta: usize, n: usize, values: [2][value_table_size]Value) void {
    var offset = start;
    var stones: usize = 0;

    inline for (0..win_stones - 1) |i| {
        stones += self.getPlace(offset + i * delta);
    }

    for (0..n) |_| {
        stones += self.getPlace(offset + delta * (win_stones - 1));
        inline for (0..2) |i| {
            const placeValue = values[i][stones];
            if (placeValue != 0) {
                inline for (0..win_stones) |j| {
                    self.values[i][offset + j * delta] += placeValue;
                }
            }
        }
        stones -= self.getPlace(offset);
        offset += delta;
    }
}

fn getPlace(self: Board, offset: usize) usize {
    return @intCast(@intFromEnum(self.places[offset]));
}

pub fn clone(self: Board) Board {
    var result = Board{ .value = self.value };
    @memcpy(&result.places, &self.places);
    @memcpy(&result.values, &self.values);
    return result;
}

pub fn maxValue(self: Board, player: Player) Value {
    const values: @Vector(n_places, Value) = self.values[@intFromEnum(player)];
    return @reduce(.Max, values);
}

fn boardValue(self: Board) Value {
    var value: Value = 0;
    for (0..board_size) |y| {
        var stones: usize = 0;
        for (0..win_stones - 1) |x| {
            stones += self.getPlace(y * board_size + x);
        }
        for (0..board_size - win_stones + 1) |x| {
            stones += self.getPlace(y * board_size + x + win_stones - 1);
            value += Board.calcValue(stones);
            stones -= self.getPlace(y * board_size + x);
        }
    }

    for (0..board_size) |x| {
        var stones: usize = 0;
        for (0..win_stones - 1) |y| {
            stones += self.getPlace(y * board_size + x);
        }
        for (0..board_size - win_stones + 1) |y| {
            stones += self.getPlace((y + win_stones - 1) * board_size + x);
            value += Board.calcValue(stones);
            stones -= self.getPlace(y * board_size + x);
        }
    }

    for (0..board_size - win_stones + 1) |y| {
        var stones: usize = 0;
        for (0..win_stones - 1) |x| {
            stones += self.getPlace((x + y) * board_size + x);
        }
        for (0..board_size - win_stones + 1 - y) |x| {
            stones += self.getPlace((x + y + win_stones - 1) * board_size + x + win_stones - 1);
            value += Board.calcValue(stones);
            stones -= self.getPlace((x + y) * board_size + x);
        }
    }

    for (1..board_size - win_stones + 1) |x| {
        var stones: usize = 0;
        for (0..win_stones - 1) |y| {
            stones += self.getPlace(y * board_size + x + y);
        }
        for (0..board_size - win_stones + 1 - x) |y| {
            stones += self.getPlace((y + win_stones - 1) * board_size + x + y + win_stones - 1);
            value += Board.calcValue(stones);
            stones -= self.getPlace(y * board_size + x + y);
        }
    }

    for (0..board_size - win_stones + 1) |y| {
        var stones: usize = 0;
        for (0..win_stones - 1) |x| {
            stones += self.getPlace((x + y) * board_size + board_size - 1 - x);
        }
        for (0..board_size - win_stones + 1 - y) |x| {
            stones += self.getPlace((x + y + win_stones - 1) * board_size + board_size - 1 - x - win_stones + 1);
            value += Board.calcValue(stones);
            stones -= self.getPlace((x + y) * board_size + board_size - 1 - x);
        }
    }

    for (1..board_size - win_stones + 1) |x| {
        var stones: usize = 0;
        for (0..win_stones - 1) |y| {
            stones += self.getPlace(y * board_size + board_size - 1 - x - y);
        }
        for (0..board_size - win_stones + 1 - x) |y| {
            stones += self.getPlace((y + win_stones - 1) * board_size + board_size - win_stones - x - y);
            value += Board.calcValue(stones);
            stones -= self.getPlace(y * board_size + board_size - 1 - x - y);
        }
    }

    return value;
}

fn calcValue(stones: usize) Value {
    const black = stones % win_stones;
    const white = stones / win_stones;
    return if (white == 0) Board.score_table[black] else if (black == 0) -Board.score_table[white] else 0;
}
fn scoreTable() [win_stones + 1]Value {
    return score_blk: {
        var list: [win_stones + 1]Value = undefined;
        list[0] = 0;
        list[1] = 1;
        for (2..win_stones) |i| {
            list[i] = list[i - 1] * 5;
        }
        list[win_stones] = inf;
        break :score_blk list;
    };
}

fn valueTable() [2][2][value_table_size]Value {
    const result_size = value_table_size;
    const scores = scoreTable();

    const v2 = blk: {
        var values: [win_stones][2]Value = undefined;
        values[0][0] = 1;
        values[0][1] = -1;
        for (0..win_stones - 1) |i| {
            values[i + 1][0] = scores[i + 2] - scores[i + 1];
            values[i + 1][1] = -scores[i + 1];
        }
        break :blk values;
    };

    return blk: {
        var result: [2][2][result_size]Value = undefined;
        for (0..2) |i| {
            for (0..2) |j| {
                for (0..result_size) |k| {
                    result[i][j][k] = 0;
                }
            }
        }
        for (0..win_stones - 1) |i| {
            result[0][0][i * win_stones] = v2[i][1];
            result[0][1][i * win_stones] = -v2[i][0];
            result[0][0][i] = v2[i + 1][0] - v2[i][0];
            result[0][1][i] = v2[i][1] - v2[i + 1][1];
            result[1][0][i] = -v2[i][0];
            result[1][1][i] = v2[i][1];
            result[1][0][i * win_stones] = v2[i][1] - v2[i + 1][1];
            result[1][1][i * win_stones] = v2[i + 1][0] - v2[i][0];
        }
        break :blk result;
    };
}

pub fn format(self: Board, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    writer.print("\n   ", .{}) catch {};

    for (0..board_size) |i| {
        const c: u8 = @intCast(i);
        writer.print(" {c}", .{c + 'a'}) catch {};
    }
    writer.print("\n", .{}) catch {};

    for (0..board_size) |y| {
        writer.print("{:2} ", .{y + 1}) catch {};
        for (0..board_size) |x| {
            const stone = self.places[y * board_size + x];
            switch (stone) {
                .black => if (x == 0) writer.print(" X", .{}) catch {} else writer.print("─X", .{}) catch {},
                .white => if (x == 0) writer.print(" O", .{}) catch {} else writer.print("─O", .{}) catch {},
                .none => {
                    switch (y) {
                        0 => {
                            switch (x) {
                                0 => writer.print(" ┌", .{}) catch {},
                                board_size - 1 => writer.print("─┐", .{}) catch {},
                                else => writer.print("─┬", .{}) catch {},
                            }
                        },
                        board_size - 1 => {
                            switch (x) {
                                0 => writer.print(" └", .{}) catch {},
                                board_size - 1 => writer.print("─┘", .{}) catch {},
                                else => writer.print("─┴", .{}) catch {},
                            }
                        },
                        else => {
                            switch (x) {
                                0 => writer.print(" ├", .{}) catch {},
                                board_size - 1 => writer.print("─┤", .{}) catch {},
                                else => writer.print("─┼", .{}) catch {},
                            }
                        },
                    }
                },
            }
        }
        writer.print(" {:2}\n", .{y + 1}) catch {};
    }
    writer.print("   ", .{}) catch {};
    for (0..board_size) |i| {
        const c: u8 = @intCast(i);
        writer.print(" {c}", .{c + 'a'}) catch {};
    }
    writer.print("\n", .{}) catch {};

    try self.printScoresForPlayer(.first, writer);
    try self.printScoresForPlayer(.second, writer);
}

fn printScoresForPlayer(self: Board, player: Player, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    const idx = @intFromEnum(player);
    writer.print("\n   │", .{}) catch {};
    for (0..board_size) |i| {
        const c: u8 = @intCast(i);
        writer.print("   {c} ", .{c + 'a'}) catch {};
    }
    writer.print("│\n───┼" ++ "─────" ** board_size ++ "┼───\n", .{}) catch {};
    for (0..board_size) |y| {
        writer.print("{d:2} │", .{y + 1}) catch {};
        for (0..board_size) |x| {
            const stone = self.places[y * board_size + x];
            switch (stone) {
                .none => {
                    const value: usize = @intCast(self.values[idx][y * board_size + x]);
                    writer.print("{d:4} ", .{value}) catch {};
                },
                .black => writer.print("   X ", .{}) catch {},
                .white => writer.print("   O ", .{}) catch {},
            }
        }
        writer.print("| {d:2}\n", .{y + 1}) catch {};
    }
    writer.print("───┼" ++ "─────" ** board_size ++ "┼───", .{}) catch {};
    if (idx == 1) {
        writer.print("\n   │", .{}) catch {};
        for (0..board_size) |i| {
            const c: u8 = @intCast(i);
            writer.print("   {c} ", .{c + 'a'}) catch {};
        }
        writer.print("│\n", .{}) catch {};
    }
}

test "init Place" {
    const place: Place = try .init("j10");
    try std.testing.expectEqual(9 * board_size + 9, place.offset);
}

test "parsePlace" {
    const place = try Place.init("j10");
    const expected = 9 * (board_size + 1);
    try std.testing.expectEqual(expected, place.offset);
    var buf: [3]u8 = undefined;
    const str = try std.fmt.bufPrint(&buf, "{f}", .{place});
    try std.testing.expectEqualStrings("j10", str);
}

test "max value" {
    const board = Board{};
    const expected = if (game == .Gomoku) 20 else 24;
    try std.testing.expectEqual(expected, board.maxValue(.first));
}

test boardValue {
    var board = Board{};
    const value = board.values[0][9 * board_size + 9];
    board.placeStone(try .init("j10"), .first);
    try std.testing.expectEqual(value, board.boardValue());
}

test topPlaces {
    var board = Board{};
    board.placeStone(try Place.init("j10"), .first);
    board.placeStone(try Place.init("i10"), .second);
    board.placeStone(try Place.init("j9"), .second);
    var buf: [max_places]PlaceValue = undefined;
    var places: std.ArrayList(PlaceValue) = .initBuffer(buf[0..20]);
    board.topPlaces(.first, &places);
    for (places.items) |place| {
        try std.testing.expect(place.value >= 30);
    }
    places.clearRetainingCapacity();
    board.topPlaces(.second, &places);
    for (places.items) |place| {
        try std.testing.expect(place.value >= 35);
    }
}

// test {
//     for (0..2) |i| {
//         for (0..2) |j| {
//             for (0..win_stones) |k| {
//                 for (0..win_stones) |l| {
//                     std.debug.print("{:5} ", .{value_table[i][j][k * win_stones + l]});
//                 }
//                 std.debug.print("\n", .{});
//             }
//             std.debug.print("\n", .{});
//         }
//         std.debug.print("\n", .{});
//     }
// }
