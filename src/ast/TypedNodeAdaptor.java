package ast;

import org.antlr.runtime.tree.CommonTreeAdaptor;
import org.antlr.runtime.Token;

public class TypedNodeAdaptor extends CommonTreeAdaptor{
    public Object create(Token t){
        return new TypedNode(t);
    }
}