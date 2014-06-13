package reporter;

public class Reporter{
    boolean report;

    public Reporter(boolean report){
        this.report = report;
    }

    public void log(String s){
        if (report) System.out.println(s);
    }
}