const std = @import("std");
const linux = std.os.linux;

const program_name = "pport";
const version = "0.1.0";

// Capability constants
const CAP_NET_BIND_SERVICE = 10;
const CAP_SETPCAP = 8;

// capget/capset constants
const LINUX_CAPABILITY_VERSION_3: u32 = 0x20080522;

// prctl constants
const PR_CAP_AMBIENT = 47;
const PR_CAP_AMBIENT_RAISE = 2;

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
        try stdout.writeAll(program_name ++ " - A command wrapper\n");
        try stdout.writeAll(
            \\
            \\Usage: pport [options] [--] <command> [args...]
            \\
            \\Options:
            \\  -h, --help     Show this help message
            \\  -V, --version  Show version information
            \\  --             End of options (optional)
            \\
        );
        return;
    }

    if (std.mem.eql(u8, first_arg, "--version") or std.mem.eql(u8, first_arg, "-V")) {
        try stdout.writeAll(program_name ++ " version " ++ version ++ "\n");
        return;
    }

    // Handle optional "--" separator
    const command = if (std.mem.eql(u8, first_arg, "--"))
        args.next() orelse {
            try stderr.writeAll("Usage: pport [--help] [--version] [--] <command> [args...]\n");
            std.process.exit(1);
        }
    else
        first_arg;

    // Collect remaining args for exec
    var argv_buf: [256:null]?[*:0]const u8 = .{null} ** 256;
    var argc: usize = 0;

    argv_buf[argc] = command.ptr;
    argc += 1;

    while (args.next()) |arg| {
        if (argc >= argv_buf.len - 1) break;
        argv_buf[argc] = arg.ptr;
        argc += 1;
    }

    // 1. Get current capabilities
    var header = linux.cap_user_header_t{
        .version = LINUX_CAPABILITY_VERSION_3,
        .pid = 0,
    };
    var data: [2]linux.cap_user_data_t = undefined;

    var res = linux.capget(&header, @ptrCast(&data));
    var errno = linux.E.init(res);
    if (errno != .SUCCESS) {
        std.debug.print("Error: capget failed. (errno={s})\n", .{@tagName(errno)});
        std.process.exit(1);
    }

    // 2. Add CAP_NET_BIND_SERVICE and CAP_SETPCAP to Inheritable set
    const cap_bit: u32 = @as(u32, 1) << @intCast(CAP_NET_BIND_SERVICE % 32);
    const setpcap_bit: u32 = @as(u32, 1) << @intCast(CAP_SETPCAP % 32);
    data[0].inheritable |= cap_bit;
    data[0].inheritable |= setpcap_bit;

    // 3. Apply the changes
    res = linux.capset(&header, @ptrCast(&data));
    errno = linux.E.init(res);
    if (errno != .SUCCESS) {
        std.debug.print("Error: capset failed. (errno={s})\n", .{@tagName(errno)});
        std.debug.print("Make sure the binary has cap_net_bind_service and cap_setpcap in its permitted set.\n", .{});
        std.process.exit(1);
    }

    // 4. Raise ambient capability for CAP_NET_BIND_SERVICE
    res = linux.prctl(PR_CAP_AMBIENT, PR_CAP_AMBIENT_RAISE, CAP_NET_BIND_SERVICE, 0, 0);
    errno = linux.E.init(res);
    if (errno != .SUCCESS) {
        std.debug.print("Error: Failed to raise ambient capability. (errno={s})\n", .{@tagName(errno)});
        std.debug.print("Make sure the binary has cap_net_bind_service and cap_setpcap permissions.\n", .{});
        std.process.exit(1);
    }

    // 5. Drop privileges to the original user
    const real_gid = linux.getgid();
    const real_uid = linux.getuid();

    // setgid must be called before setuid (can't change gid after dropping root)
    res = linux.setgid(real_gid);
    errno = linux.E.init(res);
    if (errno != .SUCCESS) {
        std.debug.print("Error: setgid failed. (errno={s})\n", .{@tagName(errno)});
        std.process.exit(1);
    }

    res = linux.setuid(real_uid);
    errno = linux.E.init(res);
    if (errno != .SUCCESS) {
        std.debug.print("Error: setuid failed. (errno={s})\n", .{@tagName(errno)});
        std.process.exit(1);
    }

    const err = std.posix.execvpeZ(command.ptr, &argv_buf, std.c.environ);
    try stderr.writeAll("exec failed: ");
    try stderr.writeAll(command);
    try stderr.writeAll("\n");
    return err;
}
