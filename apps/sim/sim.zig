const std = @import("std");
const Io = std.Io;

const base = @import("base");
const Board = @import("board");

pub fn main(_: std.process.Init) !void {
    std.debug.print("game:       {}\n", .{base.game});
    std.debug.print("tree:       {}\n", .{base.tree});
    std.debug.print("board_size: {}\n", .{base.board_size});

    const board = Board{};
    _ = board;
}

test "foo" {
    std.debug.print("TEST\n", .{});
    // return error.Bar;
}
