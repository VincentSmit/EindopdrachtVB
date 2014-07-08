package ast;

import org.antlr.runtime.Token;
import org.antlr.runtime.CommonToken;
import org.antlr.runtime.RecognitionException;
import org.javatuples.Pair;
import org.javatuples.Tuple;

/**
 * A typed node is a node which holds a type. For example: an expression or identifier. Almost
 * all other nodes inherit from it.
 */
@SuppressWarnings("unchecked")
public class TypedNode extends CommonNode{
    // Type of expression
    protected Type exprType;

    // Relative memory address on which this node resides. The first value of the tuple
    // indicates its global scope level, the second it level relative to it. For example:
    //
    // func x{
    //    int a;
    //
    //    func y{
    //       int b;
    //       int c;
    //    }
    // }
    //
    // x: (0, -1)
    // a: (1, 0)
    // y: (1, -1)
    // b: (1, 0)
    // c: (1, 1)
    protected Pair<Integer, Integer> memAddr;

    public TypedNode(){ super(); }
    public TypedNode(Token t){ super(t); }
    public TypedNode(CommonNode n){ super(n); }

    /**
     * Copy node 'n'. Makes shallow copies of exprType and memAddr.
     *
     * @ensures: getExprType() == n.getExprType() && getMemAddr() == n.memAddr;
     */
    public TypedNode(TypedNode n) {
        super(n);
        this.exprType = n.getExprType();
        this.memAddr = n.memAddr;
    }


    /**
     * Returns duplicate of current node. Used by dupNode().
     */
    public TypedNode getDuplicate(){
        return new TypedNode(this);
    }

    /**
     * Get exprType property.
     */
    public Type getExprType() {
        return exprType;
    }

    /**
     * Set exprType property.
     *
     * @ensures: getExprType() == type
     * @requires: type != null
     */
    public void setExprType(Type type) {
        this.exprType = type;
    }

    /**
     * Convenience function: wraps given primitive in Type object and sets
     * it as exprType.
     *
     * @requires: prim != null
     * @ensures: getExprType().getPrimType() == prim
     */
    public void setExprType(Type.Primitive prim){
        this.setExprType(new Type(prim));
    }

    /**
     * Convenience function: extracts expression type of node, and sets it
     * for this function.
     *
     * @ensures: node.getExprType() == getExprType()
     * @requires: node != null
     */
    public void setExprType(TypedNode node){
        this.setExprType(node.getExprType());
    }

    /**
     * Sets property memAddr
     *
     * @ensures: getMemAddr() == p
     * @requires: p != null
     */
    public void setMemAddr(Pair<Integer, Integer> p){
        this.memAddr = p;
    }

    /**
     * Get memAddr property
     */
    public Pair getMemAddr(){
        return this.memAddr;
    }
}