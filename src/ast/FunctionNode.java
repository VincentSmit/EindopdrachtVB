package ast;

import java.util.List;
import java.util.ArrayList;
import org.antlr.runtime.Token;

/*
 * A function node contains a list of argument it takes as TypedNodes pointing
 * to the .
 */
@SuppressWarnings("unchecked")
public class FunctionNode extends TypedNode{
    public List<TypedNode> vars;
    public List<TypedNode> args;

    public TypedNode idNode;
    public String name;
    public FunctionNode parent;

    public FunctionNode(CommonNode n){
        super(n);
        this.vars = new ArrayList<TypedNode>();
        this.args = new ArrayList<TypedNode>();
    }

    public FunctionNode(Token t){
        super(t);
        this.vars = new ArrayList<TypedNode>();
        this.args = new ArrayList<TypedNode>();
    }

    public FunctionNode(FunctionNode n){
        super(n);
        this.vars = new ArrayList<TypedNode>();

        this.vars.addAll(n.vars);
        this.args.addAll(n.args);
        this.idNode = n.idNode;
        this.name = n.name;
        this.parent = n.parent;
    }

    public FunctionNode getDuplicate(){
        return new FunctionNode(this);
    }

    public String getName(){ return this.name; }
    public void setName(String name){
        this.name = name;
    }

    public List<TypedNode> getVars(){ return this.vars; }
    public List<TypedNode> getArgs(){ return this.args; }

    public FunctionNode getParent(){ return this.parent; }
    public void setParent(FunctionNode parent){
        this.parent = parent;
    }

}