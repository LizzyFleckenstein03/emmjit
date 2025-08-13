# emmjit

An [emmental](https://esolangs.org/wiki/Emmental) JIT for Linux x86-64, written in assembly.

Compile with `./build.sh`, invoke using `./emmjit file.emm`. See examples directory for some files to test with.

The `interpreter` directory contains an emmental interpreter written in lua, you can use this to benchmark against emmjit. On my machine, emmjit currently seems to be roughly 20x faster.
