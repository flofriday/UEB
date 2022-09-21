#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "generator.h"

int NUM_REGS = 9;
char *regs[] = {"rax", "r11", "r10", "r9", "r8", "rcx", "rdx", "rsi", "rdi"};
int NUM_PARAM_REGS = 6;
char *param_regs[] = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"};
int NUM_BYTE_REGS = 9;
char *byte_regs[] = {"al", "r11b", "r10b", "r9b", "r8b", "cl", "dl", "sil", "dil"};

char *first_reg()
{
    return regs[0];
}

char *next_reg(char *current)
{

    for (int i = 0; i < NUM_REGS - 1; i++)
    {
        if (current == regs[i])
            return regs[i + 1];
    }

    fprintf(stderr, "ERROR: There are no registers left to give.\n");
    exit(3);
    return NULL;
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
        if (reg == regs[i])
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

void write_function_header(char *name)
{
    printf(
        "\t.global\t%s\n"
        "\t.type\t%s, @function\n"
        "%s:\n",
        name, name, name);
}

void write_multistage_function_header(char *name, vector *high_args, vector *low_args)
{
    // Write the default function header
    write_function_header(name);

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
    if (src == dst)
    {
        return;
    }

    printf("\tmovq\t%%%s, %%%s\n", src, dst);
}

void write_move_val(long val, char *dst)
{
    printf("\tmovq\t$%ld, %%%s\n", val, dst);
}

// Move the result to rax and return.
void write_return()
{
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

void write_index(char *srcdst, char *index)
{
    printf(
        "\tmovq\t(%%%s, %%%s, 8), %%%s\n",
        srcdst, index, srcdst);
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
    // TODO: read the flag like a professional and dont use three moves like the morron you are
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

void write_index_val(char *srcdst, long index_val)
{
    printf(
        "\tmovq\t%ld(%%%s), %%%s\n",
        index_val * 8, srcdst, srcdst);
}

void write_label(char *name, char *funcname)
{
    printf(".L_%s_%s\n", funcname, name);
}