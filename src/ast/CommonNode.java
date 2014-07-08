package ast;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;

@SuppressWarnings("unchecked")
public class CommonNode extends AbstractNode{
    // A lot of constructors :)
    public CommonNode(){ super(); }
    public CommonNode(int t){ super(new CommonToken(t)); }
    public CommonNode(Token t){ super(t); }
    public CommonNode(CommonNode n){ super(n); }
    public CommonNode dupNode(){
        return this.getDuplicate();
    }

    /**
     * Returns duplicate of current node. Used by dupNode().
     */
    public CommonNode getDuplicate(){
        return new CommonNode(this);
    }
}