const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const base = @import("base");
const Score = base.Score;
const MoveScore = base.MoveScore;

pub fn Mcts(comptime Game: type, comptime C: f64) type {
    return struct {
        const Self = @This();
        const Node = MctsNode(Game, C);
        const MS = MoveScore(Game.Move);

        root: Node = .init(.{ .move = .{}, .score = .{ .value = 0 } }),
        game: *Game,
        allocator: Allocator,
        io: std.Io,

        pub fn init(game: *Game, allocator: Allocator, io: std.Io) Self {
            return Self{ .game = game, .allocator = allocator, .io = io };
        }

        pub fn deinit(self: *Self) void {
            self.root.deinit(self.allocator);
        }

        fn timestamp(self: Self) std.Io.Timestamp {
            return std.Io.Clock.awake.now(self.io);
        }

        pub fn search(self: *Self, max_moves: usize, max_places: usize, max_time_ms: i64, pv: []Game.Move) []Game.Move {
            self.root.deinit(self.allocator);
            self.root = .init(.{ .move = .{}, .score = .{ .value = 0 } });
            const start = self.timestamp();
            const deadline = start.addDuration(.fromMilliseconds(max_time_ms)).nanoseconds;

            var g = self.game.clone();
            while (self.timestamp().nanoseconds < deadline) {
                self.root.expand(&g, max_moves, max_places, self.allocator);
                if (self.root.ms.score.isDecisive()) {
                    return self.calcPv(pv);
                }
                var n_undecisive: usize = 0;
                for (self.root.children) |child| {
                    if (!child.ms.score.isDecisive()) {
                        n_undecisive += 1;
                    }
                }
                if (n_undecisive == 1) {
                    return self.calcPv(pv);
                }
            }

            return self.calcPv(pv);
        }

        fn calcPv(self: Self, buf: []Game.Move) []Game.Move {
            var idx: usize = 0;
            var node = self.root;
            while (idx < buf.len) {
                buf[idx] = node.ms.move;
                if (node.children.len == 0) break;
                node = node.bestChild();
                idx += 1;
            }

            return buf[0..idx];
        }

        pub fn format(self: Self, w: *std.Io.Writer) std.Io.Writer.Error!void {
            try self.formatTree(self.root, 0, w);
        }

        pub fn formatTree(self: Self, node: Node, depth: usize, w: *std.Io.Writer) std.Io.Writer.Error!void {
            for (0..depth) |_| {
                try w.print("|   ", .{});
            }
            try w.print("{f}\n", .{node});
            for (node.children) |child| {
                try self.formatTree(child, depth + 1, w);
            }
        }
    };
}

fn MctsNode(comptime Game: type, comptime C: f64) type {
    return struct {
        const Self = @This();
        const MS = MoveScore(Game.Move);

        ms: MS,
        n_sims: u32,
        children: []Self,

        pub fn init(ms: MS) Self {
            return Self{
                .ms = ms,
                .n_sims = 1,
                .children = &.{},
            };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            for (self.children) |*child| {
                child.deinit(allocator);
            }
            allocator.free(self.children);
        }

        fn expand(self: *Self, game: *Game, max_moves: usize, max_places: usize, allocator: Allocator) void {
            if (self.children.len > 0) {
                var child = self.selectChild();
                game.playMove(child.ms.move);
                child.expand(game, max_moves, max_places, allocator);
            } else {
                var move_list: [Game.max_moves]MS = undefined;
                const moves = game.topMoves(max_places, move_list[0..max_moves]);
                self.children = allocator.alloc(Self, moves.len) catch unreachable;
                for (self.children, moves) |*child, move| {
                    child.* = .init(move);
                }
            }
            var best_score: Score = .loss();
            for (self.children) |child| {
                if (best_score.lt(child.ms.score)) {
                    best_score = child.ms.score;
                }
            }
            self.ms.score = best_score.neg();
            self.n_sims += 1;
        }

        fn selectChild(self: Self) *Self {
            var selected_child: ?*Self = null;
            var max_value = -std.math.inf(f64);
            const node_sims: f64 = @floatFromInt(self.n_sims);
            for (self.children) |*child| {
                if (child.ms.score.isDecisive()) {
                    continue;
                } else {
                    const value: f64 = @floatCast(child.ms.score.value);
                    const child_sims: f64 = @floatFromInt(child.n_sims);
                    const child_value: f64 = value + C * node_sims / child_sims;
                    if (max_value < child_value) {
                        max_value = child_value;
                        selected_child = child;
                    }
                }
            }
            if (selected_child) |child| {
                return child;
            } else {
                std.debug.panic("Mcts: failed to select node child", .{});
            }
        }

        fn bestChild(self: Self) Self {
            var best_child = self.children[0];
            for (self.children[1..]) |child| {
                if (best_child.ms.score.lt(child.ms.score)) {
                    best_child = child;
                }
            }
            return best_child;
        }

        pub fn format(self: Self, w: *std.Io.Writer) std.Io.Writer.Error!void {
            try w.print("{f} sims: {d}", .{ self.ms, self.n_sims });
        }
    };
}

const DummyMove = struct {
    pub fn format(_: DummyMove, _: *std.Io.Writer) std.Io.Writer.Error!void {}
};

const DummyGame = struct {
    const Move = DummyMove;
    const max_moves = 64;

    pub fn topMoves(_: DummyGame, _: usize, ms: []MoveScore(DummyMove)) []MoveScore(DummyMove) {
        return ms;
    }

    pub fn playMove(_: *DummyGame, _: Move) void {}

    pub fn clone(g: DummyGame) DummyGame {
        return g;
    }
};

test {
    var game = DummyGame{};
    var tree = Mcts(DummyGame, 1).init(&game, std.testing.allocator, std.testing.io);
    defer tree.deinit();
    var pv_buf: [100]DummyGame.Move = undefined;
    _ = tree.search(26, 20, 1, &pv_buf);
}
