package generator.TAM;

import ast.FunctionNode;
import ast.TypedNode;
import ast.IdentifierNode;
import ast.Type;

import generator.Utils;

/**
 * Helper class for generating function specific TAM code.
 */
public class Function{
    private GrammarTAM generator;
    private Emitter emitter;

    public Function(GrammarTAM generator, Emitter emitter){
        this.generator = generator;
        this.emitter = emitter;
    }

    /**
     * This method:
     *  1. Generates label at start of function
     *  2. Generates a jump instruction which jumps over function
     *  3. Pushes empty space on stack for variables
     *  4. Registers new scope on 'generator'
     *
     * @ensures generator.funcs.size() + 1 == old.generator.funcs.size()
     * @requires generator != null && generator.funcs != null && f != null
     * @param f function to prepare
     */
    public void enter(FunctionNode f){
        if(f.getMemAddr().getValue0() != 0){
            // We're not the root note, so we need to make sure the TAM interpreter
            // skips this function while executing the code.
            emitter.emit(String.format("JUMP %safter[CB]", f.getFullName()));
        }

        emitter.emitLabel(f.getFullName());
        generator.funcs.push(f);

        if (f.getVars().size() > 0){
            emitter.emit(String.format("PUSH %s", f.getVars().size()));
        }
    }

    /**
     * This method:
     *   1. Deallocate all ('static') arrays of this function
     *   2. Emit label at end of function
     *   3. Deregisters this scope on generator.
     *
     * @ensures generator.funcs.size() - 1 == old.generator.funcs.size()
     * @requires generator != null && generator.funcs != null && f != null
     * @requires generator.funcs.size() >= 1
     * @param func function to deprepare
     */
    public void exit(FunctionNode func){
        // Deallocate all arrays. Yes, I know this is O(n) with n being the amount
        // of variables in this function. We could keep an extra list for arrays
        // only, but this is even uglier IMO.
        for (TypedNode node : generator.funcs.peek().getVars()){
            if (node.getExprType().getPrimType() == Type.Primitive.ARRAY){
                emitter.emit("LOADA " + generator.addr((IdentifierNode)node), node.getText());
                emitter.emit("LOADI(1)", "Load heap pointer to array");
                emitter.emit("CALL (L1) free[CB]", "Freeeedooooooom");
                emitter.emit("POP(1) 0", "Pop useless call result");
            }
        };

        emitter.emitLabel(func.getFullName(), "after");
        generator.funcs.pop();
    }
}