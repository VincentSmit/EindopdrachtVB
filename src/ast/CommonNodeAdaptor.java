package ast;

import org.antlr.runtime.tree.CommonTreeAdaptor;
import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;

public class CommonNodeAdaptor extends CommonTreeAdaptor{
    @Override
    public Object dupNode(Object i){
        return ((CommonNode)i).dupNode();
    }

    @Override
    public Object nil(){
        return new CommonNode();
    }

    @Override
    public Object create(Token payload) {
        return new CommonNode(payload);
    }

    /** What is the Token associated with this node? */
    @Override
    public Token getToken(Object t) {
        return ((CommonNode)t).getToken();
    }
}
