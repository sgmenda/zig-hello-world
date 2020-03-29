const stdio = @cImport({
    @cInclude("stdio.h");
});

pub fn main() void {
    _ = stdio.printf("Hello, World!\n");
}
