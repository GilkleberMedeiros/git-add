const std = @import("std");
const clap = @import("clap");

const PROGRAM_VERSION = "0.0.1";

const ProgramParams = struct {
    paths: []const []const u8,
    help: bool = undefined,
    version: bool = undefined,
    ignore: ?[]const []const u8 = undefined,
    options: ?[]const []const u8 = undefined,

    pub fn init(
        paths: []const []const u8,
        help: ?bool,
        version: ?bool,
        ignore: ?[]const []const u8,
        options: ?[]const []const u8,
    ) ProgramParams {
        return ProgramParams{
            .paths = paths,
            .help = help orelse false,
            .version = version orelse false,
            .ignore = ignore orelse null,
            .options = options orelse null,
        };
    }
};

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime("\n\n" ++
        "-h, --help                  Displays this help and exit.\n" ++
        "-v, --version               Displays program version.\n" ++
        "-i, --ignore <str>...       Ignore a listed command given its name.\n" ++
        "-o, --options <str>...      Use git add options.\n" ++
        "<str>...                    Paths to be passed to actual git add command.\n");

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        // Report useful error and exit.
        try diag.reportToFile(.stderr(), err);
        return err;
    };
    defer res.deinit();

    const allocator = gpa.allocator();
    const programParams: *ProgramParams = try gpa.allocator().create(ProgramParams);
    defer allocator.destroy(programParams); // deallocate when exit this scope

    handleParams(res, programParams);

    std.debug.print("ProgramParams: {any} \n", .{programParams});
    std.debug.print("Paths: {any} \n", .{programParams.paths});
    std.debug.print("Options: {any} \n", .{programParams.options});
    std.debug.print("Ignore: {any} \n", .{programParams.ignore});
    std.debug.print("Help: {any} \n", .{programParams.help});
    std.debug.print("Version: {any} \n", .{programParams.version});

    // Prints if program works.
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}

// @Requires res = clap.Result(Help)
// Handle command params. Executing -h and -v and parsing to apropriate struct.
pub fn handleParams(res: anytype, paramsStruct: *ProgramParams) void {
    // Show help/version and exit right after
    if (res.args.help != 0) {
        showHelp();
        // show help
    }
    if (res.args.version != 0) {
        showVersion();
        // show version
    }

    if (res.positionals[0].len == 0) {
        @panic("Required param '<path>...' (git add <path>...) not found! exiting...");
    }

    // Use .positionals[0] to unwrap pos params from unnecessary tuple.
    paramsStruct.* = ProgramParams.init(res.positionals[0], false, false, null, null);

    if (res.args.ignore.len > 0) {
        paramsStruct.ignore = res.args.ignore;
        // set ignore
    }
    if (res.args.options.len > 0) {
        paramsStruct.options = res.args.options;
        // set git add options
    }
}

fn helpStr() []const u8 {
    return "USAGE: git-add [options] <paths>..." ++
        "\n\n" ++
        "-h, --help                  Displays this help and exit.\n" ++
        "-v, --version               Displays program version.\n" ++
        "-i, --ignore <str>...       Ignore a listed command given its name.\n" ++
        "-o, --options <str>...      Use git add options.\n" ++
        "<str>...                    Paths to be passed to actual git add command.\n";
}

fn versionStr() []const u8 {
    return "git-add version " ++ PROGRAM_VERSION;
}

// Show Command Help String and exit program
fn showHelp() void {
    std.log.info("\n" ++ helpStr(), .{});
    std.process.exit(0);
}

// Show Command Version String and exit program
fn showVersion() void {
    std.log.info("\n" ++ versionStr(), .{});
    std.process.exit(0);
}
