# Hromadný export

Hromadný export správ v GovBox PRO umožňuje používateľom exportovať správy z elektronických schránok vo veľkom množstve. Export môže obsahovať originálne dokumenty, PDF vizualizácie a sumár správ vo formáte .xlsx. Používateľ si môže prispôsobiť štruktúru exportu, názvy súborov a priečinkov pomocou premenných.

## Funkcie exportu

- Export originálnych dokumentov (napr. ASiC-E formát)
- Generovanie PDF verzií dokumentov pre čítanie a tlač
- Vytvorenie sumáru správ s prehľadom údajov (napr. DIČ, stav správy, typ správy)

## Príklad použitia
Export podaní a potvrdení podľa subjektu a obdobia:  
- Dokumenty sa ukladajú do priečinkov pomenovaných podľa názvu subjektu
- Názvy súborov obsahujú informácie o type podania a období, ktorého sa týkajú
- Potvrdenia sú pomenované ako potvrdenia a uložené v rovnakom priečinku ako podania

Príklad štruktúry:  
Firma XY/
├── Firma XY_SVDPH_092025.pdf
├── Firma XY_SVDPH_092025_potvrdenie.pdf

## Súvisiace témy

- [Stiahnutie správy](../messages/downloading.md)
- [Vytvorenie hromadného exportu](../messages/export.md)
