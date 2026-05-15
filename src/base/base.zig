const std = @import("std");
const Writer = std.Io.Writer;

const options = @import("options");
pub const game = options.game;
pub const tree = options.tree;
pub const board_size = options.board_size;

pub const Player = enum { first, second };

pub const Value = f32;

pub const Score = union(enum) {
    value: Value,

    pub fn win() Score {
        return .{ .value = std.math.inf(Value) };
    }

    pub fn loss() Score {
        return .{ .value = -std.math.inf(Value) };
    }

    pub fn draw() Score {
        return .{ .value = std.math.nan(Value) };
    }

    pub fn isWin(score: Score) bool {
        return std.math.isPositiveInf(score.value);
    }

    pub fn isLoss(score: Score) bool {
        return std.math.isNegativeInf(score.value);
    }

    pub fn isDraw(score: Score) bool {
        return std.math.isNan(score.value);
    }

    pub fn isDecisive(score: Score) bool {
        return std.math.isInf(score.value) or score.isDraw();
    }

    pub fn lt(self: Score, other: Score) bool {
        const self_value = if (self.isDraw()) 0 else self.value;
        const other_value = if (other.isDraw()) 0 else other.value;
        return self_value < other_value;
    }

    pub fn neg(self: Score) Score {
        return Score{ .value = -self.value };
    }

    pub fn format(self: Score, w: *Writer) Writer.Error!void {
        if (self.isWin()) {
            try w.print("win", .{});
        } else if (self.isLoss()) {
            try w.print("loss", .{});
        } else if (self.isDraw()) {
            try w.print("draw", .{});
        } else {
            try w.print("{d}", .{self.value});
        }
    }
};

pub fn MoveScore(comptime Move: type) type {
    return struct {
        move: Move,
        score: Score,

        pub fn format(self: @This(), w: *Writer) Writer.Error!void {
            try w.print("{f} {f}", .{ self.move, self.score });
        }
    };
}
