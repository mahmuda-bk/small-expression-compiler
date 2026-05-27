#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

typedef enum {
    TYPE_INT,
    TYPE_FLOAT
} DataType;

typedef struct {
    char name[50];
    char type[20];
    char scope[20];
    int scopeLevel;
    double value;
    int initialized;
} Symbol;

void enterScope(void);
void exitScope(void);
int currentScopeLevel(void);
const char* currentScopeName(void);

void insertSymbol(const char *name, DataType type, int lineNo);
int searchSymbol(const char *name);
void updateSymbol(const char *name, double value);
double getValue(const char *name);
DataType getSymbolType(const char *name);
int isSymbolInitialized(const char *name);
void displaySymbolTable();

#endif
