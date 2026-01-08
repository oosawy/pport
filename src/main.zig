const std = @import("std");

pub fn main() !void {
    const stdout = std.fs.File.stdout();
    const stderr = std.fs.File.stderr();

    var args = std.process.args();
    _ = args.skip(); // skip program name

    const command = args.next() orelse {
        try stderr.writeAll("Usage: pport <command>\n");
        std.process.exit(1);
    };

    if (std.mem.eql(u8, command, "help")) {
        try stdout.writeAll("pport - A simple CLI tool\n\nCommands:\n  help    Show this help message\n  version Show version information\n");
    } else if (std.mem.eql(u8, command, "version")) {
        try stdout.writeAll("pport version 0.1.0\n");
    } else {
        try stderr.writeAll("Unknown command: ");
        try stderr.writeAll(command);
        try stderr.writeAll("\n");
        std.process.exit(1);
    }
}
