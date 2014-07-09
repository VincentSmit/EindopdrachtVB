package generator;

import ast.IdentifierNode;
import ast.FunctionNode;

public class Utils{
    /**
     * Helper function of register(). Determines register based on current lookupScopeLevel
     * and a difference between identifier and scope.
     *
     * @requires: diff <= 6
     * @return: one of {"LB", "SB", "L1" .. "L2"}
     */
    public static String register(int lookupScopeLevel, int diff){
        String base = "LB"; // Local base
        if (diff == 6 || lookupScopeLevel == 0){
            // Declared as global, so we need to fetch it from stack base
            base = "SB";
        } else if (diff > 0){
            // Declared in one of enclosing functions, so we need to use
            // pseudoregisters L1, L2 ... L6.
            base = "L" + diff;
        }

        return base;
    }

    /**
     * Returns base in which 'inode' is registered, relative to the current scope. The following example
     * illustrates the workings:
     *
     *    var i;
     *    func a{
     *       var j;
     *       func b{
     *          var k;
     *          lookup i; // I
     *          lookup j; // II
     *       }
     *    }
     *
     * I:  would result in "SB", and called as register(b, i);
     * II: would result in "L1", and called as register(b, j);
     *
     * @requires: difference of levels <= 6 (forced by parser)
     * @param scope: scope in which identifier is looked up
     * @param inode: identifier which has to be resolved
     * @return: one of {"LB", "SB", "L1" .. "L2"}
     */
    public static String register(FunctionNode scope, IdentifierNode inode){
        int lookupScopeLevel = (Integer)scope.getMemAddr().getValue0();
        int idScopeLevel = (Integer)inode.getRealNode().getMemAddr().getValue0();
        int diff = lookupScopeLevel - idScopeLevel;
        return register(lookupScopeLevel, diff);

   }

    /**
     * Determines memory address of identifier, given a scope and identifier.
     *
     * @return: String formatted as {offset:int}[{base:string}]
     */
    public static String addr(FunctionNode scope, IdentifierNode id){
        return String.format("%s[%s]", id.getRealNode().getMemAddr().getValue1(), register(scope, id));
    }
}