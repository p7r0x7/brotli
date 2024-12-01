const Build = @import("std").Build;
const builtin = @import("std").builtin;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    b.enable_wine = target.result.os.tag == .windows and target.result.cpu.arch == .x86_64;
    b.enable_rosetta = target.result.os.tag == .macos and target.result.cpu.arch == .x86_64;

    const lib = b.addStaticLibrary(.{ .name = "brotli", .target = target, .optimize = optimize });

    lib.linkLibC();
    lib.addIncludePath(b.path("c/include"));
    lib.addCSourceFiles(.{ .files = &sources, .flags = &.{} });
    lib.installHeadersDirectory(b.path("c/include/brotli"), "brotli", .{});

    switch (target.result.os.tag) {
        .linux => lib.defineCMacro("OS_LINUX", "1"),
        .freebsd => lib.defineCMacro("OS_FREEBSD", "1"),
        .macos => lib.defineCMacro("OS_MACOSX", "1"),
        else => {},
    }

    b.installArtifact(lib);

    const brotli = executable(b, "brotli", null, target, optimize);
    brotli.linkLibrary(lib);
    brotli.addCSourceFile(.{ .file = b.path("c/tools/brotli.c"), .flags = &.{} });
    b.installArtifact(brotli);
}

const sources = [_][]const u8{
    "c/common/constants.c",
    "c/common/context.c",
    "c/common/dictionary.c",
    "c/common/platform.c",
    "c/common/shared_dictionary.c",
    "c/common/transform.c",
    "c/dec/bit_reader.c",
    "c/dec/decode.c",
    "c/dec/huffman.c",
    "c/dec/state.c",
    "c/enc/backward_references.c",
    "c/enc/backward_references_hq.c",
    "c/enc/bit_cost.c",
    "c/enc/block_splitter.c",
    "c/enc/brotli_bit_stream.c",
    "c/enc/cluster.c",
    "c/enc/command.c",
    "c/enc/compound_dictionary.c",
    "c/enc/compress_fragment.c",
    "c/enc/compress_fragment_two_pass.c",
    "c/enc/dictionary_hash.c",
    "c/enc/encode.c",
    "c/enc/encoder_dict.c",
    "c/enc/entropy_encode.c",
    "c/enc/fast_log.c",
    "c/enc/histogram.c",
    "c/enc/literal_cost.c",
    "c/enc/memory.c",
    "c/enc/metablock.c",
    "c/enc/static_dict.c",
    "c/enc/utf8_util.c",
    "c/tools/brotli.c",
};

fn executable(b: *Build, name: []const u8, root_path: ?[]const u8, target: Build.ResolvedTarget, optimize: builtin.OptimizeMode) *Build.Step.Compile {
    const exe = b.addExecutable(.{
        .error_tracing = optimize == .ReleaseSafe or optimize == .Debug,
        .strip = optimize == .ReleaseFast or optimize == .ReleaseSmall,
        .omit_frame_pointer = optimize != .Debug,
        .root_source_file = if (root_path) |v| b.path(v) else null,
        .unwind_tables = optimize == .Debug,
        .optimize = optimize,
        .target = target,
        .name = name,
        .pic = true,
    });
    exe.want_lto = !target.result.isDarwin(); // https://github.com/ziglang/zig/issues/8680
    exe.compress_debug_sections = .zstd;
    exe.link_function_sections = true;
    exe.link_gc_sections = true;
    return exe;
}
