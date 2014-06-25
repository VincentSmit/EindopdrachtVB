package ast;

import org.antlr.runtime.tree.CommonTreeAdaptor;
import org.antlr.runtime.Token;

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
}
