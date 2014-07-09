#!/bin/bash
javadoc -tag requires:cm:"Requires:" -tag ensures:cm:"Ensures:" -classpath ~/code/vb2/tests/build/antlr-3.5.2-complete.jar:. ast checker reporter symtab generator
