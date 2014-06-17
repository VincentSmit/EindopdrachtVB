package ast;

public class Type {
    public enum Primitive {
        INTEGER,
        CHARACTER,
        BOOLEAN,
        ARRAY,
        AUTO,
        FUNCTION
    }

    private Primitive primType;
    private Type innerType;

    public Type(Primitive primType){
        this.primType = primType;
    }

    //Only for arrays, which have primitive type array, and
    //inner type integer, boolean or character.
    public Type(Primitive primType, Type innerType){
        this.primType = primType;
        this.innerType = innerType;
    }

    public Primitive getPrimType() {
        return primType;
    }

    public void setInnerType(Type innerType) {
        this.innerType = innerType;
    }

    public Type getInnerType() {
        return innerType;
    }

    /*
     * @param other
     */
    public boolean equals(Type other){
        boolean primEqual = this.primType != Primitive.AUTO &&
                            other.primType != Primitive.AUTO &&
                            this.primType == other.primType;

        if(this.innerType == null){
            return primEqual && other.innerType == null;
        }

        return primEqual && this.innerType.equals(other.innerType);
    }

    public boolean equals(Primitive other){
        return equals(new Type(other));
    }

    public static Primitive getPrimFromString(String type) throws InvalidTypeException{
        switch(type){
            case "int": return Primitive.INTEGER;
            case "bool": return Primitive.BOOLEAN;
            case "char": return Primitive.CHARACTER;
            case "array": return Primitive.ARRAY;
            case "auto": return Primitive.AUTO;
            default: throw new InvalidTypeException(type + " is not a specified type.");
        }
    }

    public String toString(){
        if (this.innerType == null)
            return String.format("Type<%s>", this.primType);
        return String.format("Type<%s, %s>", this.primType, this.innerType);
    }
}
