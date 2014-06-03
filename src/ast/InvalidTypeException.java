package ast;

import java.lang.Exception;

public class InvalidTypeException extends Exception {
    public InvalidTypeException(String message){
        super(message);
    }
}