#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>
#include <string.h>

#include "generator.h"

int NUM_REGS = 9;
char *regs[] = {"rax", "r11", "r10", "r9", "r8", "rcx", "rdx", "rsi", "rdi"};
int NUM_PARAM_REGS = 6;
char *param_regs[] = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"};
int NUM_BYTE_REGS = 9;
char *byte_regs[] = {"al", "r11b", "r10b", "r9b", "r8b", "cl", "dl", "sil", "dil"};

bool has_locals;

char *first_reg()
{
    return regs[0];
}

char *next_reg(char *current)
{

    for (int i = 0; i < NUM_REGS - 1; i++)
    {
        if (strcmp(current, regs[i]) == 0)
            return regs[i + 1];
    }

    fprintf(stderr, "ERROR: There are no registers left to give.\n");
    exit(3);
    return NULL;
}

int reg_index(char *current)
{
    for (int i = 0; i < NUM_REGS; i++)
    {
        if (strcmp(current, regs[i]) == 0)
            return i;
    }
    fprintf(stderr, "ERROR: The current %s register is was not found\n", current);
    exit(3);
    return -1;
}

char *param_reg(int index)
{
    if (index < 0)
    {
        fprintf(stderr, "ERROR: Parameter registers cannot be negative.\n");
        exit(3);
    }

    if (index > NUM_PARAM_REGS)
    {
        fprintf(stderr, "ERROR: There are only %d parameter registers to give. You wanted a %dth one.\n", NUM_PARAM_REGS, index);
        exit(3);
    }

    return param_regs[index];
}

char *byte_reg(char *reg)
{
    for (int i = 0; i < NUM_BYTE_REGS; i++)
    {
        if (strcmp(reg, regs[i]) == 0)
            return byte_regs[i];
    }

    fprintf(stderr, "ERROR: No matching byte reg found to %s.\n", reg);
    exit(3);
}

void write_file_metadata()
{
    time_t now = time(NULL);
    struct tm *ptm = localtime(&now);

    printf("# Compiled by Florian Freitag's compiler on %s", asctime(ptm));
}

void write_function_header(char *name, long var_count, bool has_call)
{
    printf(
        "\t.global\t%s\n"
        "\t.type\t%s, @function\n"
        "%s:\n",
        name, name, name);

    // This is just preperation for the gesamt example
    if (has_call)
    {
        has_locals = true;
        printf("\tenter\t$%d, $0\n", 7 * 8);
    }
    else
    {
        has_locals = false;
    }
}

void write_multistage_function_header(char *name, long var_count, bool has_call, vector *high_args, vector *low_args)
{
    // Write the default function header
    write_function_header(name, var_count, has_call);

    // Move the higher arguments into the "default" registers as if it would be
    // a normal function call. Therefore the other generating code parts can be
    // shared between single stage functions and multistage functions.
    //
    // We work here in reverse order, because we also need to override the
    // register from which we need to read in the loop. If we do it in reverse
    // we only overwrite it in the last iteration after which we don't need it
    // anymore so it should be fine.
    char *arg_reg = param_reg(low_args->len);
    for (int i = high_args->len - 1; i >= 0; i--)
    {
        printf(
            "\tmovq\t%d(%%%s), %%%s\n",
            8 * (i + 1), arg_reg, param_reg(low_args->len + i));
    }
}

void write_move(char *src, char *dst)
{
    // Yes we can do this as we are always using the same strings with the same
    // pointers.
    // A optimization to remove unneccessary moves.
    if (strcmp(src, dst) == 0)
    {
        return;
    }

    printf("\tmovq\t%%%s, %%%s\n", src, dst);
}

void write_move_val(long value, char *dst)
{
    printf("\tmovq\t$%ld, %%%s\n", value, dst);
}

void write_move_to_stack(char *src, long addr)
{
    printf(
        "\tmovq\t%%%s, %ld(%%rsp)\n",
        src, addr);
}

void write_move_to_stack_val(long val, long addr)
{
    printf(
        "\tmovq\t$%ld, %ld(%%rsp)\n",
        val, addr);
}

void write_move_from_stack(long addr, char *dst)
{
    printf(
        "\tmovq\t%ld(%%rsp), %%%s\n",
        addr, dst);
}

