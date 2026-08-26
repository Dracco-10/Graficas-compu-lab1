const std = @import("std");
const Io = std.Io;

const lab1_relleno_poligonos = @import("lab1_relleno_poligonos");
const rl = @import("raylib");
const Point = struct {
    x: f32,
    y: f32,
};

const poligono1 = [_]Point{
    .{ .x = 165, .y = 380 },
    .{ .x = 185, .y = 360 },
    .{ .x = 188, .y = 330 },
    .{ .x = 207, .y = 345 },
    .{ .x = 233, .y = 330 },
    .{ .x = 230, .y = 360 },
    .{ .x = 250, .y = 380 },
    .{ .x = 220, .y = 385 },
    .{ .x = 205, .y = 410 },
    .{ .x = 193, .y = 383 },
};
const poligono2 = [_]Point{
    .{ .x = 321, .y = 335 },
    .{ .x = 288, .y = 286 },
    .{ .x = 339, .y = 251 },
    .{ .x = 374, .y = 302 },
};
const poligono3 = [_]Point{
    .{ .x = 377, .y = 249 },
    .{ .x = 411, .y = 197 },
    .{ .x = 436, .y = 249 },
};
const poligono4 = [_]Point{
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
const agujero4 = [_]Point{
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

fn drawFilledPolygon(allocator: std.mem.Allocator, polygon: []const Point, color: rl.Color) !void {
    var y: f32 = 0;
    while (y < 600) : (y += 1) {
        const intersections = try findIntersections(allocator, polygon, y);
        defer allocator.free(intersections);

        var idx: usize = 0;
        while (idx + 1 < intersections.len) : (idx += 2) {
            const x_start = intersections[idx];
            const x_end = intersections[idx + 1];
            rl.DrawLine(
                @intFromFloat(x_start),
                @intFromFloat(y),
                @intFromFloat(x_end),
                @intFromFloat(y),
                color,
            );
        }
    }
}

fn drawFilledPolygonWithHole(allocator: std.mem.Allocator, polygon: []const Point, hole: []const Point, color: rl.Color) !void {
    var y: f32 = 0;
    while (y < 600) : (y += 1) {
        const intersections1 = try findIntersections(allocator, polygon, y);
        defer allocator.free(intersections1);
        const intersections2 = try findIntersections(allocator, hole, y);
        defer allocator.free(intersections2);

        var all_intersections: std.ArrayList(f32) = .empty;
        defer all_intersections.deinit(allocator);
        for (intersections1) |x| try all_intersections.append(allocator, x);
        for (intersections2) |x| try all_intersections.append(allocator, x);

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
                color,
            );
        }
    }
}

fn drawOutline(polygon: []const Point) void {
    var v: usize = 0;
    while (v < polygon.len) : (v += 1) {
        const p1 = polygon[v];
        const p2 = polygon[(v + 1) % polygon.len];
        rl.DrawLine(
            @intFromFloat(p1.x),
            @intFromFloat(p1.y),
            @intFromFloat(p2.x),
            @intFromFloat(p2.y),
            rl.WHITE,
        );
    }
}

pub fn main(init: std.process.Init) !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    var gpa_state = std.heap.DebugAllocator(.{}){};
    const gpa = gpa_state.allocator();
    defer _ = gpa_state.deinit();
    rl.InitWindow(800, 600, "Prueba Raylib");
    defer rl.CloseWindow();

    const target = rl.LoadRenderTexture(800, 600);
    defer rl.UnloadRenderTexture(target);

    rl.BeginTextureMode(target);
    rl.ClearBackground(rl.BLACK);

    try drawFilledPolygon(gpa, &poligono1, rl.YELLOW);
    try drawFilledPolygon(gpa, &poligono2, rl.BLUE);
    try drawFilledPolygon(gpa, &poligono3, rl.RED);
    try drawFilledPolygonWithHole(gpa, &poligono4, &agujero4, rl.GREEN);

    drawOutline(&poligono1);
    drawOutline(&poligono2);
    drawOutline(&poligono3);
    drawOutline(&poligono4);
    drawOutline(&agujero4);

    rl.EndTextureMode();

    var image = rl.LoadImageFromTexture(target.texture);
    defer rl.UnloadImage(image);
    rl.ImageFlipVertical(&image);
    _ = rl.ExportImage(image, "out.bmp");

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.BLACK);
        rl.DrawTextureRec(
            target.texture,
            .{ .x = 0, .y = 0, .width = 800, .height = -600 },
            .{ .x = 0, .y = 0 },
            rl.WHITE,
        );
    }

    const arena: std.mem.Allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    const io = init.io;
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try lab1_relleno_poligonos.printAnotherMessage(stdout_writer);

    try stdout_writer.flush();
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa);
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;

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
