package ast;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;
import org.javatuples.Pair;
import org.javatuples.Tuple;

/*
 *
 */
@SuppressWarnings("unchecked")
public class IdentifierNode extends TypedNode{
    public FunctionNode scope;

    /*
     * Points to another IdentifierNode which it considers its 'realNode'. The
     * existence of this property is a bit unfortunate, but necessary as we cannot
     * override $id.tree in GrammarChecker.
     */
    public IdentifierNode realNode;

    public IdentifierNode(){ super(); }
    public IdentifierNode(Token t){ super(t); }
    public IdentifierNode(CommonNode n){ super(n); }

    /*
     * @ensures: this.scope == n.scope && this.realNode == n.realNode
     */
    public IdentifierNode(IdentifierNode n) {
        super(n);
        this.scope = n.scope;
        this.realNode = n.realNode;
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
     *    -> ... IDENTIFIER<IdentifierNode>["auto"] ...
     *
     * This executes the constructor of TypedNode with types 'int'
     * and 'String' according to CommonToken.
     */
     public IdentifierNode(Integer type, String text) throws RecognitionException{
        super(type, text);
    }

    public IdentifierNode getDuplicate(){
        return new IdentifierNode(this);
    }

    public FunctionNode getScope(){
        return this.getRealNode().scope;
    }

    public void setScope(FunctionNode scope){
        this.getRealNode().scope = scope;
    }

    /*
     * Traverses tree of n.getRealNode() calls until it finds a call which returns
     * null. It then returns `n`.
     *
     * @ensures retval != null
     */
    public IdentifierNode getRealNode(){
        IdentifierNode n = this;

        while (n.realNode != null){
            n = n.realNode;
        }

        return n;
    }

    /*
     * Sets realNode property
     *
     * @requires: node != null
     * @ensures: this.getRealNode() is node.getRealNode()
     */
    public void setRealNode(IdentifierNode node){ this.realNode = node.getRealNode(); }

    @Override
    public Type getExprType(){
        return this.getRealNode().exprType;
    }

    @Override
    public void setExprType(Type type) {
        this.getRealNode().exprType = type;
    }

    @Override
    public void setExprType(Type.Primitive prim){
        this.getRealNode().setExprType(new Type(prim));
    }

    @Override
    public void setExprType(TypedNode node){
        this.getRealNode().setExprType(node.getExprType());
    }

    @Override
    public void setMemAddr(Pair<Integer, Integer> p){
        this.getRealNode().memAddr = p;
    }

    @Override
    public Pair getMemAddr(){
        return this.getRealNode().memAddr;
    }
}
