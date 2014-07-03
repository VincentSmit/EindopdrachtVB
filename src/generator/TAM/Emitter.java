package generator.TAM;

public class Emitter{
    // Used to determine at which position on the stack a variable is kept.
    private String label;
    private String comment;
    private int labelLength = 25;

    public Emitter(){}
    public Emitter(int labelLength){
        this.labelLength = labelLength;
    }

    /*
     * Prints code `s` formatted nicely.
     *
     * @requires: s != null
     * @ensures: this.label == null && this.comment == null;
     */
    public void emit(String s){
        // Print label
        if(label != null){
            System.out.print(label);
            for (int i=label.length(); i < labelLength; i++) System.out.print(' ');
        } else {
            for (int i=0; i < labelLength; i++) System.out.print(' ');
        }

        // Print command
        System.out.print(s);

        // Print comment
        if (comment != null){
            for (int i=s.length(); i < 30; i++) System.out.print(' ');
            System.out.print("; ");
            System.out.print(comment);
        }

        this.comment = null;
        this.label = null;
        System.out.println("");
    }

    /*
     * Prints code `s` formatted nicely according to emit(String).
     *
     * @requires: s != null
     * @ensures: this.label == null && this.comment == null;
     */
    public void emit(String s, String comment){
        this.comment = comment;
        emit(s);
    }

    /*
     * Set label property for following emit() call.
     *
     * @requires: s != null
     * @ensures: this.label != null
     */
    public void emitLabel(String s, int ix){
        emitLabel(s, ((Integer)ix).toString());
    }

    public void emitLabel(String s){
        if (this.label != null){
            // A label was already defined. Do a NOP and add an extra label on next line.
            emit("PUSH 0", "NOP for secondary label");
        }

        this.label = s + ":";
    }

    public void emitLabel(String s1, String s2){
        emitLabel(String.format("%s%s", s1, s2));
    }

    public void emitLabel(String s1, String s2, String s3){
        emitLabel(String.format("%s%s%s", s1, s2, s3));
    }

}