const std = @import("std");
const Io = std.Io;

const lab1_relleno_poligonos = @import("lab1_relleno_poligonos");
const rl = @import("raylib");
const Point = struct {
    x: f32,
    y: f32,
};
const polygon1 = [_]Point{
    .{ .x = 413, .y = 177 },
    .{ .x = 448, .y = 159 },
    .{ .x = 502, .y = 88 },
    .{ .x = 553, .y = 53 },
    .{ .x = 535, .y = 36 },
    .{ .x = 676, .y = 37 },
    .{ .x = 660, .y = 52 },
    .{ .x = 750, .y = 145 },
    .{ .x = 761, .y = 179 },
    .{ .x = 672, .y = 192 },
    .{ .x = 659, .y = 214 },
    .{ .x = 615, .y = 214 },
    .{ .x = 632, .y = 230 },
    .{ .x = 580, .y = 230 },
    .{ .x = 597, .y = 215 },
    .{ .x = 552, .y = 214 },
    .{ .x = 517, .y = 144 },
    .{ .x = 466, .y = 180 },
};
const polygon2 = [_]Point{
    .{ .x = 682, .y = 175 },
    .{ .x = 708, .y = 120 },
    .{ .x = 735, .y = 148 },
    .{ .x = 739, .y = 170 },
};

fn findIntersections(allocator: std.mem.Allocator, polygon: []const Point, y: f32) ![]f32 {
    var intersections: std.ArrayList(f32) = .empty;

    var i: usize = 0;
    while (i < polygon.len) : (i += 1) {
        const p1 = polygon[i];
        const p2 = polygon[(i + 1) % polygon.len];

        const y_min = @min(p1.y, p2.y);
        const y_max = @max(p1.y, p2.y);

        if (y >= y_min and y < y_max) {
            const x = p1.x + (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y);
            try intersections.append(allocator, x);
        }
    }

    const result = try intersections.toOwnedSlice(allocator);
    std.mem.sort(f32, result, {}, std.sort.asc(f32));
    return result;
}

pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    var gpa_state = std.heap.DebugAllocator(.{}){};
    const gpa = gpa_state.allocator();
    defer _ = gpa_state.deinit();
    rl.InitWindow(800, 600, "Prueba Raylib");
    defer rl.CloseWindow();

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.BLACK);

        var y: f32 = 0;
        while (y < 600) : (y += 1) {
            const intersections1 = findIntersections(gpa, &polygon1, y) catch continue;
            defer gpa.free(intersections1);
            const intersections2 = findIntersections(gpa, &polygon2, y) catch continue;
            defer gpa.free(intersections2);

            var all_intersections: std.ArrayList(f32) = .empty;
            defer all_intersections.deinit(gpa);
            for (intersections1) |x| try all_intersections.append(gpa, x);
            for (intersections2) |x| try all_intersections.append(gpa, x);

            std.mem.sort(f32, all_intersections.items, {}, std.sort.asc(f32));

            var idx: usize = 0;
            while (idx + 1 < all_intersections.items.len) : (idx += 2) {
                const x_start = all_intersections.items[idx];
                const x_end = all_intersections.items[idx + 1];
                rl.DrawLine(
                    @intFromFloat(x_start),
                    @intFromFloat(y),
                    @intFromFloat(x_end),
                    @intFromFloat(y),
                    rl.GREEN,
                );
            }
        }

        var v: usize = 0;
        while (v < polygon1.len) : (v += 1) {
            const p1 = polygon1[v];
            const p2 = polygon1[(v + 1) % polygon1.len];
            rl.DrawLine(@intFromFloat(p1.x), @intFromFloat(p1.y), @intFromFloat(p2.x), @intFromFloat(p2.y), rl.WHITE);
        }

        var w: usize = 0;
        while (w < polygon2.len) : (w += 1) {
            const p1 = polygon2[w];
            const p2 = polygon2[(w + 1) % polygon2.len];
            rl.DrawLine(@intFromFloat(p1.x), @intFromFloat(p1.y), @intFromFloat(p2.x), @intFromFloat(p2.y), rl.WHITE);
        }
    }

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try lab1_relleno_poligonos.printAnotherMessage(stdout_writer);

    try stdout_writer.flush(); // Don't forget to flush!
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!

    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    while (!smith.eos()) switch (smith.value(enum { add_data, dup_data })) {
        .add_data => {
            const slice = try list.addManyAsSlice(gpa, smith.value(u4));
            smith.bytes(slice);
        },
        .dup_data => {
            if (list.items.len == 0) continue;
            if (list.items.len > std.math.maxInt(u32)) return error.SkipZigTest;
            const len = smith.valueRangeAtMost(u32, 1, @min(32, list.items.len));
            const off = smith.valueRangeAtMost(u32, 0, @intCast(list.items.len - len));
            try list.appendSlice(gpa, list.items[off..][0..len]);
            try std.testing.expectEqualSlices(
                u8,
                list.items[off..][0..len],
                list.items[list.items.len - len ..],
            );
        },
    };
}
