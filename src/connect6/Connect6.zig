pub const Connect6 = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;

const base = @import("base");
const game = base.game;
const board_size = base.board_size;
const Player = base.Player;
const Score = base.Score;
const Value = base.Value;
const MoveScore = base.MoveScore(Move);
const b = @import("board");
const Board = b.Board;
const Place = b.Place;
const PlaceValue = b.PlaceValue;
const heapAdd = @import("heap").heapAdd;

pub const max_moves = 32;

board: Board = Board{},
turn: Player = .first,

pub const Move = struct {
    place1: Place = .{},
    place2: Place = .{},

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

pub fn topMoves(self: Connect6, max_places: usize, moves: []MoveScore) []MoveScore {
    var place_buf: [Board.max_places]PlaceValue = undefined;
    const top_places = self.board.topPlaces(self.turn, place_buf[0..max_places]);

    std.debug.assert(top_places.len >= 2);

    var move_list = std.ArrayList(MoveScore).initBuffer(moves[0..max_places]);
    for (0..top_places.len - 1) |i| {
        const pv = top_places[i];
        const place1 = pv.place;
        const value1 = pv.value;
        if (value1 == std.math.inf(Value)) {
            moves[0] = .{ .move = .init(place1, place1), .score = .win() };
            return moves[0..1];
        }

        var board1 = self.board.clone();
        board1.placeStone(place1, self.turn);

        for (i + 1..top_places.len) |j| {
            const place2 = top_places[j].place;
            const value2 = board1.values[@intFromEnum(self.turn)][place2.offset];

            if (value2 == std.math.inf(Value)) {
                moves[0] = .{ .move = .init(place1, place2), .score = .win() };
                return moves[0..1];
            } else if (value1 + value2 == 0) {
                const ms = MoveScore{ .move = .init(place1, place2), .score = .draw() };
                heapAdd(ms, &move_list, lt);
            } else {
                var board2 = board1.clone();
                board2.placeStone(place2, self.turn);
                const opp_value = board2.maxValue(opponent(self.turn));
                if (std.math.isFinite(opp_value)) {
                    const move_value = self.board.value + value1 + value2 - opp_value;
                    const ms = MoveScore{ .move = .init(place1, place2), .score = .{ .value = move_value } };
                    heapAdd(ms, &move_list, lt);
                }
            }
        }
    }
    if (moves.len == 0) {
        moves[0] = .{ .move = .init(top_places[0].place, top_places[1].place), .score = .loss() };
        return moves[0..1];
    }
    return move_list.items;
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
    const top_moves = c6.topMoves(16, &move_buf);
    var best_move = top_moves[0];
    for (top_moves) |move| {
        if (best_move.score.lt(move.score)) {
            best_move = move;
        }
    }
    try std.testing.expect(best_move.score.value == 19);
}
