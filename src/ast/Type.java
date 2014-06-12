package ast;

public class Type {
    public enum Primitive {
        INTEGER,
        CHARACTER,
        BOOLEAN,
        ARRAY,
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

    public boolean equals(Type other){
        return this.primType == other.primType &&
                // In case of null, check on identity
                (this.innerType == other.innerType || this.innerType.equals(other.innerType));
    }

    public static Primitive getPrimFromString(String type) throws InvalidTypeException{
        switch(type){
            case "int": return Primitive.INTEGER;
            case "bool": return Primitive.BOOLEAN;
            case "char": return Primitive.CHARACTER;
            case "array": return Primitive.ARRAY;
            default: throw new InvalidTypeException(type + " is not a specified type.");
        }
    }
}
