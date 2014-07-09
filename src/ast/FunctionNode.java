package ast;

import java.util.List;
import java.util.ArrayList;
import org.antlr.runtime.Token;

/**
 * A function has three special properties: it's arguments, variables (which most
 * likely need to be initialised at the start of calling it), return type and name.
 */
@SuppressWarnings("unchecked")
public class FunctionNode extends IdentifierNode{
    // Variables declared in this function (might also include implicitly declared
    // strings, arrays or characters).
    public List<TypedNode> vars;

    // Arguments which need to be passed to this function
    public List<IdentifierNode> args;

    // Non-qualified name of function.
    public String name;

    // Return type of this function
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

    /**
     * Copies given function node by copying the pointers to 'args', 'vars' and
     * 'returnType'. Thus nodes added to vars / args on an 'old' node changes the
     * lists on the 'new' node also.
     */
    public FunctionNode(FunctionNode n){
        super(n);

        this.vars = n.vars;
        this.args = n.args;
        this.name = n.name;
        this.returnType = n.returnType;
    }

    /**
     * Returns duplicate of current node. Used by dupNode().
     */
    public FunctionNode getDuplicate(){
        return new FunctionNode(this);
    }

    /**
     * Returns name property
     */
    public String getName(){ return this.name; }

    /**
     * Sets name property.
     *
     * @requires name != null
     * @ensures this.getName() == name
     */
    public void setName(String name){
        this.name = name;
    }

    /**
     * Get returnType property
     */
    public Type getReturnType(){
        return ((FunctionNode)this.getRealNode()).returnType;
    }

    /**
     * Set returnType property
     *
     * @requires type != null
     * @ensures getReturnType() == type
     */
    public void setReturnType(Type type){
        ((FunctionNode)this.getRealNode()).returnType = type;
    }

    /**
     * Get vars property
     */
    public List<TypedNode> getVars(){ return this.vars; }

    /**
     * Get args property
     */
    public List<IdentifierNode> getArgs(){ return this.args; }

    /**
     * Returns qualified name including their parents, which can be used as a unique
     * name for this function inside a program.
     *
     * TODO: Allow for imported programs. As of now, this may create collisions.
     *
     * @ensures retval != null && retval.length() >= 1
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
