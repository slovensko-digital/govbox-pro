# Chcem posunut spravu na podpis – podpisuje 1 statutar, organizacia ma len jedneho statutara
- Postup: 
- Pouzivatel oznaci objekty akciou “Na podpis”, pripadne poznamky doplni do poznamok vo vlakne

   - system prida na objekty stitok “Na podpis”
   - system prida na vlakno stitok “Na podpis”

- Nasledne sa statutarovi v pohlade “Na podpis” objavi toto vlakno

- Statutar podpise prislusne objekty - akcia na podpis zobrazi zoznam objektov, ktore je mozne podpisat, statutar podpise vybrane objekty
   - na podpisanych objektoch sa stitok “Na podpis” nahradi stitkom “Podpisane”
   - na podpisanych objektoch sa doplni stitok “Podpisane - #{meno_podpisovaca}”
   - ak na vlakne neostava objekt so stitkom “Na podpis”, stitok na vlakne “Na podpis” sa nahradi stitkom “Podpisane”

# Chcem posunut spravu na podpis – podpisuje 1 podpisovac, organizacie ma viac podpisovacov, podpisuje ktorykolvek podpisovac
- Postup:
- Pouzivatel oznaci objekty akciou “Na podpis”, pripadne poznamky doplni do poznamok vo vlakne

   - system prida na objekty stitok “Na podpis”
   - system prida na vlakno stitok “Na podpis”

- Nasledne sa viacerým statutarom v pohlade “Na podpis” objavi toto vlakno

- Statutary podpišu prislusne objekty - akcia na podpis zobrazi zoznam objektov, ktore je mozne podpisat, statutary podpisu vybrane objekty
   - na podpisanych objektoch sa stitok “Na podpis” nahradi stitkom “Podpisane”
   - na podpisanych objektoch sa doplni stitok “Podpisane - #{meno_podpisovaca}”
   - ak na vlakne neostava objekt so stitkom “Na podpis”, stitok na vlakne “Na podpis” sa nahradi stitkom “Podpisane”

# Chcem posunut spravu na podpis – podpisuje 1 statutar, organizacia ma viac podpisovacov, podpisuje podpisovac podla org. posobnosti
- Postup: 
- Pouzivatel pri vybere akcie “Na podpis” zvoli prislusneho podpisovaca

   - system prida na objekty stitok “Na podpis”
   - system prida na vlakno stitok “Na podpis”

- Nasledne sa statutarovi v pohlade “Na podpis” objavi toto vlakno

- Statutar podpise prislusne objekty - akcia na podpis zobrazi zoznam objektov, ktore je mozne podpisat, statutar podpise vybrane objekty
   - na podpisanych objektoch sa stitok “Na podpis” nahradi stitkom “Podpisane”
   - na podpisanych objektoch sa doplni stitok “Podpisane - #{meno_podpisovaca}”
   - ak na vlakne neostava objekt so stitkom “Na podpis”, stitok na vlakne “Na podpis” sa nahradi stitkom “Podpisane”

# Chcem posunut spravu na podpis – podpisuju vsetci podpisovac
- Postup:
- Pouzivatel oznaci objekty akciou “Na podpis”, pripadne poznamky doplni do poznamok vo vlakne
   - system prida na objekty stitok “Na podpis” a stitok “Na podpis - #{meno_pouzivatela}” kazdeho podpisovaca
   - system prida na vlakno stitok “Na podpis”

- Nasledne sa kazdemu podpisovacovi v pohladoch “Na podpis” aj “Na podpis - #{meno_pouzivatela} objavi toto vlakno

- Statutar podpise prislusne objekty - akcia na podpis zobrazi zoznam objektov, ktore je mozne podpisat, statutar podpise vybrane objekty
   - na podpisanych objektoch sa stitok “Na podpis - #{meno_podpisovaca}” nahradi stitkom “Podpisane - #{meno_podpisovaca}”
   - ak na objekte neostava objekt so stitkom “Na podpis - #{meno_akehokolvek_podpisovaca}”, stitok na objekte “Na podpis” sa nahradi  stitkom “Podpisane”
   - ak na vlakne neostava objekt so stitkom “Na podpis - #{meno_podpisovaca}”, stitok na vlakne “Na podpis - #{meno_podpisovaca}” sa nahradi stitkom “Podpisane - #{meno_podpisovaca}”
   - ak na vlakne neostava objekt so stitkom “Na podpis”, stitok na vlakne “Na podpis” sa nahradi stitkom “Podpisane”

# Chcem posunut spravu na podpis – podpisuje niekolko podpisovacov
- Alternativa 1 - pocet podpisov je vlastnostou tenanta (potrebne doplnit do administracie)
   - odchylka nastava iba po podpisani vo vyhodnocovani dostatocneho poctu podpisov na objekte a na vlakne
- Alternativa 2 - pocet podpisov alebo konkretni mozni podpisovaci nie su vopred dani
   - ziadatel o podpisanie pri akcii “Na podpis“ vyberie pozadovanych podpisovacov (t.j. konkretne stitky “Na podpis - #{meno_podpisovaca}”