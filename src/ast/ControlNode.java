package ast;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;

/*
 * Control nodes alter the flow of execution of a program. These are
 * for example RETURN, CONTINUE and BREAK. Each ControlNode contains
 * a 'scope' which it belongs to.
 */
@SuppressWarnings("unchecked")
public class ControlNode extends CommonNode{
    public CommonNode scope;

    public ControlNode(CommonNode n){ super(n); }
    public ControlNode(int n){ super(new CommonToken(n)); };
    public ControlNode(Token t){ super(t); }
    public ControlNode(ControlNode n){
        super(n);
        this.scope = n.getScope();
    }

    public ControlNode getDuplicate(){
        return new ControlNode(this);
    }

    public void setScope(CommonNode p){
        this.scope = p;
    }

    public CommonNode getScope(){
        return this.scope;
    }
}