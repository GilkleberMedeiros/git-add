const std = @import("std");
const clap = @import("clap");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime("\n\n-h, --help                  Displays this help and exit.\n--ignore-[listed command]    Ignore a listed command given its name.\n--o-[git add option]        Use git add options when command executed (optional).\n");

    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}
