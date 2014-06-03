package ast;

import org.antlr.runtime.tree.CommonTreeAdaptor;
import org.antlr.runtime.Token;

public class ExprNodeAdaptor extends CommonTreeAdaptor{
    public Object create(Token t){
        return new ExprNode(t);
    }
}