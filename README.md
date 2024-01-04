# GovBox Pro

GovBox Pro je webová aplikácia, ktorá slúži na organizáciu práce so správami zo schránok na slovensko.sk. Je intuitívna, responzívna a dôrazom na silnú konfigurovateľnosť podľa potrieb používateľov.

GovBox pro je zameraný primárne na používateľov, ktorí majú väčšie množstvo agendy so štátom alebo chcú v roku 2024 so štátnou schránkou pracovať v modernom rozhraní a z mobilných zariadení.

![Screenshot](docs/govbox-pro-screenshot2.png?raw=true)

**Medzi klúčové funkcionality (na rozdiel od štátnych schránok) patrí:**
- Zobrazovanie správ vo vláknach a odfiltrovanie nepodstatných technických správ.
- Okamžité prepínanie medzi viacerými schránkami alebo zobrazenie správ naprieč rôznymi schránkami naraz.
- Riadenie workflowu a prístupu k správam pre rôzne skupiny používateľov.
- Podpora pre automatizáciu, hromadné spracovanie, elektronické podpisovanie (cez [Autogram](https://github.com/slovensko-digital/autogram)) a podávanie podaní.
- Dlhodobá archivácia elektronicky podpísaných dokumentov.
- Responzívny dizajn pre mobilné zariadenia, natívne notifikácie, PWA.
- Pripravené pre SaaS, aj on-premise nasadenie.
- Open API pre integráciu s inými systémami.
- Kompletne open-source.

## Autori a sponzori

Autorom tohto projektu je Solver IT, s.r.o. v spolupráci so občianskym združením Slovensko.Digital, ďaľší rozvoj a prevádzku v SaaS režime zabezpečujú Služby Slovensko.Digital, s.r.o.

*Tento projekt je spolufinancovaný z prostriedkov Európskeho fondu regionálneho rozvoja v rámci Operačného programu Integrovaná infraštruktúra. **Govbox Pro/NFP311070CTK1**.* 

## Vývoj

Komunitný vývoj prebieha na GitHube, detaily k rozbehaniu prostredia je môžné nájsť v [DEVELOPER.md](DEVELOPER.md). 

Ak sa chcete zapojiť, ozvi sa nám [na komunitnom Slack](https://slack.slovensko.digital/)-u.

### Externé závislosti

- Sťahovanie správ vyžaduje integráciu na slovensko.sk (ÚPVS) a napojenie cez komponent [slovensko.sk API](https://github.com/slovensko-digital/slovensko-sk-api) alebo  cez službu [GovBox API](https://ekosystem.slovensko.digital/sluzby/govbox-api).
- Na podpisovanie sa využíva [Autogram](https://sluzby.slovensko.digital/autogram).
- Dlhodobá archivácia vyžaduje komponent [govbox-pro-archiver](https://github.com/slovensko-digital/govbox-pro-archiver).

## Licencia

Tento softvér je licencovaný pod [licenciou EUPL v1.2](LICENSE).

V skratke to znamená, že tento softvér môžete voľne používať komerčne aj nekomerčne, môžete vytvárať vlastné verzie a to všetko za predpokladu, že prípadné vlastné zmeny a rozšírenia tiež zverejníte pod rovnakou licenciou a zachováte originálny copyright pôvodných autorov. Softvér sa poskytuje "ber ako je", bez záväzkov.

Tento projekt je postavený na open-source softvéri, ktorý umožnuje jeho používanie tiež komerčne, aj nekomerčne.
