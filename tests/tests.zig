const std = @import("std");
const Io = std.Io;
const print = std.debug.print;

test {
    const Mcts = @import("mcts").Mcts;
    const Connect6 = @import("connect6").Connect6;

    var game = Connect6{};
    game.playMove(try .initFromStr("j10"));
    game.playMove(try .initFromStr("i9-i10"));
    std.debug.print("{f}\n", .{game});
    var tree = Mcts(Connect6, 0.35).init(&game, std.testing.allocator, std.testing.io);
    defer tree.deinit();

    var pv_buf: [100]Connect6.Move = undefined;
    const pv = tree.search(26, 20, 250, &pv_buf);

    std.debug.print("pv:", .{});
    for (pv) |move| std.debug.print(" {f}", .{move});
    std.debug.print("\ntree: {f}\n", .{tree});
}
