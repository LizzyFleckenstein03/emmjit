# emmjit

An [emmental](https://esolangs.org/wiki/Emmental) JIT for Linux x86-64, written in assembly.

Compile with `./build.sh`, invoke using `./emmjit file.emm`. See examples directory for some files to test with.

There are still a lot of bugs and problems, in particular it consumes memory really fast. A proper heap implementation is needed.

The `interpreter` directory contains an emmental interpreter written in lua, you can use this to benchmark against emmjit. On my machine, emmjit currently seems to be roughly 3x faster (This will probably improve a lot once the heap is implemented.)
