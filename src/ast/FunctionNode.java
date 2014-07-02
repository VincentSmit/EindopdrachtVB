package ast;

import java.util.List;
import java.util.ArrayList;
import org.antlr.runtime.Token;

/*
 * A function node contains a list of argument it takes as TypedNodes pointing
 * to the .
 */
@SuppressWarnings("unchecked")
public class FunctionNode extends IdentifierNode{
    public List<TypedNode> vars;
    public List<TypedNode> args;

    public String name;
    public Type returnType;

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

        this.vars = n.vars;
        this.args = n.args;
        this.name = n.name;
        this.returnType = n.returnType;
    }

    public FunctionNode getDuplicate(){
        return new FunctionNode(this);
    }

    public String getName(){ return this.name; }
    public void setName(String name){
        this.name = name;
    }

    public Type getReturnType(){
        return ((FunctionNode)this.getRealNode()).returnType;
    }

    public void setReturnType(Type type){
        ((FunctionNode)this.getRealNode()).returnType = type;
    }

    public List<TypedNode> getVars(){ return this.vars; }
    public List<TypedNode> getArgs(){ return this.args; }
}