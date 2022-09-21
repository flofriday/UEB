/**
 * A super minimilistic implementation of a dynamic char array.
 * It is trimmed for this very specific use case and will quickly
 * fall apart if used for anything serious.
 *
 * For example, since I know that running out of memory will be a non-issue
 * for these exercises I skipped all errorhandling of malloc, realloc and free.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "vector.h"

void print_vector(vector *v)
{
    printf("[\n");
    for (int i = 0; i < v->len; i++)
    {
        printf("'%s'\n", v->content[i]);
    }
    printf("]\n");
}

vector *new_vector()
{
    vector *v = malloc(sizeof(vector));
    v->len = 0;
    v->cap = 8;
    v->content = malloc(sizeof(char *) * v->cap);
    return v;
}

void free_vector(vector *v)
{
    free(v->content);
    free(v);
}

vector *resize_vector(vector *v, int new_size)
{
    v->cap = new_size;
    v = realloc(v, sizeof(char *) * v->cap);
    return v;
}

vector *add_vector(vector *v, char *new)
{
    if (in_vector(v, new))
    {
        fprintf(stderr, "ERROR: '%s' was already defined!\n", new);
        exit(3);
    }

    if (v->cap == v->len)
    {
        v = resize_vector(v, v->cap * 2);
    }

    // TODO: should we copy the new string to the heap?
    v->content[v->len] = new;
    v->len++;

    return v;
}

/* This is a bad operation because it takes O(n) to run and could be O(1) if
 * implemented with a linked list.
 */
vector *merge_vector(vector *first, vector *second)
{
    for (int i = 0; i < second->len; i++)
    {
        first = add_vector(first, second->content[i]);
    }

    return first;
}

bool in_vector(vector *v, char *target)
{
    for (int i = 0; i < v->len; i++)
    {
        if (strcmp(v->content[i], target) == 0)
            return true;
    }
    return false;
}

vector *clone_vector(vector *other)
{
    vector *v = new_vector();
    for (int i = 0; i < other->len; i++)
    {
        add_vector(v, other->content[i]);
    }
    return v;
}

void assert_in_vector(vector *v, char *target)
{
    if (!in_vector(v, target))
    {
        fprintf(stderr, "ERROR: '%s' is not visible\n", target);
        exit(3);
    }
}

void assert_contains_vector(vector *v, vector *other)
{
    for (int i = 0; i < other->len; i++)
    {
        char *target = other->content[i];
        if (!in_vector(v, target))
        {
            fprintf(stderr, "ERROR: '%s' is not visible\n", target);
            exit(3);
        }
    }
}

void assert_disjoined_vector(vector *first, vector *second)
{
    for (int i = 0; i < second->len; i++)
    {
        char *target = second->content[i];
        if (in_vector(first, target))
        {
            fprintf(stderr, "ERROR: '%s' is already defined\n", target);
            exit(3);
        }
    }
}
