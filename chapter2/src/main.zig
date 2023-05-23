const std = @import("std");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var list = std.ArrayList(u8).init(arena.allocator());
    defer list.deinit();
    try list.append(10);
    try list.append(20);
    try list.append(30);

    var i: u8 = 0;

    while (i < list.capacity) : (i += 1) {
        std.log.info("{d}", .{list[i]});
    }

    for (list.items) |value|
        std.log.info("{d}", .{value});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

//Allocators
//The most basic allocator is std.heap.page_allocator
//Whenever this allocator makes an allocation it will
//ask for entire page of memory: an allocation
//of a single byte will likely reserve multiple
//kibibytes. As asking the os for memory requires a system
//call this is also extremely inefficient for speed
test "allocation" {
    const allocator = std.heap.page_allocator;
    //Allocates 100 bytes as a []u8
    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);
    try std.testing.expect(memory.len == 100);
    try std.testing.expect(@TypeOf(memory) == []u8);
}

//Fixed Buffer Allocator
//Allocator that allocates memory into a fixed buffer
//does not make any heap allocations. Useful when heap usage
//is not wanted. (Kernel, performance reasons)
//OutOfmemory if out of bytes
test "fixed buffer allocator" {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);
}

//ArenaAllocator
//Takes in a child allocator, allows to allocate many times and
//only free once.
//deinit() is called on the arena which frees all memory
test "arena allocator" {
    var arena = std.heap.ArenaAllocator.inti(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    _ = try allocator.alloc(u8, 1);
    _ = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);
}

//alloc and free are used for slices. For single items, consider
//using create and destroy
test "allocator create/destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
}

//General purpose allocator
//Safe allocator which can prevent double-free, use-after-free,
//can detect leaks.
//Designed for safety over performance, but may still be many
//times faster than page_allocator
test "GPA" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak)
            std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}

//ArrayList
//Serves as a buffer which can change in size.
//Similar to vector<T>, Vec<T>
//The deinit() method fress all of the ArrayList's memory.array
//The memory can be read from and written to via its slice field .items

test "arraylist" {
    const eql = std.mem.eql;
    const ArrayList = std.ArrayList;
    const test_allocator = std.testing.allocator;

    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.append("H");
    try list.appendSlice("ello World!");
    try std.testing.expect(eql(u8, list.items, "Hello World!"));
}
