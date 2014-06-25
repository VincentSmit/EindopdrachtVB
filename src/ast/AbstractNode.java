package ast;

import org.antlr.runtime.tree.CommonTree;
import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;

public abstract class AbstractNode extends CommonTree{
    @SuppressWarnings("unchecked")
    public abstract <T extends AbstractNode> T getDuplicate();

    public AbstractNode(){ super(); }
    public AbstractNode(Token t){ super(t); }
    public AbstractNode(AbstractNode n){ super(n); }
}
