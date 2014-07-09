package ast;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;

/**
 * CommonNode replaces the antlr class CommonTree. It is the base node for all other
 * custom nodes, and is used as a default type for all AST nodes. Other than an implementation
 * of getDuplicate() (as documented in AbstractNode), it does not differ from CommonTree.
 */
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
