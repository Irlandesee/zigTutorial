const std = @import("std");

test "switch tastement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            x = @divExact(x, 10);
        },
        else => {},
    }
    try std.testing.expect(x == 1);
}
//Runtime safety
//Zig provides a level of safety, where problems may
//be found during execution.
//Zig has many cases of detectable illegal behaviour, meaning that
//illegal behaviour will be caught, causing a panic with safety on.
test "out of bounds" {
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
} //unreachable is an assertion to the compiler that this statement
//will not be reached. It can used to tell the compiler that a branch
//is impossible, which the optimeser can then take advantage of.
test "unreachable" {
    const x: i32 = 1;
    const y: u32 = if (x == 2) 5 else unreachable;
    _ = y;
}

test "unreachable switch" {
    try std.testing.expect(asciiToUpper('a') == 'A');
    try std.testing.expect(asciiToUpper('A') == 'A');
}

//Pointers
//Normal pointeres in zig aren't allowed to have 0 or null as a value;
//Referencing is done with &, dereferencing with *
test "pointers" {
    var x: u8 = 1;
    increment(&x);
    try std.testing.expect(x == 2);
}
//Trying to set *T to the value 0 is detectable illegal behaviour
test "naughty pointer" {
    var x: u16 = 0;
    var y: *u8 = @intToPtr(*u8, x);
    _ = y;
}

//Zig also has const pointers, which cannot be used to modify the
//referenced data. Referencing a const variable will yield a const
//pointer
test "const pointers" {
    const x: u8 = 1;
    var y = &x;
    y.* += 1; //error: cannot assign to constant
}

//Pointer sized integers
//usize and isize are given as unsigned and signed integers which
//are hte same size as pointers
test "usize" {
    try std.testing.expect(@sizeOf(usize) == @sizeOf(*u8));
    try std.testing.expect(@sizeOf(isize) == @sizeOf(*u8));
}

//Many item pointers
//Sometimes it is possible to have a pointer to an unknown amount of elements
//[*]T is the solution for this, which works like *t but also supports indexing syntax
//pointer arithmetic and slicing
//Unlike *T, it cannot point to a type which does not have a known size.
//*T coerces to [*]T
//These many pointers may point to any amount of elements, including 0 and 1.

//Slices
//Slices can be thought of as a pair of [*]T (the pointer to the data) and a usize
//(the element count).
//Slices are used heavily throughout Zig for when you need to operate on arbitrary
//amounts of data.
//They have the same attributes as pointers, meaning that there also exists const slices.
test "slices" {
    const array = [_]u8{
        1,
        2,
        3,
        4,
        5,
    };
    const slice = array[0..3];
    try std.testing.expect(total(slice) == 6);
}
test "slices 2" {
    const array = [_]u8{
        1,
        2,
        3,
        4,
        5,
    };
    const slice = array[0..3];
    try std.testing.expect(@TypeOf(slice) == *const [3]u8);
}
test "slices 3" {
    var array = [_]u8{ 1, 2, 3, 4, 5 };
    var slice = array[0..];
    _ = slice;
}

test "set enum ordinal value" {
    try std.testing.expect(@enumToInt(Value2.hundred) == 100);
    try std.testing.expect(@enumToInt(Value2.thousand) == 1000);
    try std.testing.expect(@enumToInt(Value2.million) == 1000000);
    try std.testing.expect(@enumToInt(Value2.next) == 1000001);
}
test "enum method" {
    try std.testing.expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}
test "hmm" {
    Mode.count += 1;
    try std.testing.expect(Mode.count == 1);
}
test "struct usage" {
    const my_vecotr = Vec3{
        .x = 0,
        .y = 100,
        .z = 50,
    };
    _ = my_vector;
}
test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try std.testing.expect(thing.x == 20);
    try std.testing.expect(thing.y == 10);
}
test "simple union" {
    var result = Result{ .int = 1234 };
    result.float = 12.64; //error: access of inactive union field
}
test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) { //payload capturing
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try std.testing.expect(value.b == 3);
} //payload capturing is used to switch on the tag type
//of a union while also capturing the vlaue it contains
//Here is used a pointer capture; captured values are immutable,
//but with the |*value| syntax a pointer to the values can be
//captured instead of the values themselves.
//This allows dereferencing

//labelled blocks
test "labelled blocks" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += 1;
        break :blk sum;
    };
    try std.testing.expect(count == 45);
    try std.testing.expect(@TypeOf(count) == u32);
}
//Labelled loops
test "nested continue" {
    var count: usize = 0;
    outer: for ([_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5, 6 }) |_| {
            count += 1;
            continue :outer;
        }
    }
    try std.testing.expect(count == 8);
}
//Loops as expressions
//Like return, break accepts a value. This can be used to
//yield a value from a loop. Loops also have an else branch
//on loops, which is evaluated when the loop is not exited
//with a break
test "while loop expression" {
    try std.testing.expect(rangeHasNumber(0, 10, 3));
}

//Optionals
//Optionals use the syntax ?T and are used to store the
//data null or a value of type T
test "optional" {
    //var found_index: ?usize = null;
    //const data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 12 };

    //for (data, 0..) |v, i| {
    //if (v == 10) found_index = i;
    //}
    //try expect(found_index == null);
}

//Optionals support the orelse expression, which acts when
//the optional is null.
//This unwraps the optional to its child type
test "orelse" {
    var a: ?f32 = null;
    var b = a orelse 0;
    const c = a.?;
    _ = c; //shortend for orelse unreachable
    try std.testing.expect(b == 0);
    try std.testing.expect(@TypeOf(b) == f32);
}
//orelse unreachable is used when it is impossible for an
//optional value to be null, and using this to unwrap a null
//value is detectable illegal behaviour
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    try std.testing.expect(b == c);
    try std.testing.expect(@TypeOf(c) == f32);
}
//Payload capturing works in many places for optionals,
//in the event that it is non-null we can "capture" its
//non null value
test "if optional payload capture" {
    const a: ?i32 = 5;
    if (a != null) {
        const value = a.?;
        _ = value;
    }
    var b: ?i32 = 5;
    if (b) |*value| {
        value.* += 1;
    }
    try std.testing.expect(b.? == 6);
}
pub fn main() !void {

    

    //Unions
    //Zig's unions allow you to define types which store one
    //value of many possible typed fields; Only one field may
    //be active at one time
    //Bare union types do not have a guaranteed memory layout,
    //bare unions cannot be used to reinterpret memory.
    //Accessing a field in a union which is not active is
    //detectable illegal behaviour.
    const Result = union {
        int: i64,
        float: f64,
        bool: bool,
    };
    _ = Result;
    test "enum ordinal value" {
        try std.testing.expect(@enumToInt(Value.zero) == 0);
        try std.testing.expect(@enumToInt(Value.one) == 1);
        try std.testing.expect(@enumToInt(Value.two) == 2);
    }

    //Tagged unions are unions which use an enum to detect
    //which field is active.
    const Tag = enum { a, b, c };
    const Tagged = union(Tag) { a: u8, b: f32, c: bool };
    _ = Tagged;
}

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) return true;
    } else false;
}

fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}

fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

fn increment(num: *u8) void {
    num.* += 1;
}
