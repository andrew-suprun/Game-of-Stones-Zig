const std = @import("std");
const Io = std.Io;

const config = @import("config");
const Board = @import("board");

pub fn main(_: std.process.Init) !void {
    std.debug.print("game:       {}\n", .{config.game});
    std.debug.print("tree:       {}\n", .{config.tree});
    std.debug.print("board_size: {}\n", .{config.board_size});

    const board = Board{};
    _ = board;
}

test "foo" {
    std.debug.print("TEST\n", .{});
    // return error.Bar;
}
