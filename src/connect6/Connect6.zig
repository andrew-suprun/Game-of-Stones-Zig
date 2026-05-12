const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Connect6 = @This();
const base = @import("base");
const game = base.game;
const board_size = base.board_size;
const Player = base.Player;
const Value = base.Value;
const MoveScore = base.MoveScore(Move);
const b = @import("board");
const Board = b.Board;
const Place = b.Place;
const PlaceValue = b.PlaceValue;

board: Board = Board{},
turn: Player = .first,

pub const Move = struct {
    place1: Place,
    place2: Place,

    pub fn init(text: []const u8) error{ParseError}!Move {
        var it = std.mem.tokenizeScalar(u8, text, '-');
        const token1 = it.next() orelse return error.ParseError;
        const token2 = it.next() orelse token1;
        const place1 = try Place.init(token1);
        const place2 = try Place.init(token2);
        return .{ .place1 = place1, .place2 = place2 };
    }

    pub fn format(self: Move, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print("{f}", .{self.place1});
        if (self.place1.offset != self.place2.offset) {
            try w.print("-{f}", .{self.place2});
        }
    }
};

fn less(x: MoveScore, y: MoveScore) bool {
    return x.score < y.score;
}

pub fn clone(self: Connect6) Connect6 {
    return Connect6{ .board = self.board.clone(), .turn = self.turn };
}

pub fn playMove(self: *Connect6, move: Move) void {
    self.board.placeStone(move.place1, self.turn);
    if (move.place1.offset != move.place2.offset) {
        self.board.placeStone(move.place2, self.turn);
    }
    self.turn = opponent(self.turn);
}

pub fn topMoves(self: *Connect6, max_places: usize, moves: *std.ArrayList(MoveScore)) void {
    var place_buf: [Board.max_places]PlaceValue = undefined;
    var top_places: std.ArrayList(PlaceValue) = .initBuffer(place_buf[0..max_places]);
    self.board.topPlaces(self.turn, &top_places);

    std.debug.assert(top_places.items.len >= 2);

    const turn_idx: usize = @intCast(@intFromEnum(self.turn));
    for (0..top_places.items.len - 1) |i| {
        const place1 = top_places.items[i];
        const value1 = self.board.values[turn_idx][place1.place.offset];
        if (value1 >= Board.win) {
            moves.clearRetainingCapacity();
            moves.appendAssumeCapacity(MoveScore{ .move = Move{ .place1 = place1.place, .place2 = place1.place }, .score = .win });
            return;
        }

        self.board.placeStone(place1.place, self.turn);

        for (i + 1..top_places.items.len) |j| {
            const place2 = top_places.items[j];
            const value2 = self.board.values[turn_idx][place2.place.offset];

            if (value2 >= Board.win) {
                moves.clearRetainingCapacity();
                moves.appendAssumeCapacity(MoveScore{ .move = Move{ .place1 = place1.place, .place2 = place2.place }, .score = .win });
                return;
            } else if (value1 + value2 == 0) {
                moves.appendAssumeCapacity(MoveScore{ .move = Move{ .place1 = place1.place, .place2 = place2.place }, .score = .draw });
            } else {
                self.board.placeStone(place2.place, self.turn);
                const opp_value = self.board.maxValue(opponent(self.turn));
                const move_value = self.board.value + value1 + value2 - opp_value;
                moves.appendAssumeCapacity(MoveScore{ .move = Move{ .place1 = place1.place, .place2 = place2.place }, .score = .{ .value = move_value } });
            }
        }
    }
}

fn opponent(player: Player) Player {
    return if (player == .first) .second else .first;
}

pub fn format(self: Connect6, w: *std.Io.Writer) std.Io.Writer.Error!void {
    try w.print("turn {}\n{f}\n", .{ self.turn, self.board });
}

test "topMoves" {
    var c6 = Connect6{};
    c6.playMove(Connect6.Move{ .place1 = try .init("j10"), .place2 = try .init("j10") });
    c6.playMove(Connect6.Move{ .place1 = try .init("i9"), .place2 = try .init("i10") });

    var move_buf: [20]MoveScore = undefined;
    std.debug.print("{f}", .{c6});
    var top_moves: std.ArrayList(MoveScore) = .initBuffer(&move_buf);
    c6.topMoves(16, &top_moves);
    std.debug.print("{}\n", .{top_moves.items.len});
    for (top_moves.items) |item| {
        std.debug.print("{f}\n", .{item});
    }
}
