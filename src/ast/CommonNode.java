package ast;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;

@SuppressWarnings("unchecked")
public class CommonNode extends AbstractNode{
    // Size of instruction
    public int size = 1;

    public CommonNode(){ super(); }
    public CommonNode(int t){ super(new CommonToken(t)); }
    public CommonNode(Token t){ super(t); }
    public CommonNode(CommonNode n){ super(n); }
    public CommonNode dupNode(){
        return this.getDuplicate();
    }

    public CommonNode getDuplicate(){
        return new CommonNode(this);
    }

    /*
     * Gets size (in words) this expression takes on stack.
     */
    public int getSize(){
        return this.size;
    }

    public void setSize(int size){
        this.size = size;
    }
}