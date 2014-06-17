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

    public void error(CommonTree n, String msg) throws InvalidTypeException{
        StringWriter err = new StringWriter();
        err.write(String.format(
            "on line %s, char %s:\n", n.getLine(), n.getCharPositionInLine() + 1
        ));

        err.write("   ");
        err.write(source[n.getLine() - 1]);
        err.write('\n');
        err.write("   ");

        for (int i=0; i < n.getCharPositionInLine(); i++){
            err.write(' ');
        }

        err.write('^');
        err.write('\n');
        err.write(msg);
        err.write('\n');

        throw new InvalidTypeException(err.toString());
    }
}