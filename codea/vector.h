#ifndef vector_h
#define vector_h

#include <stdbool.h>

typedef struct vector
{
    int len;
    int cap;
    char **content;
} vector;

vector *new_vector();
vector *add_vector(vector *v, char *neew);
vector *merge_vector(vector *first, vector *second);
vector *clone_vector(vector *other);
bool in_vector(vector *v, char *target);
int index_in_vector(vector *v, char *target);
void assert_in_vector(vector *v, char *target);
void assert_contains_vector(vector *v, vector *other);
void assert_disjoined_vector(vector *first, vector *second);

#endif