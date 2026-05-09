const std = @import("std");
const Io = std.Io;

const config = @import("config");
const Score = @import("game.zig").Score;

const bench = @import("benchmark.zig").benchmark;
fn b() void {}

pub fn main(init: std.process.Init) !void {
    std.debug.print("game:       {}\n", .{config.game});
    std.debug.print("tree:       {}\n", .{config.tree});
    std.debug.print("board_size: {}\n", .{config.board_size});
    std.debug.print("bm: {}\n", .{bench(init.io, b)});
    var score = Score{ .value = 13 };
    std.debug.print("size: {}\n", .{@sizeOf(Score)});
    std.debug.print("score: |{f:>5}|\n", .{score});
    score = .win;
    std.debug.print("score: |{f:>5}|\n", .{score});
    std.debug.print("int: |{d:>5}|\n", .{42});
}

test "foo" {
    std.debug.print("TEST\n", .{});
    // return error.Bar;
}
