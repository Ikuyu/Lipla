# Package

version       = "0.1.0"
author        = "Ikuyu"
description   = "A command line oriented life plan assistent"
license       = "MIT"
srcDir        = "src"
bin           = @["lipla"]

# Dependencies

requires "nim >= 1.4.0"
requires "https://github.com/jangko/nim-noise"
requires "https://github.com/docopt/docopt.nim"

task macesc, " compile to release mode with esc_exit_editing on":
  exec "nim c -d:release -d:esc_exit_editing --verbosity:0 --hints:off --outdir:./bin src/lipla.nim"
task docs, "  create documentation for lifeplan.nim and repl.nim":
  exec "nim doc src/lifeplan.nim"
  exec "nim doc src/repl.nim"
task winesc, "compile to release mode for Windows with esc_exit_editing on":
  exec "nim c -d:release -d:mingw -d:esc_exit_editing --verbosity:0 --hints:off --outdir:./bin src/lipla.nim"
