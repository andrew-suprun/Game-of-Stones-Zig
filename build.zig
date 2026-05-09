const std = @import("std");

const Game = enum { Gomoku, Connect6 };
const Tree = enum { Mcts, Abs, Pvs };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const option_game = b.option(Game, "game", "Name of the game (default: Connect6)") orelse Game.Connect6;
    const option_tree = b.option(Tree, "tree", "Search tree (default: Mcts)") orelse Tree.Mcts;
    const option_board_size = b.option(usize, "board_size", "Board size (default: 19)") orelse 19;
    const options = b.addOptions();
    options.addOption(Game, "game", option_game);
    options.addOption(Tree, "tree", option_tree);
    options.addOption(usize, "board_size", option_board_size);

    const base = b.addModule("base", .{
        .root_source_file = b.path("src/base/base.zig"),
        .target = target,
        .optimize = optimize,
    });
    base.addOptions("options", options);

    const board = b.addModule("board", .{
        .root_source_file = b.path("src/board/Board.zig"),
        .target = target,
        .optimize = optimize,
    });
    board.addImport("base", base);

    const sim = b.addModule("board", .{
        .root_source_file = b.path("apps/sim/sim.zig"),
        .target = target,
        .optimize = optimize,
    });
    sim.addImport("base", base);
    sim.addImport("board", board);

    // Executable: sim
    const exe_sim = b.addExecutable(.{
        .name = "sim",
        .root_module = sim,
    });
    b.installArtifact(exe_sim);
    const run_sim_step = b.step("run-sim", "Run the simulation");
    const run_sim_cmd = b.addRunArtifact(exe_sim);
    run_sim_step.dependOn(&run_sim_cmd.step);
    run_sim_cmd.step.dependOn(b.getInstallStep());

    // Test: board
    const board_tests = b.addTest(.{
        .root_module = board,
    });
    const run_board_tests = b.addRunArtifact(board_tests);
    const test_step = b.step("test-board", "Run Board tests");
    test_step.dependOn(&run_board_tests.step);

    // Benchmarks:
    const benchmarks = b.addModule("benchmarks", .{
        .root_source_file = b.path("apps/benchmarks/benchmarks.zig"),
        .target = target,
        .optimize = .ReleaseFast,
        // .optimize = optimize,
    });
    benchmarks.addImport("base", base);
    benchmarks.addImport("board", board);

    const benchmarks_exe = b.addExecutable(.{
        .name = "benchmarks",
        .root_module = benchmarks,
    });
    b.installArtifact(benchmarks_exe);
    const bench_board_cmd_step = b.step("benchmarks", "Run benchmarks");
    const bench_board_cmd = b.addRunArtifact(benchmarks_exe);
    bench_board_cmd_step.dependOn(&bench_board_cmd.step);
}
