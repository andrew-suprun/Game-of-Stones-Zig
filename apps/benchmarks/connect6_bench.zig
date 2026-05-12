const std = @import("std");

fn benchConnect6TopMoves() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const C6 = Connect6(19, 60, 32);
    var c6 = C6.init(allocator);
    defer c6.deinit();
    c6.playMove(C6.Move{ .place1 = board.Place{ .x = 9, .y = 9 }, .place2 = board.Place{ .x = 9, .y = 9 } });
    c6.playMove(C6.Move{ .place1 = board.Place{ .x = 9, .y = 8 }, .place2 = board.Place{ .x = 9, .y = 10 } });
    for (0..1000) |_| {
        _ = c6.topMoves();
    }
}
