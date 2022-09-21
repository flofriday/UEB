#ifndef tree_h
#define tree_h

typedef struct burm_state *STATEPTR_TYPE;

typedef enum
{
    OP_RETURN = 0,
    OP_NOT,
    OP_SUB,
    OP_ADD,
    OP_MUL,
    OP_AND,
    OP_EQUAL,
    OP_GREATER,
    OP_NUM,
    OP_INDEX,
    OP_ID,
    OP_NOP, // A placeholder op code
    OP_GOTO,
    OP_IF,
    OP_ASSIGN,
    OP_VAR, // Creating a new local variable
    OP_STAGE_ONE,
    OP_EXPRS,
    OP_CALL,
    OP_CLOSURE_CALL,
}
operator;

typedef struct tree
{
    operator op;
    struct tree *kids[2];
    STATEPTR_TYPE state;

    long value;

    char *identifier;
    char *funcname; // Enclosing func name;
    int param_id;

    char *reg;
} tree;

typedef tree *NODEPTR_TYPE;

#define OP_LABEL(p) ((p)->op)
#define LEFT_CHILD(p) ((p)->kids[0])
#define RIGHT_CHILD(p) ((p)->kids[1])
#define STATE_LABEL(p) ((p)->state)
#define PANIC printf

tree *new_tree(operator op, tree *left, tree *right);
tree *new_num_leaf(long value);
tree *new_param_leaf(char *name, int param_id);
tree *new_label_leaf(char *name, char *funcname);
tree *new_call_leaf(char *name, tree *exprs, long vars_count);
tree *new_closure_call_leaf(tree *expr, tree *exprs, long vars_count);
// tree *new_nop_leaf();

void print_tree(tree *node);

#endif