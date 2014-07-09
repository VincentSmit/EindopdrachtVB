package ast;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;
import org.javatuples.Pair;
import org.javatuples.Tuple;

/**
 * An IdentifierNode is a node which refers to a, sigh, identifier. Naturally, it contains
 * the scope it is defined in, and a reference to the node which holds its inception. Consider
 * the following example:
 *
 * func a{  // I
 *   a();   // II
 * }
 *
 * I:  Declaration of a. It is a TypedNode with its 'realNode' being null.
 * II: Usage of a. It is a TypedNode which 'realNode' points to I.
 */
@SuppressWarnings("unchecked")
public class IdentifierNode extends TypedNode{
    public FunctionNode scope;

    /**
     * Points to another IdentifierNode which it considers its 'realNode'. The
     * existence of this property is a bit unfortunate, but necessary as we cannot
     * override $id.tree in GrammarChecker.
     */
    public IdentifierNode realNode;

    public IdentifierNode(){ super(); }
    public IdentifierNode(Token t){ super(t); }
    public IdentifierNode(CommonNode n){ super(n); }

    /**
     * Copies given node.
     *
     * @ensures this.scope == n.scope && this.realNode == n.realNode
     */
    public IdentifierNode(IdentifierNode n) {
        super(n);
        this.scope = n.scope;
        this.realNode = n.realNode;
    }

    /**
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

    /**
     * Returns duplicate of current node. Used by dupNode().
     */
    public IdentifierNode getDuplicate(){
        return new IdentifierNode(this);
    }

    /**
     * Returns scope property of getRealNode().
     */
    public FunctionNode getScope(){
        return this.getRealNode().scope;
    }

    /**
     * Sets scope property on getRealNode()
     */
    public void setScope(FunctionNode scope){
        this.getRealNode().scope = scope;
    }

    /**
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

    /**
     * Sets realNode property
     *
     * @requires node != null
     * @ensures this.getRealNode() is node.getRealNode()
     */
    public void setRealNode(IdentifierNode node){ this.realNode = node.getRealNode(); }

    /**
     * Same as super, but gets property off getRealNode()
     */
    @Override
    public Type getExprType(){
        return this.getRealNode().exprType;
    }

    /**
     * Same as super, but sets property on getRealNode()
     */
    @Override
    public void setExprType(Type type) {
        this.getRealNode().exprType = type;
    }

    /**
     * Same as super, but sets property on getRealNode()
     */
    @Override
    public void setExprType(Type.Primitive prim){
        this.getRealNode().setExprType(new Type(prim));
    }

    /**
     * Same as super, but sets property on getRealNode()
     */
    @Override
    public void setExprType(TypedNode node){
        this.getRealNode().setExprType(node.getExprType());
    }

    /**
     * Same as super, but sets property on getRealNode()
     */
    @Override
    public void setMemAddr(Pair<Integer, Integer> p){
        this.getRealNode().memAddr = p;
    }

    /**
     * Same as super, but gets property off getRealNode()
     */
    @Override
    public Pair getMemAddr(){
        return this.getRealNode().memAddr;
    }
}
