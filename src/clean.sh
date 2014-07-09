#!/bin/bash
find . -name "*.class" -exec rm -rf {} \;
find . -name "*.tokens" -exec rm -rf {} \;
find . -name "*.html" -exec rm -rf {} \;

rm GrammarParser.java
rm GrammarLexer.java

javac TAM/*.java
