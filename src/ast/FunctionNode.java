package ast;

import org.antlr.runtime.Token;

/*
 * A function node contains a list of argument it takes as TypedNodes pointing
 * to the .
 */
@SuppressWarnings("unchecked")
public class FunctionNode extends CommonNode{
    public FunctionNode(CommonNode n){ super(n); }
    public FunctionNode(Token t){ super(t); }
    public FunctionNode(FunctionNode n){
        super(n);
    }

    public FunctionNode getDuplicate(){
        return new FunctionNode(this);
    }
}