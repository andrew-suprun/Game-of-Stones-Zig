const std = @import("std");
const ArrayList = std.ArrayList;

const base = @import("base");
const MoveScore = base.MoveScore;

const Idx = u32;

pub fn Mcts(comptime Game: type, comptime C: f64) type {
    return struct {
        const Self = @This();

        tree: ArrayList(Node) = .empty,
        game: *Game,
        allocator: std.mem.Allocator,
        io: std.Io,

        const MS = MoveScore(Game.Move);

        const Node = struct {
            ms: MoveScore(Game.Move),
            n_sims: u32,
            first_child: Idx,
            n_children: u32,

            pub fn init(ms: MS) Node {
                return Node{
                    .ms = ms,
                    .n_sims = 1,
                    .first_child = 0,
                    .n_children = 0,
                };
            }

            pub fn format(self: Node, w: *std.Io.Writer) std.Io.Writer.Error!void {
                try w.print("{f} sims: {d}", .{ self.ms, self.n_sims });
            }
        };

        pub fn init(game: *Game, allocator: std.mem.Allocator, io: std.Io) Self {
            return Self{ .game = game, .allocator = allocator, .io = io };
        }

        pub fn deinit(self: *Self) void {
            self.tree.deinit(self.allocator);
        }

        fn timestamp(self: Self) std.Io.Timestamp {
            return std.Io.Clock.awake.now(self.io);
        }

        pub fn search(self: *Self, max_time_ms: i64) ArrayList(Game.Move) {
            self.tree.clearRetainingCapacity();
            self.tree.append(self.allocator, .init(.{ .move = .{}, .score = .loss })) catch unreachable;
            const start = self.timestamp();
            const deadline = start.addDuration(.fromMilliseconds(max_time_ms)).nanoseconds;

            while (self.timestamp().nanoseconds < deadline) {
                self.expand();
            }

            // while perf_counter_ns() < deadline:
            //     self.expand(game)
            //     var n_undecisive = 0
            //     ref root = self.tree[0]
            //     if root.move.score().is_loss():
            //         return self._pv()
            //     for idx in range(root.first_child, root.first_child + root.n_children):
            //         ref child = self.tree[idx]

            //         if not child.move.score().is_decisive():
            //             n_undecisive += 1

            //     if n_undecisive <= 1:
            //         break

            return self.pv();
        }

        fn expand(self: *Self) void {
            var g = self.game.clone();
            var idx: Idx = 0;
            var parent_indices_buffer: [100]Idx = undefined;
            var parent_indices: ArrayList(Idx) = .initBuffer(&parent_indices_buffer);
            defer parent_indices.deinit(self.allocator);
            parent_indices.appendAssumeCapacity(self.allocator, 0);
            while (true) {
                const node = &self.tree.items[idx];
                if (node.n_children == 0) break;
                idx = self.select_child_idx(idx);
                parent_indices.appendAssumeCapacity(self.allocator, idx);
                const child = &self.tree.items[idx];
                g.playMove(child.ms.move);
            }
            // while True:
            //     ref node = self.tree[idx]
            //     if node.n_children == 0:
            //         break
            //     idx = self._select_child_idx(idx)
            //     parent_indices.append(idx)
            //     ref child = self.tree[idx]
            //     g.play_move(child.move)

            // var moves = g.moves()
            // ref leaf = self.tree[idx]
            // leaf.first_child = Idx(len(self.tree))
            // leaf.n_children = UInt32(len(moves))
            // for move in moves:
            //     self.tree.append(Self.Node(move))

            // for parent_idx in reversed(parent_indices):
            //     ref parent = self.tree[parent_idx]
            //     parent.n_sims += 1
            //     var best_score = Loss
            //     for idx in range(parent.first_child, parent.first_child + parent.n_children):
            //         ref child = self.tree[idx]
            //         best_score = best_score.max(child.move.score())

            //     parent.move.set_score(-best_score)
        }

        fn select_child_idx(self: Self, parent_idx: Idx) Idx {
            const parent = &self.tree.items[parent_idx];
            var selected_child_idx: Idx = std.math.maxInt(u32);
            var max_value = -std.math.inf(f64);
            for (parent.first_child..parent.first_child + parent.n_children) |child_idx| {
                const child = self.tree.items[child_idx];

                switch (child.ms.score) {
                    .win, .loss, .draw => continue,
                    .value => |v| {
                        const fv: f64 = @floatFromInt(v);
                        const ps: f64 = @floatFromInt(parent.n_sims);
                        const cs: f64 = @floatFromInt(child.n_sims);
                        const value: f64 = fv + C * ps / cs;
                        if (max_value < value) {
                            max_value = value;
                            selected_child_idx = @intCast(child_idx);
                        }
                    },
                }
            }
            std.debug.assert(selected_child_idx != std.math.maxInt(Idx));
            return selected_child_idx;
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

const DummyMove = struct {
    pub fn format(_: DummyMove, _: *std.Io.Writer) std.Io.Writer.Error!void {}
};

const DummyGame = struct {
    const Move = DummyMove;

    pub fn playMove(_: *DummyGame, _: Move) void {}

    pub fn clone(g: DummyGame) DummyGame {
        return g;
    }
};

test {
    var game = DummyGame{};
    var tree = Mcts(DummyGame, 1).init(&game, std.testing.allocator, std.testing.io);
    defer tree.deinit();
    const pv = tree.search(1);
    _ = pv;
}
