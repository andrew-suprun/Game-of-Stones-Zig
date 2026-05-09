const Writer = @import("std").Io.Writer;

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
