const std = @import("std");
const Io = std.Io;
const print = std.debug.print;

test {
    const Mcts = @import("mcts").Mcts;
    const Connect6 = @import("connect6").Connect6;

    var game = Connect6{};
    game.playMove(try .initFromStr("j10"));
    game.playMove(try .initFromStr("i9-i10"));
    var tree = Mcts(Connect6, 0.35).init(&game, std.testing.allocator, std.testing.io);
    defer tree.deinit();

    for (1..21) |i| {
        print("==== expand {d}\n", .{i});
        var g = game.clone();
        tree.root.expand(&g, 26, 20, std.testing.allocator);
        var pv_buf: [100]Connect6.Move = undefined;
        const pv = tree.calcPv(&pv_buf);

        print("pv:", .{});
        for (pv) |move| print(" {f}", .{move});
        print("\n{f}\n", .{tree});
    }
}
