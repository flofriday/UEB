#include <stdlib.h>
#include <stdio.h>

#include "tree.h"

tree *new_empty_tree()
{
    tree *new = malloc(sizeof(tree));
    new->op = -1;
    new->kids[0] = NULL;
    new->kids[1] = NULL;
    new->value = -1;
    new->reg = NULL;
    new->identifier = NULL;
    new->param_id = -1;
    return new;
}

tree *new_tree(operator op, tree *left, tree *right)
{
    tree *new = new_empty_tree();
    new->op = op;
    new->kids[0] = left;
    new->kids[1] = right;
    return new;
}

tree *new_num_leaf(long value)
{
    tree *new = new_empty_tree();
    new->op = OP_NUM;
    new->value = value;
    return new;
}

tree *new_param_leaf(char *name, int param_id)
{
    tree *new = new_empty_tree();
    new->op = OP_ID;
    new->identifier = name;
    new->param_id = param_id;
    return new;
}

tree *new_nop_leaf()
{
    tree *new = new_empty_tree();
    new->op = OP_NOP;
    return new;
}

void print_tree_rec(tree *node, int depth)
{
    if (node == NULL)
    {
        for (int i = 0; i < depth; i++)
            printf("\t");

        printf("- NULL\n");
        return;
    }

    // Print current node
    for (int i = 0; i < depth; i++)
        printf("\t");
    printf("- TREE: op=%d value=%ld ", node->op, node->value);
    if (node->reg == NULL)
    {
        printf("reg=NULL");
    }
    else
    {
        printf("reg=%s", node->reg);
    }
    printf("\n");

    // Print kids recursivley
    print_tree_rec(node->kids[0], depth + 1);
    print_tree_rec(node->kids[1], depth + 1);
}

void print_tree(tree *node)
{
    print_tree_rec(node, 0);
}
