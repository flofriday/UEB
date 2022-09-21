#ifndef generator_h
#define generator_h

#include "vector.h"

char *first_reg();
char *next_reg(char *current);
char *param_reg(int index);

void write_file_metadata();

void write_function_header(char *name);
void write_multistage_function_header(char *name, vector *high_args, vector *low_args);

void write_return();
void write_move(char *src, char *dst);
void write_move_val(long val, char *dst);

void write_not(char *dst);
void write_neg(char *dst);
void write_add(char *src, char *src2, char *dst);
void write_sub(char *src, char *dst);
void write_mul(char *src, char *dst);
void write_and(char *src, char *dst);
void write_equal(char *src1, char *src2, char *dst);
void write_greater(char *src1, char *src2, char *dst);
void write_index(char *srcdst, char *index);

void write_add_val(long val, char *src2, char *dst);
void write_mul_val(long val, char *src2, char *dst);
void write_and_val(long val, char *dst);
void write_equal_val(long val, char *src2, char *dst);
void write_greater_val(long val, char *src2, char *dst);
void write_less_val(long val, char *src2, char *dst);
void write_index_val(char *srcdst, long index_val);

void write_label(char *name, char *funcname);

#endif