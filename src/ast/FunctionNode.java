package ast;

import java.util.List;
import java.util.ArrayList;
import org.antlr.runtime.Token;

/*
 * A function node contains a list of argument it takes as IdentifierNodes pointing
 * to the .
 */
@SuppressWarnings("unchecked")
public class FunctionNode extends IdentifierNode{
    public List<TypedNode> vars;
    public List<IdentifierNode> args;

    public String name;
    public Type returnType;

    public FunctionNode(CommonNode n){
        super(n);
        this.vars = new ArrayList<TypedNode>();
        this.args = new ArrayList<IdentifierNode>();
    }

    public FunctionNode(Token t){
        super(t);
        this.vars = new ArrayList<TypedNode>();
        this.args = new ArrayList<IdentifierNode>();
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
    public List<IdentifierNode> getArgs(){ return this.args; }

    /*
     * Returns unique name including their parents, which can be used as a unique
     * name for this function inside a program.
     */
    public String getFullName(){
        if (this.getName().equals("__root__"))
            return this.getName();

        String fullName = this.getName();
        FunctionNode f = this.getScope();
        while (!f.getName().equals("__root__")){
            fullName = String.format("%s_%s", f.getName(), fullName);
            f = this.getScope();
        }

        return fullName;
    }
}
