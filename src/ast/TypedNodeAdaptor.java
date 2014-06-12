package ast;

import org.antlr.runtime.tree.CommonTreeAdaptor;
import org.antlr.runtime.tree.CommonTree;
import org.antlr.runtime.Token;

public class TypedNodeAdaptor extends CommonTreeAdaptor{
    public Object create(Token t){
        return new TypedNode(t);
    }

    @Override
    public Object dupNode(Object i){
        Object n = super.dupNode((CommonTree)i);
        ((TypedNode)n).setExprType(((TypedNode)i).getExprType());
        return n;
    }
}