void write_move_to_addr(char *src, char *dst)
{
    printf(
        "\tmovq\t%%%s, (%%%s)\n",
        src, dst);
}

void write_move_to_addr_val(long val, char *dst)
{
    printf(
        "\tmovq\t$%ld, (%%%s)\n",
        val, dst);
}

void write_move_from_addr(char *src, char *dst)
{
    printf(
        "\tmovq\t(%%%s), %%%s\n",
        src, dst);
}

void write_calc_index(char *src, char *index_src, char *dst)
{
    printf(
        "\tleaq\t(%%%s, %%%s, 8), %%%s\n",
        src, index_src, dst);
}

void write_calc_index_val(char *src, long val, char *dst)
{
    printf(
        "\tleaq\t%ld(%%%s), %%%s\n",
        val * 8, src, dst);
}

void write_return()
{
    if (has_locals)
    {
        printf("\tleave\n");
    }
    printf("\tret\n");
}

void write_read_addr(char *src, char *dst)
{
    printf(
        "\tmovq\t(%%%s), %%%s\n",
        src, dst);
}

void write_not(char *dst)
{
    printf("\tnotq\t%%%s\n", dst);
}

void write_neg(char *dst)
{
    printf("\tnegq\t%%%s\n", dst);
}

void write_add(char *src1, char *src2, char *dst)
{
    // We use here lea instead of add because this allows us to also perfrom a
    // a move in the same instruction, saving us quite often a whole move
    // instruction.
    printf(
        "\tleaq\t(%%%s, %%%s), %%%s\n",
        src1, src2, dst);
}

void write_sub(char *src, char *dst)
{
    printf(
        "\tsubq\t%%%s, %%%s\n", src, dst);
}

void write_mul(char *src, char *dst)
{
    printf(
        "\timulq\t%%%s, %%%s\n", src, dst);
}

void write_and(char *src, char *dst)
{
    printf(
        "\tandq\t%%%s, %%%s\n", src, dst);
}

void write_equal(char *src1, char *src2, char *dst)
{
    printf(
        "\tcmpq\t%%%s, %%%s\n"
        "\tsete\t%%%s\n"
        "\tand\t$1, %%%s\n",
        src1, src2, byte_reg(dst), dst);
}

void write_greater(char *src1, char *src2, char *dst)
{
    printf(
        "\tcmpq\t%%%s, %%%s\n"
        "\tsetg\t%%%s\n"
        "\tand\t$1, %%%s\n",
        src1, src2, byte_reg(dst), dst);
}

void write_index(char *src, char *index, char *dst)
{
    printf(
        "\tmovq\t(%%%s, %%%s, 8), %%%s\n",
        src, index, dst);
}

void write_add_val(long val, char *src2, char *dst)
{
    // We use here lea instead of add because this allows us to also perfrom a
    // a move in the same instruction, saving us quite often a whole move
    // instruction.
    printf(
        "\tleaq\t%ld(%%%s), %%%s\n", val, src2, dst);
}

void write_mul_val(long val, char *src2, char *dst)
{
    printf(
        "\timulq\t$%ld, %%%s, %%%s\n", val, src2, dst);
}

void write_and_val(long val, char *dst)
{
    printf(
        "\tandq\t$%ld, %%%s\n", val, dst);
}

void write_equal_val(long val, char *src2, char *dst)
{
    printf(
        "\tcmpq\t$%ld, %%%s\n"
        "\tsete\t%%%s\n"
        "\tand\t$1, %%%s\n",
        val, src2, byte_reg(dst), dst);
}

void write_greater_val(long val, char *src2, char *dst)
{
    printf(
        "\tcmpq\t$%ld, %%%s\n"
        "\tsetg\t%%%s\n"
        "\tand\t$1, %%%s\n",
        val, src2, byte_reg(dst), dst);
}

void write_less_val(long val, char *src2, char *dst)
{
    printf(
        "\tcmpq\t$%ld, %%%s\n"
        "\tsetl\t%%%s\n"
        "\tand\t$1, %%%s\n",
        val, src2, byte_reg(dst), dst);
}

