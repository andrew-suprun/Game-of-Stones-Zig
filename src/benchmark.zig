const std = @import("std");
const Io = std.Io;

pub fn benchmark(io: Io, comptime func: fn () void) f64 {
    var minDur: i96 = std.math.maxInt(i96);
    for (0..5) |_| {
        const start = Io.Clock.awake.now(io).nanoseconds;
        func();
        const dur = Io.Clock.awake.now(io).nanoseconds - start;
        if (minDur > dur) {
            minDur = dur;
        }
    }
    return @as(f64, @floatFromInt(minDur)) / std.time.ns_per_s;
}
