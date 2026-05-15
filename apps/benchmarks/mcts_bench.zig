const std = @import("std");

const Benchmark = @import("root").Benchmark;

pub fn benchMctsExpand(allocator: std.mem.Allocator, io: std.Io) void {
    var bm = Benchmark.init(io);
    const Mcts = @import("mcts").Mcts;
    const Connect6 = @import("connect6").Connect6;

    var game = Connect6{};
    game.playMove(Connect6.Move.initFromStr("j10") catch unreachable);
    game.playMove(Connect6.Move.initFromStr("i9-i10") catch unreachable);
    var tree = Mcts(Connect6, 0.35).init(&game, allocator, io);
    defer tree.deinit();
    bm.start();
    for (0..1_000) |_| {
        var g = game.clone();
        tree.root.expand(&g, 26, 20, allocator);
        bm.keep(tree.root);
    }
    bm.stop();
    std.debug.print("expand: {d} msec/1K\n", .{bm.toMilliseconds()});
}
