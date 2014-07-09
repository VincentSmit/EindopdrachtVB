package symtab;

import java.util.HashMap;
import java.util.Stack;

public class SymbolTable<Entry extends IdEntry> {
    
    private int level;
    private HashMap<String, Stack<Entry>> identifiers;

    /**
     * Constructor.
     * @ensures  this.currentLevel() == -1
     */
    public SymbolTable() {
        this.level = -1;
        identifiers = new HashMap<>();
    }

    /**
     * Opens a new scope.
     * @ensures this.currentLevel() == old.currentLevel()+1;
     */
    public void openScope()  {
        this.level++;
    }

    /**
     * Closes the current scope. All identifiers in
     * the current scope will be removed from the SymbolTable.
     * @requires old.currentLevel() > -1;
     * @ensures  this.currentLevel() == old.currentLevel()-1;
     */
    public void closeScope() {
        for(Stack<Entry> entries: this.identifiers.values()){
            if(entries.size() >= 1){
                Entry lastEntry = entries.peek();
                if (lastEntry.getLevel() == this.level){
                    entries.pop();
                }
            }    
        }
        this.level--;
    }

    /** Returns the current scope level. */
    public int currentLevel() {
        return this.level;
    }

    /**
     * Enters an id together with an entry into this SymbolTable
     * using the current scope level. The entry's level is set to
     * currentLevel().
     * @requires id != null && id.length() > 0 && entry != null;
     * @ensures  this.retrieve(id).getLevel() == currentLevel();
     * @throws SymbolTableException when there is no valid
     *    current scope level, or when the id is already declared
     *    on the current level.
     */
    public void enter(String id, Entry entry) throws SymbolTableException {
        if(this.level == -1){
            throw new SymbolTableException("Declaration of " + id + " failed. No scope entered yet.");
        }

        if(!identifiers.containsKey(id)){
            identifiers.put(id, new Stack<Entry>());
        }

        Stack<Entry> entries = identifiers.get(id); 
        if(entries.size() >= 1 && entries.peek().getLevel() == this.level){
            throw new SymbolTableException("Declaration of " + id + " failed. This identifier already declared on this level.");            
        }

        entry.setLevel(this.level);
        entries.push(entry);

    }

    /**
     * Get the Entry corresponding with id whose level is
     * the highest; in other words, that is defined last.
     * @return  Entry of this id on the highest level
     *          null if this SymbolTable does not contain id
     */
    public Entry retrieve(String id) {
        Stack<Entry> entries = this.identifiers.get(id);
        
        if(!this.identifiers.containsKey(id) || entries.size() == 0){
            return null;
        }

        return entries.peek();
    }
}


