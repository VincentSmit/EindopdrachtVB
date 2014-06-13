package ast;

import org.antlr.runtime.tree.CommonTree;
import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;

/*
 * Control nodes alter the flow of execution of a program. These are
 * for example RETURN, CONTINUE and BREAK. Each ControlNode contains
 * a 'parent' which it belongs to.
 */
public class ControlNode extends TypedNode{
    public CommonTree parent;

    public ControlNode(Token t){
        super(t);
    }

    public ControlNode(ControlNode n){
        super(n);
        this.parent = n.getParent();
    }

    public void setParent(CommonTree p){
        this.parent = p;
    }

    public CommonTree getParent(){
        return this.parent;
    }
}