KIDEB
==============
Deze repository bevat een beperkte programmeertaal die dient als eindproduct van
het vak 'vertalerbouw' van Universiteit Twente, 2014.

## Mappenstructuur
De repository is verdeeld in een aantal mappen ter organisatie. Hieronder is per
map aangegeven waar het voor dient.

* _docs_: bevat automatisch gegenereerde documentatie, geassembleerd door Oracles
          javadoc. Indien deze map leeg is (zoals in de 'kale' repository het geval
          is) kan `src/javadoc.sh` gebruikt worden om het op te vullen. Let erop dat
          het genereren alleen werkt als alle java klassen reeds gecompileerd zijn.
          Dit kan handmatig, maar gebeurt automatisch bij het uitvoeren van testcases
          of bij het gebruik van `run_as_tam.py` met `--compile` flag.

* _examples_: bevat voorbeeldprogramma's die veel functies van KIDEB behandelen. De
              voorbeelden kunnen uitgevoerd worden door `run_as_tam.py` met Python
              >= 2.7. In de volgende sectie wordt nader uitgelegd hoe dit werkt. Per
              programma is er een extra bestand met de extensie `out` die de gewenste
              uitvoer van het programma bevat. Deze bestanden worden gebruikt om
              geautomatiseerd te testen.

* _tests_: bevat Python programmatuur die geautomatiseerd de checker, parser en code
           generator controleert op correctheid. Er zijn respectievelijk ~30 en ~35
           tests gedefineerd voor de grammar en parser. Voor de code generator geldt 
           dat alle voorbeelden in `examples/` worden bekeken, uitgevoerd en vergeleken
           met de `{out,tam}` bestanden.

* _src_: bevat broncode van parser, checker, compiler en externe _libraries_. Zie (na
         generatie met javadoc) `docs/index.html` voor meer informatie.

* _verslag_: eindverslag

## Uitvoeren van tests
Afhankelijkheden:
 * `java`: >= 1.7
 * `javac`: >= 1.7
 * `python`: >= 2.7

`bash
cd tests/
python grammar.py
python checker.py
python generator.py
`

## Uitvoeren van voorbeeldprogramma's
