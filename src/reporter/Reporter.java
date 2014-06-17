package reporter;

import ast.InvalidTypeException;
import org.antlr.runtime.tree.CommonTree;
import java.io.StringWriter;

public class Reporter{
    boolean report;
    String[] source;

    public Reporter(boolean report, String source){
        this.report = report;
        this.source = source.split("\n");
    }

    public void log(String s){
        if (report) System.out.println(s);
    }

    /*
     * Returns string with pointer to current node `n`.
     *
     * For example, it returns:
     *    on line 3, char 2:
     *       a+b
     *        ^
     */
    public String pointer(CommonTree n){
        StringWriter pointer = new StringWriter();

        pointer.write(String.format(
            "on line %s, char %s:\n", n.getLine(), n.getCharPositionInLine() + 1
        ));

        pointer.write("   ");
        pointer.write(source[n.getLine() - 1]);
        pointer.write('\n');
        pointer.write("   ");

        for (int i=0; i < n.getCharPositionInLine(); i++){
            pointer.write(' ');
        }

        pointer.write('^');
        pointer.write('\n');

        return pointer.toString();
    }

    public void error(CommonTree n, String msg) throws InvalidTypeException{
        throw new InvalidTypeException(String.format("%s%s\n", pointer(n), msg));
    }
}