package generator.TAM;

/**
 * Emitter is a helper class for generating TAM code. It allows easy emitting of labels
 * and formatting of code and comments.
 */
public class Emitter{
    // Used to determine at which position on the stack a variable is kept.
    private String label;
    private String comment;
    private int labelLength = 25;

    public Emitter(){}

    /**
     * @param labelLength: characters reserved for labeling
     */
    public Emitter(int labelLength){
        this.labelLength = labelLength;
    }

    /**
     * Prints code `s` formatted nicely. If this.label is set, it will be prepended
     * to the code. Example output (stdout):
     *
     * func_label:      PUSH 3     ; Initialise arguments of test()
     * ^label           ^code        ^comment
     *
     * @requires: code != null
     * @ensures: this.label == null && this.comment == null;
     */
    public void emit(String code){
        // Print label
        if(label != null){
            System.out.print(label);
            for (int i=label.length(); i < labelLength; i++) System.out.print(' ');
        } else {
            for (int i=0; i < labelLength; i++) System.out.print(' ');
        }

        // Print command
        System.out.print(code);

        // Print comment
        if (comment != null){
            for (int i=code.length(); i < 30; i++) System.out.print(' ');
            System.out.print("; ");
            System.out.print(comment);
        }

        this.comment = null;
        this.label = null;
        System.out.println("");
    }

    /**
     * Prints code `s` formatted nicely according to emit(String). This adds an additional
     * comment at the end of the emitted code.
     *
     * @param s: code to be emitted
     * @param comment: comment to help read emitted code
     * @requires: s != null
     * @ensures: this.label == null && this.comment == null;
     */
    public void emit(String s, String comment){
        this.comment = comment;
        emit(s);
    }

    /**
     * Set label property for following emit() call.
     *
     * @requires: s != null
     * @ensures: this.label != null
     */
    public void emitLabel(String s, int ix){
        emitLabel(s, ((Integer)ix).toString());
    }

    /**
     * Set label property for following emit() call.
     *
     * @requires: s != null
     * @ensures: this.label != null
     */
    public void emitLabel(String s){
        if (this.label != null){
            // A label was already defined. Do a NOP and add an extra label on next line.
            emit("PUSH 0", "NOP for secondary label");
        }

        this.label = s + ":";
    }

    /**
     * Set label property for following emit() call.
     *
     * @requires: s1 != null && s2 != null
     * @ensures: this.label != null
     */
    public void emitLabel(String s1, String s2){
        emitLabel(String.format("%s%s", s1, s2));
    }

    /**
     * Set label property for following emit() call.
     *
     * @requires: s1 != null && s2 != null && s3 != null
     * @ensures: this.label != null
     */
    public void emitLabel(String s1, String s2, String s3){
        emitLabel(String.format("%s%s%s", s1, s2, s3));
    }

}