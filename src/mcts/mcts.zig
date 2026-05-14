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

        pub fn search(self: *Self, max_moves: usize, max_places: usize, max_time_ms: i64) ArrayList(Game.Move) {
            self.root.deinit(self.allocator);
            self.root = .init(.{ .move = .{}, .score = .{ .value = 0 } });
            const start = self.timestamp();
            const deadline = start.addDuration(.fromMilliseconds(max_time_ms)).nanoseconds;

            var g = self.game.clone();
            while (self.timestamp().nanoseconds < deadline) {
                self.root.expand(&g, max_moves, max_places, self.allocator);
                if (self.root.ms.score.isDecisive()) {
                    return self.pv();
                }
                var n_undecisive: usize = 0;
                for (self.root.children) |child| {
                    if (!child.ms.score.isDecisive()) {
                        n_undecisive += 1;
                    }
                }
                if (n_undecisive == 1) {
                    return self.pv();
                }
            }

            return self.pv();
        }

        fn pv(self: *Self) ArrayList(Game.Move) {
            var result: ArrayList(Game.Move) = .empty;
            _ = self;
            _ = &result;

            // var pv = List[Self.G.Move]()
            // var idx: Idx = 0
            // while True:
            //     if self.tree[idx].n_children == 0:
            //         return pv^
            //     idx = self._best_child_idx(idx)
            //     pv.append(self.tree[idx].move)

            return result;
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
                var child = self.select_child();
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
            var best_score: Score = .loss;
            for (self.children) |child| {
                if (best_score.lt(child.ms.score)) {
                    best_score = child.ms.score;
                }
            }
            self.ms.score = best_score.neg();
            self.n_sims += 1;
        }

        fn select_child(self: Self) *Self {
            _ = &C;
            // const parent = &self.tree.items[parent_idx];
            // var selected_child_idx: Idx = std.math.maxInt(u32);
            // var max_value = -std.math.inf(f64);
            // for (parent.first_child..parent.first_child + parent.n_children) |child_idx| {
            //     const child = self.tree.items[child_idx];

            //     switch (child.ms.score) {
            //         .win, .loss, .draw => continue,
            //         .value => |v| {
            //             const fv: f64 = @floatFromInt(v);
            //             const ps: f64 = @floatFromInt(parent.n_sims);
            //             const cs: f64 = @floatFromInt(child.n_sims);
            //             const value: f64 = fv + C * ps / cs;
            //             if (max_value < value) {
            //                 max_value = value;
            //                 selected_child_idx = @intCast(child_idx);
            //             }
            //         },
            //     }
            // }
            // std.debug.assert(selected_child_idx != std.math.maxInt(Idx));
            return &self.children[0];
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
    const pv = tree.search(26, 20, 1);
    _ = pv;
}
