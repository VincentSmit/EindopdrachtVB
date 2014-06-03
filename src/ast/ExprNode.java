package ast;

import org.antlr.runtime.tree.CommonTree;   
import org.antlr.runtime.Token;

public class ExprNode extends CommonTree {
    //Type van deze Expressie
    private Type type;

    public ExprNode() {
        super();
    }    

    public ExprNode(Token t) {
        super(t);
    }

    public ExprNode(ExprNode n) {
        super(n);
        this.type = n.getExprType();
    }

    public ExprNode dupNode() {
        return new ExprNode(this);
    }

    public Type getExprType() {
        return type;
    }

    public void setExprType(Type type) {
        this.type = type;
    }
}