#include <stdio.h>
#include <string.h>
#include "symbol_table.h"

Symbol table[100];
int count = 0;
static int scopeLevel = 0;

static const char *typeToString(DataType type) {
    return type == TYPE_FLOAT ? "float" : "int";
}

static const char *scopeToString(int level) {
    return level == 0 ? "global" : "local";
}

void enterScope(void) {
    scopeLevel++;
}

void exitScope(void) {
    if(scopeLevel > 0) {
        scopeLevel--;
    }
}

int currentScopeLevel(void) {
    return scopeLevel;
}

const char* currentScopeName(void) {
    return scopeToString(scopeLevel);
}

void insertSymbol(const char *name, DataType type, int lineNo) {
    for(int i = count - 1; i >= 0; i--) {
        if(table[i].scopeLevel != scopeLevel) {
            continue;
        }
        if(strcmp(table[i].name, name) == 0) {
            printf("Line %d: Semantic Error - Variable '%s' already declared in current scope\n", lineNo, name);
            return;
        }
    }

    if(count >= 100) {
        printf("Line %d: Semantic Error - Symbol table overflow\n", lineNo);
        return;
    }

    strcpy(table[count].name, name);
    strcpy(table[count].type, typeToString(type));
    strcpy(table[count].scope, scopeToString(scopeLevel));
    table[count].scopeLevel = scopeLevel;
    table[count].value = 0.0;
    table[count].initialized = 0;
    count++;
}

int searchSymbol(const char *name) {
    for(int i = count - 1; i >= 0; i--) {
        if(table[i].scopeLevel > scopeLevel) {
            continue;
        }
        if(strcmp(table[i].name, name) == 0) return i;
    }
    return -1;
}

void updateSymbol(const char *name, double value) {
    int index = searchSymbol(name);
    if(index != -1) {
        table[index].value = value;
        table[index].initialized = 1;
    }
}

double getValue(const char *name) {
    int index = searchSymbol(name);
    if(index != -1) return table[index].value;
    return 0.0;
}

DataType getSymbolType(const char *name) {
    int index = searchSymbol(name);
    if(index != -1) {
        return strcmp(table[index].type, "float") == 0 ? TYPE_FLOAT : TYPE_INT;
    }
    return TYPE_INT;
}

int isSymbolInitialized(const char *name) {
    int index = searchSymbol(name);
    if(index != -1) {
        return table[index].initialized;
    }
    return 0;
}

void displaySymbolTable() {
    printf("\n%-15s %-10s %-10s %-10s\n", "Variable", "Type", "Scope", "Value");
    printf("--------------------------------------------------\n");
    for(int i=0; i<count; i++) {
        if(strcmp(table[i].type, "float") == 0) {
            printf("%-15s %-10s %-10s %-10g\n", table[i].name, table[i].type, table[i].scope, table[i].value);
        } else {
            printf("%-15s %-10s %-10s %-10.0f\n", table[i].name, table[i].type, table[i].scope, table[i].value);
        }
    }
}
