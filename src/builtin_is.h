// Prototypes for executing builtin_echo function.
#ifndef FISH_BUILTIN_IS_H
#define FISH_BUILTIN_IS_H

class parser_t;
struct io_streams_t;

int builtin_is(parser_t &parser, io_streams_t &streams, wchar_t **argv);
#endif
