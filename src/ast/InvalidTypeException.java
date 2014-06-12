package ast;

import java.lang.Exception;
import org.antlr.runtime.RecognitionException;

public class InvalidTypeException extends RecognitionException{
    private String msg;

    public InvalidTypeException(String message){
        super();
        this.msg = message;
    }

    public String getMessage(){
        return this.msg;
    }
}