package symtab;

import ast.IdentifierNode;

/**
 * VB prac week1 - SymbolTable.
 * class IdEntry.
 * @author   Theo Ruys
 * @version  2006.04.21
 */
public class IdEntry {
    private int  level = -1;
    private IdentifierNode node;

    public int   getLevel()             { return this.level;         }
    public void  setLevel(int level)    { this.level = level;   }

    public IdentifierNode getNode() { return this.node; };

    public IdEntry(IdentifierNode node){ this.node = node; }
    public IdEntry(){}
}
