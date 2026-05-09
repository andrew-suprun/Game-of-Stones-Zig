const std = @import("std");

const board_size = @import("config").board_size;
const game = @import("config").game;
const Value = @import("game").Value;
const Player = @import("game").Player;
const heapAdd = @import("heap").heapAdd;

pub const Board = @This();
const win_stones = if (game == .Gomoku) 5 else 6;
const Stone = enum(u8) { none, black, white = win_stones };
const n_places = board_size * board_size;

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

pub fn maxValue(self: Board, player: Player) Value {
    const values: @Vector(n_places, Value) = self.values[@intFromEnum(player)];
    return @reduce(.Max, values);
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
