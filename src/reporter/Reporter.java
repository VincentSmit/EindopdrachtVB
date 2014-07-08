package reporter;

import ast.InvalidTypeException;
import org.antlr.runtime.tree.CommonTree;
import java.io.StringWriter;

/**
 * Reporter is a helper class which helps to throw (descriptive) errors and logs. Its to
 * main functions are log() and error().
 *
 * TODO: Incorporate imported files.
 */
public class Reporter{
    boolean report;
    String[] source;

    /**
     * @param report: enable reporting. If false, every call to log() does nothing.
     * @param source: source code of program
     */
    public Reporter(boolean report, String source){
        this.report = report;
        this.source = source.split("\n");
    }

    /**
     * Print 's' to stdout.
     *
     * @param s: string to print
     * @requires s: s != null
     */
    public void log(String s){
        if (report) System.out.println(s);
    }

    /**
     * Returns string with pointer to current node `n`.
     *
     * For example, it returns:
     *    on line 3, char 2:
     *       a+b
     *        ^
     *
     * @requires: n != null
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

    /**
     * Throw an error with line number and character count. See log() for more information.
     *
     * @param n: node which causes an error
     * @param msg: custom message which will be shown alongside 'traceback'
     */
    public void error(CommonTree n, String msg) throws InvalidTypeException{
        throw new InvalidTypeException(String.format("%s%s\n", pointer(n), msg));
    }
}