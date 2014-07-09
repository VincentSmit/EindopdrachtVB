package ast;

import java.lang.Exception;
import org.antlr.runtime.RecognitionException;

/**
 * InvalidTypeException is the default exception class for failures within the
 * checker. It is caught by Grammar.java, which displays the set message by
 * calling getMessage().
 */
public class InvalidTypeException extends RecognitionException{
    private String msg;

    public InvalidTypeException(String message){
        super();
        this.msg = message;
    }

    /**
     * @returns message displayed on screen when parsing / checking fails.
     */
    public String getMessage(){
        return this.msg;
    }
}
