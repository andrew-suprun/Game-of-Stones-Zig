const std = @import("std");

const Game = enum { Gomoku, Connect6 };
const Tree = enum { Mcts, Abs, Pvs };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "Game_of_Stones_Zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const game = b.option(Game, "game", "Name of the game (default: Connect6)") orelse Game.Connect6;
    const tree = b.option(Tree, "tree", "Search tree (default: Mcts)") orelse Tree.Mcts;
    const board_size = b.option(usize, "board_size", "Board size (default: 19)") orelse 19;

    const options = b.addOptions();
    options.addOption(Game, "game", game);
    options.addOption(Tree, "tree", tree);
    options.addOption(usize, "board_size", board_size);

    exe.root_module.addOptions("config", options);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
