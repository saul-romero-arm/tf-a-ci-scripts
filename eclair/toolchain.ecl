# Compilers.
-file_tag+={GCC,"^/opt/gcc-arm-.+/bin/aarch64-none-elf-gcc$"}

-config=STD.tokenext,+behavior={c99, GCC, "^(__asm|__asm__|__attribute__|__restrict|__typeof__|__builtin_types_compatible_p|__builtin_offsetof|__volatile__|__alignof|_Static_assert)$"}
-config=STD.inclnest,+behavior={c99, GCC, 24}
-config=STD.ppifnest,+behavior={c99, GCC, 32}
-config=STD.macident,+behavior={c99, GCC, 4096}
-config=STD.stdtypes,+behavior={c99, GCC, "unsigned long long||long long"}

-config=STD.charsmem,+behavior={c99, GCC, utf8}
-config=STD.bytebits,+behavior={c99, GCC, 8}
-config=STD.freesten,+behavior={c99, GCC, specified}
-config=STD.freestnd,+behavior={c99, GCC, specified}
