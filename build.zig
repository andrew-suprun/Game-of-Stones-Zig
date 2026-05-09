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

    const game = b.addModule("game", .{
        .root_source_file = b.path("src/game/game.zig"),
        .target = target,
        .optimize = optimize,
    });

    const board = b.addModule("board", .{
        .root_source_file = b.path("src/board/Board.zig"),
        .target = target,
        .optimize = optimize,
    });
    board.addImport("game", game);

    const sim = b.addModule("board", .{
        .root_source_file = b.path("apps/sim/sim.zig"),
        .target = target,
        .optimize = optimize,
    });
    sim.addImport("board", board);

    // Executable: sim
    const exe_sim = b.addExecutable(.{
        .name = "sim",
        .root_module = sim,
    });
    exe_sim.root_module.addOptions("config", options);
    b.installArtifact(exe_sim);
    const run_sim_step = b.step("run-sim", "Run the simulation");
    const run_sim_cmd = b.addRunArtifact(exe_sim);
    run_sim_step.dependOn(&run_sim_cmd.step);
    run_sim_cmd.step.dependOn(b.getInstallStep());

    // Test: board
    const board_tests = b.addTest(.{
        .root_module = board,
    });
    board_tests.root_module.addOptions("config", options);
    const run_board_tests = b.addRunArtifact(board_tests);
    const test_step = b.step("test-board", "Run Board tests");
    test_step.dependOn(&run_board_tests.step);

    // Benchmarks:
    const benchmark = b.addModule("benchmark", .{
        .root_source_file = b.path("src/benchmark/benchmark.zig"),
        .target = target,
        .optimize = optimize,
    });
    benchmark.addImport("board", board);

    const benchmark_exe = b.addExecutable(.{
        .name = "benchmark",
        .root_module = benchmark,
    });
    benchmark_exe.root_module.addOptions("config", options);
    b.installArtifact(benchmark_exe);
    const bench_board_cmd_step = b.step("benchmarks", "Run benchmarks");
    const bench_board_cmd = b.addRunArtifact(benchmark_exe);
    bench_board_cmd_step.dependOn(&bench_board_cmd.step);
}
