# Filter

Filter je dopyt vyhľadávania uložený spoločne s názvom na neskoršie využitie.

## Osobné a spoločné filtre

- **Osobný filter** je dostupný iba jeho autorovi, ktorý ho môže upravovať a zmazať.
- **Spoločný filter** je dostupný všetkým používateľom organizácie. Jeho názov a dopyt spravuje administrátor.
- Filter je iba uložené vyhľadávanie. Neprideľuje prístup k správam: každý používateľ vidí iba správy, na ktoré má oprávnenie.

Ak máte osobný filter s rovnakým dopytom ako spoločný, v menu a názve vyhľadávania sa použije váš osobný filter, aj keď je odopnutý. Existujúce odbery notifikácií sa tým nevypínajú ani nezlučujú.

Pri porovnávaní dopytov sa odstránia iba medzery na začiatku a konci. Napríklad ` faktúra ` a `faktúra` označujú rovnaký dopyt; `Faktúra` a `faktúra` sa považujú za rôzne uložené dopyty. Poradie podmienok a medzery vnútri dopytu sa nemenia.

Vytvorenie štítka automaticky nevytvára filter. Dopyt so štítkom si môžete uložiť samostatne.

**Známe obmedzenie:** premenovanie štítka automaticky neopraví uložené dopyty ani staré odkazy používajúce jeho pôvodný názov. Dotknuté filtre je potrebné upraviť.

## Využitie filtrov

- **Často používané vyhľadávania** - rýchly prístup k opakovaným dotazom
- **Notifikácie** - sledovanie zmien v schránke na základe kritérií

## Vytvorenie filtra

Filter môžete nastaviť priamo po zadaní dopytu v poli pre vyhľadávanie vo vrchnej časti obrazovky.

### Operátory pre pokročilé vyhľadávanie

- Vyhľadanie vlákien so štítkom Test: `label:(Test)`
- Vyhľadanie vlákien bez štítku Test: `-label:(Test)`
- Vyhľadanie vlákien úplne bez štítkov: `-label:(*)`

## Príklad použitia

**Filter "Nevybavené"** - dopyt na všetky správy, ktoré nemajú štítok "Vybavené":
```
-label:(Vybavené)
```

## Súvisiace témy

- [Vytvorenie filtra](../filters/creating.md)
- [Nastavenie notifikácií](../notifications/setting-up.md)
