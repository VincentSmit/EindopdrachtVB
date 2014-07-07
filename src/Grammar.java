import java.io.FileInputStream;
import java.io.InputStream;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.EnumSet;
import java.util.Set;
import java.util.Scanner;

import org.antlr.runtime.ANTLRInputStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.tree.BufferedTreeNodeStream;
import org.antlr.runtime.tree.CommonTree;
import org.antlr.runtime.tree.CommonTreeNodeStream;
import org.antlr.runtime.tree.DOTTreeGenerator;
import org.antlr.runtime.tree.TreeNodeStream;
import org.antlr.stringtemplate.StringTemplate;

import reporter.Reporter;
import checker.GrammarChecker;
import generator.TAM.GrammarTAM;
import ast.InvalidTypeException;
import ast.CommonNodeAdaptor;
import ast.FunctionNode;

/**
* Program that creates and starts the Grammar lexer, parser, etc.
* @author Theo Ruys
* @version 2009.05.01
*/
public class Grammar {
    private static final Set<Option> options = EnumSet.noneOf(Option.class);
    private static String inputFile;

    public static void parseOptions(String[] args) {
        if (args.length == 0) {
            System.err.println(USAGE_MESSAGE);
            System.exit(1);
        }
        for (int i=0; i<args.length; i++) {
            try {
                Option option = getOption(args[i]);
                if (option == null) {
                    if (i < args.length - 1) {
                        System.err.println("Input file name '%s' should be last argument");
                        System.exit(1);
                    } else {
                        inputFile = args[i];
                    }
                } else {
                    options.add(option);
                }
            } catch (IllegalArgumentException exc) {
                System.err.println(exc.getMessage());
                System.err.println(USAGE_MESSAGE);
                System.exit(1);
            }
        }
    }

    public static void main(String[] args) {
        parseOptions(args);

        try {
            // Setup I/O sources
            InputStream in = inputFile == null ? System.in : new FileInputStream(inputFile);
            String source = (new Scanner(in).useDelimiter("\\A")).next();
            Reporter reporter = new Reporter(options.contains(Option.REPORT), source);

            // Parse tokens through lexer and tokenizer
            GrammarLexer lexer = new GrammarLexer(new ANTLRInputStream(
                new ByteArrayInputStream(source.getBytes(StandardCharsets.UTF_8)))
            );
            CommonTokenStream tokens = new CommonTokenStream(lexer);

            // Parse tokens as tree
            GrammarParser parser = new GrammarParser(tokens);
            parser.setTreeAdaptor(new CommonNodeAdaptor());
            GrammarParser.program_return result = parser.program();

            // Print parsed AST
            CommonTree tree = (CommonTree) result.getTree();
            if (options.contains(Option.AST)) {
                if (!options.contains(Option.NEWLINES)){
                    System.out.println(tree.toStringTree().replace("\n", "\\n"));
                } else {
                    System.out.println(tree.toStringTree());
                }

                // Allow operating system to print to console (because flush()
                // doesn't work..)
                try {
                    Thread.sleep(50);
                } catch(InterruptedException ex) {
                    Thread.currentThread().interrupt();
                }
            }

            // Decorate tree with types
            if (!options.contains(Option.NO_CHECKER)) {
                CommonTreeNodeStream nodes = new CommonTreeNodeStream(new CommonNodeAdaptor(), tree);
                GrammarChecker checker = new GrammarChecker(nodes);
                checker.setTreeAdaptor(new CommonNodeAdaptor());
                checker.setReporter(reporter);
                tree = checker.program().getTree();
            }

            // Generate TAM code
            if (options.contains(Option.TAM)){
                if (options.contains(Option.NO_CHECKER)){
                    System.err.println("You can't use both -no_checker and -tam.");
                    return;
                }

                CommonTreeNodeStream nodes = new CommonTreeNodeStream(new CommonNodeAdaptor(), tree);
                GrammarTAM tam = new GrammarTAM(nodes);
                tam.program();
                return;
            }

            // Generate Python bytecode
            // Not yet :)

        } catch (RecognitionException e) {
            System.err.print("ERROR: recognition exception thrown by compiler ");
            System.err.println(e.getMessage());
            e.printStackTrace();
        } catch (Exception e) {
            System.err.print("ERROR: uncaught exception thrown by compiler: ");
            System.err.println(e.getMessage());
            e.printStackTrace();
        }
    }

    private static Option getOption(String text) throws IllegalArgumentException {
        if (!text.startsWith(OPTION_PREFIX)) {
            return null;
        }
        String stripped = text.substring(OPTION_PREFIX.length());
        for (Option option: Option.values()) {
            if (option.getText().equals(stripped)) {
                return option;
            }
        }
        throw new IllegalArgumentException(String.format("Illegal option value '%s'", text));
    }

    private static final String USAGE_MESSAGE;

    static {
        StringBuilder message = new StringBuilder("Usage:");
        for (Option option: Option.values()) {
            message.append(" [");
            message.append(option.getText());
            message.append("]");
        }
        message.append(" [filename]");
        USAGE_MESSAGE = message.toString();
    }

    private static enum Option {
        DOT,
        AST,
        NO_CHECKER,
        NO_INTERPRETER,
        REPORT,
        NEWLINES,
        TAM;

        private Option() {
            this.text = name().toLowerCase();
        }

        /** Returns the option text of this option. */
        public String getText() {
            return this.text;
        }

        private final String text;
    }

    private static final String OPTION_PREFIX = "-";
}
