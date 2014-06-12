package ast;

import org.antlr.runtime.tree.CommonTree;   
import org.antlr.runtime.Token;

public class TypedNode extends CommonTree {
    //Type van deze Expressie
    private Type exprType;

    public TypedNode() {
        super();
    }    

    public TypedNode(Token t) {
        super(t);
    }

    public TypedNode(TypedNode n) {
        super(n);
        this.exprType = n.getExprType();
    }

    public TypedNode(CommonTree n){
        super(n);
    }

    public TypedNode dupNode() {
        return new TypedNode(this);
    }

    public Type getExprType() {
        return exprType;
    }

    public void setExprType(Type type) {
        this.exprType = type;
    }
}