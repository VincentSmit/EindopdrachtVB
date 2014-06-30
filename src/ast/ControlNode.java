package ast;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;

/*
 * Control nodes alter the flow of execution of a program. These are
 * for example RETURN, CONTINUE and BREAK. Each ControlNode contains
 * a 'parent' which it belongs to.
 */
@SuppressWarnings("unchecked")
public class ControlNode extends CommonNode{
    public CommonNode parent;

    public ControlNode(CommonNode n){ super(n); }
    public ControlNode(int n){ super(new CommonToken(n)); };
    public ControlNode(Token t){ super(t); }
    public ControlNode(ControlNode n){
        super(n);
        this.parent = n.getParent();
    }

    public ControlNode getDuplicate(){
        return new ControlNode(this);
    }

    public void setParent(CommonNode p){
        this.parent = p;
    }

    public CommonNode getParent(){
        return this.parent;
    }
}