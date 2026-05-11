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

        pub fn format(self: MoveScore, w: *Writer) Writer.Error!void {
            w.print("{f} {f}", .{ self.move, self.score });
        }
    };
}
