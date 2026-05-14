const Writer = @import("std").Io.Writer;

const options = @import("options");
pub const game = options.game;
pub const tree = options.tree;
pub const board_size = options.board_size;

pub const Player = enum { first, second };

pub const Value = i16;

pub const Score = union(enum) {
    value: Value,
    win,
    loss,
    draw,

    pub fn isDecisive(self: Score) bool {
        return switch (self) {
            .win, .loss, .draw => true,
            .value => false,
        };
    }

    pub fn lt(self: Score, other: Score) bool {
        return switch (self) {
            .win => false,
            .loss => true,
            .draw => switch (other) {
                .win => true,
                .loss, .draw => false,
                .value => |vy| vy > 0,
            },
            .value => |vx| switch (other) {
                .win => true,
                .loss => false,
                .draw => vx < 0,
                .value => |vy| vx < vy,
            },
        };
    }

    pub fn neg(self: Score) Score {
        return switch (self) {
            .win => .loss,
            .loss => .win,
            .draw => .draw,
            .value => |v| -v,
        };
    }

    pub fn format(self: Score, w: *Writer) Writer.Error!void {
        try switch (self) {
            .value => |v| w.print("{d}", .{v}),
            .win => w.print("win", .{}),
            .loss => w.print("loss", .{}),
            .draw => w.print("draw", .{}),
        };
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
