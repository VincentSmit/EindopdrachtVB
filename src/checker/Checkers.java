package checker;

import ast.TypedNode;
import ast.CommonNode;
import ast.Type;
import ast.Type.Primitive;
import ast.InvalidTypeException;

/**
 * Helper class which holds checks commonly executed on types.
 */
public class Checkers{
    private GrammarChecker checker;

    public Checkers(GrammarChecker checker){
        this.checker = checker;
    }

    /**
     * Compare two nodes for their equality. If the types do not match, throw an error
     * through reporter. If one of the node has type "AUTO", we will assume the type
     * of the other node.
     *
     * @param op: 'parent' expression which needs it's type set, and to report an error on
     * @param tn1: left-side of op
     * @param tn2: right-side of op
     */
    public void equal(CommonNode op, TypedNode tn1, TypedNode tn2) throws InvalidTypeException{
        // If one of the typednodes has type auto, assume type of other typednode.
        if(tn1.getExprType().getPrimType().equals(Type.Primitive.AUTO)){
            tn1.setExprType(tn2.getExprType());
        } else if(tn2.getExprType().getPrimType().equals(Type.Primitive.AUTO)){
            tn2.setExprType(tn1.getExprType());
        }

        // Check equality and throw error if not equal
        if(!(tn1.getExprType().equals(tn2.getExprType()))){
            checker.reporter.error(op, "Expected operands to be of same type. Found: " +
            tn1.getExprType() + " and " + tn2.getExprType() + ".");
        }

        // Set expression of op.
        ((TypedNode)op).setExprType(tn1.getExprType());
    }

    /**
     * Check for the existence of a symbol stored under 'symbolName'. If it does not exist,
     * throw an error on 'op', stating the user might need to import 'module'.
     *
     * @param op: node to report error on
     * @param symbolName: symbol to check existence of
     * @param module: if symbol does not exist, which module needs to be imported?
     */
    public void symbol(CommonNode op, String symbolName, String module) throws InvalidTypeException{
        if(checker.symtab.retrieve(symbolName) == null){
            checker.reporter.error(op, String.format("Could not find %s(). Did you import '%s'?", symbolName, module));
        }
    }

    /**
     * Check 'op' for 'type'. If it does not match, report error through reporter with 'message'.
     */
     public void type(TypedNode op, Type type, String message) throws InvalidTypeException{
        if (!op.getExprType().equals(type)){
            checker.reporter.error(op, message);
        }
     }

    /**
     * Check 'op' for 'type'. If it does not match, report error through reporter with
     * generic error message.
     */
     public void type(TypedNode op, Type type) throws InvalidTypeException{
        type(op, type, String.format("Found: %s. Expected: %s.", op.getExprType(), type));
     }

    /**
     * Check 'op' for 'type'. If it does not match, report error through reporter with
     * generic error message.
     */
     public void type(TypedNode op, Primitive type, String message) throws InvalidTypeException{
        if(op.getExprType().getPrimType() != type){
            checker.reporter.error(op, message);
        }
     }

    /**
     * Check 'op' for 'type'. If it does not match, report error through reporter with
     * generic error message.
     */
     public void type(TypedNode op, Primitive type) throws InvalidTypeException{
        type(op, type, String.format("Found: %s. Expected: %s.", op.getExprType().getPrimType(), type));
     }


    /**
     * Check 'op' for 'type'. If it does not match, report error through reporter with 'message'.
     */
     public void typeEQ(TypedNode op, Type type, String message) throws InvalidTypeException{
        if (op.getExprType().equals(type)){
            checker.reporter.error(op, message);
        }
     }

    /**
     * Check 'op' for 'type'. If it does not match, report error through reporter with
     * generic error message.
     */
     public void typeEQ(TypedNode op, Type type) throws InvalidTypeException{
        typeEQ(op, type, String.format("Did not expect: %s.", op.getExprType()));
     }

    /**
     * Check 'op' for 'type'. If it does not match, report error through reporter with
     * generic error message.
     */
     public void typeEQ(TypedNode op, Primitive type, String message) throws InvalidTypeException{
        if(op.getExprType().getPrimType() == type){
            checker.reporter.error(op, message);
        }
     }

    /**
     * Check 'op' for 'type'. If it does not match, report error through reporter with
     * generic error message.
     */
     public void typeEQ(TypedNode op, Primitive type) throws InvalidTypeException{
        typeEQ(op, type, String.format("Did not expect: %s.", op.getExprType().getPrimType()));
     }


}