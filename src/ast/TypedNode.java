package ast;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;

@SuppressWarnings("unchecked")
public class TypedNode extends CommonNode{
    private Type exprType;

    public TypedNode(){ super(); }
    public TypedNode(Token t){ super(t); }
    public TypedNode(CommonNode n){ super(n); }
    public TypedNode(TypedNode n) {
        super(n);
        this.exprType = n.getExprType();
    }


    public TypedNode getDuplicate(){
        return new TypedNode(this);
    }

    /*
     * This is a bit of a hack. We want our users to able to type:
     *
     *    func foo(int a){ return a; }
     *
     * which should trigger the same behaviour as:
     *
     *    func foo(int a) returns auto { return a; }
     *
     * To accomplish this a rewrite rule exists in Grammar.g in te
     * following form:
     *
     *    -> ... IDENTIFIER<TypedNode>["auto"] ...
     *
     * This executes the constructor of TypedNode with types 'int'
     * and 'String' according to CommonToken.
     */
    public TypedNode(Integer type, String text) throws RecognitionException{
        super(new CommonToken(type, text));

        try{
            this.exprType = new Type(Type.getPrimFromString(text));
        } catch (InvalidTypeException e){
            // Note to programmers: this exception is only triggered if Grammar.g
            // defines a TypedNode to be made with a string which is not in
            // Type.Primitives.
            throw new RecognitionException();
        }
    }

    public Type getExprType() {
        return exprType;
    }

    public void setExprType(Type type) {
        this.exprType = type;
    }

    public void setExprType(Type.Primitive prim){
        this.setExprType(new Type(prim));
    }

    public void setExprType(TypedNode node){
        this.setExprType(node.getExprType());
    }
}