package ast;

public class Type {
    public enum Primitive {
        INTEGER,
        CHARACTER,
        BOOLEAN,
        ARRAY,
        AUTO,
        FUNCTION,
        POINTER,

        // Special type which indicates the caller is responsible
        // for using this type correctly. For example:
        //
        // func malloc(int size) returns %var{
        //    // Fetch argument `size`
        //    __tam__('LOAD(1) -1[LB]');
        //
        //    // Allocate size on heap and return pointer
        //    return __tam__(%int, 'CALL new');
        // }
        //
        // %int p  = malloc(4);
        // %int p2 = p + 1;
        // p2%     = 6;
        VARIABLE
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
     * Returns whether this type has (on any level) a VARIABLE type somewhere.
     */
    public boolean containsVariableType(){
        return 
            (this.primType == Primitive.VARIABLE) ||
            (this.innerType == null ? false : this.innerType.containsVariableType());
    }

    /*
     * Test Type objects for equality. Objects with type AUTO are never
     * equal.
     *
     * @param other: type to compare with
     * @return: result of equality test
     */
    public boolean equals(Type other){
        return equals(other, false);
    }

    /*
     * Test Type objects for equality. Objects with type AUTO are never
     * equal. This is a convinience method, wrapping the passed primitive
     * object into a Type.
     *
     * @param other: type to compare with
     * @return: result of equality test
     */
    public boolean equals(Primitive other){
        return equals(new Type(other));
    }

    /*
     * Test Type objects for equality. Objects with type AUTO are never
     * equal.
     *
     * @param acceptVar: if true, 
     * @param other: type to compare with
     * @return: result of equality test
     */
    public boolean equals(Type other, boolean acceptVar){
        // Are primitive types equal?
        boolean primEqual = this.primType != Primitive.AUTO &&
                            other.primType != Primitive.AUTO &&
                            this.primType == other.primType;

        // If one of arguments has variable as pritimive type, accept it
        // but only if acceptVar flag is set.
        if (acceptVar){
            if(this.primType == Primitive.VARIABLE || other.primType == Primitive.VARIABLE){
                return true;
            }
        }

        // Check for innerType
        if(this.innerType == null){
            return primEqual && other.innerType == null;
        }

        // Innertype is not null, so we can safely use .equals() on it
        return primEqual && this.innerType.equals(other.innerType, acceptVar);
    }


    public static Primitive getPrimFromString(String type) throws InvalidTypeException{
        switch(type){
            case "int": return Primitive.INTEGER;
            case "bool": return Primitive.BOOLEAN;
            case "char": return Primitive.CHARACTER;
            case "array": return Primitive.ARRAY;
            case "var": return Primitive.VARIABLE;
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