void write_index_val(char *src, long index_val, char *dst)
{
    printf(
        "\tmovq\t%ld(%%%s), %%%s\n",
        index_val * 8, src, dst);
}

void write_label(char *name, char *funcname)
{
    printf("\t.L_%s_%s:\n", funcname, name);
}

void write_goto(char *name, char *funcname)
{
    printf("\tjmp\t.L_%s_%s\n", funcname, name);
}

// Ifs are weired, they jump if the condition results in a odd value
void write_if(char *reg, char *name, char *funcname)
{
    printf(
        "\tandq\t$1, %%%s\n"
        "\tcmpq\t$1, %%%s\n"
        "\tje\t.L_%s_%s\n",
        reg, reg, funcname, name);
}

void write_stage_one(char *name, vector *regs, char *dst)
{
    // First, we need to allocate the heap pointer(r15)
    // Then we will copy the function pointer to the start of the heap
    // And then we will copy
    long size = regs->len * 8 + 8;
    printf(
        "\tleaq\t(%%r15), %%%s\n"
        "\taddq\t$%ld, %%r15\n"
        "\tmovq\t$%s, (%%%s)\n",
        dst, size, name, dst);

    for (long i = 0; i < regs->len; i++)
    {
        printf(
            "\tmovq\t%%%s, %ld(%%%s)\n",
            regs->content[i], (i + 1) * 8, dst);
    }
}

void write_call(char *name, vector *arg_regs, char *dst, long vars_count)
{
    // Implementation Note:
    // Function calls are quite expensive in this implementation, as they first
    // save all visible variables on the stack, than call the function and
    // finally restore the variables from the stack to registers.
    // I did this because I have a couple of optimizations that rely on the vars
    // beeing in registers. If I had more time to play with optimization I would
    // have improved it so that you can approximate if that approach is more
    // efficient than just storing variables on the stack and select the better
    // solution on a case by case basis.

    // Save the current vars (and rax if used by another expr)
    for (long i = 0; i < vars_count; i++)
    {
        if (strcmp(dst, param_reg(i)) == 0)
            continue;
        write_move_to_stack(param_reg(i), i * 8);
    }
    for (long i = 0; i < reg_index(dst); i++)
    {
        if (strcmp(regs[i], dst) != 0)
        {
            write_move_to_stack(regs[i], vars_count * 8);
        }
    }

    // Call the function
    for (long i = 0; i < arg_regs->len; i++)
    {
        write_move(arg_regs->content[i], param_reg(i));
    }

    printf("\tcall\t%s\n", name);
    write_move("rax", dst);

    // Restore the current vars (and rax if used by another expr)
    for (long i = 0; i < vars_count; i++)
    {
        if (strcmp(dst, param_reg(i)) == 0)
            continue;
        write_move_from_stack(i * 8, param_reg(i));
    }
    for (long i = 0; i < reg_index(dst); i++)
    {
        if (strcmp(regs[i], dst) != 0)
        {
            write_move_from_stack(vars_count * 8, regs[i]);
        }
    }
}

void write_closure_call(char *src_flat_closure, vector *arg_regs, char *dst, long vars_count)
{
    // Implementation Note:
    // see write_call

    // Save the current vars (and rax if used by another expr)
    for (long i = 0; i < vars_count; i++)
    {
        write_move_to_stack(param_reg(i), i * 8);
    }
    for (long i = 0; i < reg_index(dst); i++)
    {
        if (strcmp(regs[i], dst) != 0)
        {
            write_move_to_stack(regs[i], vars_count * 8);
        }
    }

    // Call the function
    for (long i = 0; i < arg_regs->len; i++)
    {
        write_move(arg_regs->content[i], param_reg(i));
    }
    write_move(src_flat_closure, param_reg(arg_regs->len));
    printf("\tcall\t*(%%%s)\n", src_flat_closure);
    write_move(first_reg(), dst);

    // Restore the current vars (and rax if used by another expr)
    for (long i = 0; i < vars_count; i++)
    {
        write_move_from_stack(i * 8, param_reg(i));
    }
    for (long i = 0; i < reg_index(dst); i++)
    {
        if (strcmp(regs[i], dst) != 0)
        {
            write_move_from_stack(vars_count * 8, regs[i]);
        }
    }
}