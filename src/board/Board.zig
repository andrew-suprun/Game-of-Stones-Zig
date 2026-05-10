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

fn valueTable() [2][2][win_stones * win_stones + 1]Value {
    const result_size = win_stones * win_stones + 1;
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
