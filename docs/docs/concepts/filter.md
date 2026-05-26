# Filter

Filter je dopyt vyhľadávania uložený spoločne s názvom na neskoršie využitie.

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
