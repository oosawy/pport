const std = @import("std");

const program_name = "pport";
const version = "0.1.0";

pub fn main() !void {
    const stdout = std.fs.File.stdout();
    const stderr = std.fs.File.stderr();

    var args = std.process.args();
    _ = args.skip(); // skip program name

    const first_arg = args.next() orelse {
        try stderr.writeAll("Usage: pport [--help] [--version] <command> [args...]\n");
        std.process.exit(1);
    };

    if (std.mem.eql(u8, first_arg, "--help") or std.mem.eql(u8, first_arg, "-h")) {
        try stdout.print("{s} - A command wrapper\n", .{program_name});
        try stdout.writeAll(
            \\
            \\Usage: pport [options] <command> [args...]
            \\
            \\Options:
            \\  -h, --help     Show this help message
            \\  -V, --version  Show version information
            \\
        );
        return;
    }

    if (std.mem.eql(u8, first_arg, "--version") or std.mem.eql(u8, first_arg, "-V")) {
        try stdout.print("{s} version {s}\n", .{ program_name, version });
        return;
    }

    // Collect remaining args for exec
    var argv_buf: [256:null]?[*:0]const u8 = .{null} ** 256;
    var argc: usize = 0;

    argv_buf[argc] = first_arg.ptr;
    argc += 1;

    while (args.next()) |arg| {
        if (argc >= argv_buf.len - 1) break;
        argv_buf[argc] = arg.ptr;
        argc += 1;
    }

    const err = std.posix.execvpeZ(first_arg.ptr, &argv_buf, std.c.environ);
    try stderr.writeAll("exec failed: ");
    try stderr.writeAll(first_arg);
    try stderr.writeAll("\n");
    return err;
}
