#ifndef generator_h
#define generator_h

#include <stdbool.h>
#include "vector.h"

char *first_reg();
char *next_reg(char *current);
char *param_reg(int index);

void write_file_metadata();

void write_function_header(char *name, long var_count, bool has_call);
void write_multistage_function_header(char *name, long var_count, bool has_call, vector *high_args, vector *low_args);

void write_return();
void write_move(char *src, char *dst);
void write_move_val(long val, char *dst);
void write_move_to_stack(char *src, long addr);
void write_move_to_stack_val(long val, long addr);
void write_move_from_stack(long addr, char *dst);
void write_move_to_addr(char *src, char *dst);
void write_move_to_addr_val(long val, char *dst);
void write_move_from_addr(char *src, char *dst);

void write_calc_index(char *src, char *index_src, char *dst);
void write_calc_index_val(char *src, long val, char *dst);

void write_not(char *dst);
void write_neg(char *dst);
void write_add(char *src, char *src2, char *dst);
void write_sub(char *src, char *dst);
void write_mul(char *src, char *dst);
void write_and(char *src, char *dst);
void write_equal(char *src1, char *src2, char *dst);
void write_greater(char *src1, char *src2, char *dst);
void write_index(char *src, char *index, char *dst);

void write_add_val(long val, char *src2, char *dst);
void write_mul_val(long val, char *src2, char *dst);
void write_and_val(long val, char *dst);
void write_equal_val(long val, char *src2, char *dst);
void write_greater_val(long val, char *src2, char *dst);
void write_less_val(long val, char *src2, char *dst);
void write_index_val(char *src, long index_val, char *dst);

void write_label(char *name, char *funcname);
void write_goto(char *name, char *funcname);
void write_if(char *reg, char *name, char *funcname);

void write_stage_one(char *name, vector *regs, char *dst);
void write_call(char *name, vector *regs, char *dst, long vars_count);
void write_closure_call(char *src_flat_closure, vector *regs, char *dst, long vars_count);

#endif