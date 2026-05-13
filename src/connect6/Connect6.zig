const Connect6 = @This();

const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

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
const heapAdd = @import("heap").heapAdd;

board: Board = Board{},
turn: Player = .first,

pub const Move = struct {
    place1: Place,
    place2: Place,

    fn init(place1: Place, place2: Place) Move {
        if (place1.lt(place2)) {
            return .{ .place1 = place1, .place2 = place2 };
        } else {
            return .{ .place1 = place2, .place2 = place1 };
        }
    }

    fn initFromStr(text: []const u8) error{ParseError}!Move {
        var it = std.mem.tokenizeScalar(u8, text, '-');
        const token1 = it.next() orelse return error.ParseError;
        const token2 = it.next() orelse token1;
        const place1 = try Place.init(token1);
        const place2 = try Place.init(token2);
        return .init(place1, place2);
    }

    pub fn format(self: Move, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print("{f}", .{self.place1});
        if (self.place1.offset != self.place2.offset) {
            try w.print("-{f}", .{self.place2});
        }
    }
};

fn lt(x: MoveScore, y: MoveScore) bool {
    return x.score.lt(y.score);
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

    for (0..top_places.items.len - 1) |i| {
        const pv = top_places.items[i];
        const place1 = pv.place;
        const value1 = pv.value;
        if (value1 >= Board.win) {
            moves.clearRetainingCapacity();
            moves.appendAssumeCapacity(MoveScore{ .move = .init(place1, place1), .score = .win });
            return;
        }

        var board1 = self.board.clone();
        board1.placeStone(place1, self.turn);

        for (i + 1..top_places.items.len) |j| {
            const place2 = top_places.items[j].place;
            const value2 = board1.values[@intFromEnum(self.turn)][place2.offset];

            if (value2 >= Board.win) {
                moves.clearRetainingCapacity();
                moves.appendAssumeCapacity(MoveScore{ .move = .init(place1, place2), .score = .win });
                return;
            } else if (value1 + value2 == 0) {
                moves.appendAssumeCapacity(MoveScore{ .move = .init(place1, place2), .score = .draw });
            } else {
                var board2 = board1.clone();
                board2.placeStone(place2, self.turn);
                const opp_value = board2.maxValue(opponent(self.turn));
                if (opp_value < Board.inf) {
                    const move_value = self.board.value + value1 + value2 - opp_value;
                    const ms = MoveScore{ .move = .init(place1, place2), .score = .{ .value = move_value } };
                    heapAdd(ms, moves, lt);
                }
            }
        }
    }
    if (moves.items.len == 0) {
        moves.appendAssumeCapacity(MoveScore{ .move = .init(top_places.items[0].place, top_places.items[1].place), .score = .loss });
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
    c6.playMove(try .initFromStr("j10"));
    c6.playMove(try .initFromStr("i9-i10"));

    var move_buf: [20]MoveScore = undefined;
    var top_moves: std.ArrayList(MoveScore) = .initBuffer(&move_buf);
    c6.topMoves(16, &top_moves);
    var best_move = top_moves.items[0];
    for (top_moves.items) |move| {
        if (best_move.score.lt(move.score)) {
            best_move = move;
        }
    }
    try std.testing.expect(best_move.score.value == 19);
}
