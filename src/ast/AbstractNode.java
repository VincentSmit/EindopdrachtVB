package ast;

import org.antlr.runtime.tree.CommonTree;
import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;

/**
 * Abstract node needs to exist, as we cannot define getDuplicate() on a
 * non-abstract node.
 */
public abstract class AbstractNode extends CommonTree{
    /**
     * Returns a duplicate of the current node. Its abstract nature allows subclasses to
     * implement it, dupeNode (internal method of antlr) to use it and make the Java compiler
     * happy.
     */
    @SuppressWarnings("unchecked")
    public abstract <T extends AbstractNode> T getDuplicate();

    public AbstractNode(){ super(); }
    public AbstractNode(Token t){ super(t); }
    public AbstractNode(AbstractNode n){ super(n); }
}
