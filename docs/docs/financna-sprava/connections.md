---
title: "Prepojenie s účtami na FS"
description: "Ako prepojiť účet na Finančnej správe s GovBox PRO."
keywords: ["financna-sprava", "schránky", "administrácia", "pridanie prepojenia"]
---

# Prepojenie s účtami na Finančnej správe

Administrátor môže v aplikácii nastaviť prepojenie s účtami na Finančnej správe.

::: callout warning "Upozornenie"
Ak potrebujete pridať prepojenie pre viaceré účty na Finančnej správe, kontaktujte podporu na: **podpora@slovensko.digital**.
:::

## Postup prepojenia účtu na Finančnej správe s GovBox PRO

1. **Otvorte Nastavenia**
   Administrátor klikne v ľavom bočnom menu na **"Nastavenia"**

2. **Prejdite do sekcie Administrácia**
   V sekcii **"Administrácia"**, klikne na možnosť **"API Prepojenia"**

3. **Kliknite na úpravu pripraveného API prepojenie**
   Administrátor klikne na tlačidlo s ikonou ceruzky vpravo pri pripravenom prepojení na Finančnú správu

4. **Vyplňte údaje o účte na Finančnej správe**
   Administrátor vyplní údaje pre prepojenie s účtom Finančnej správy:
   - **Názov** prepojenia - volitelné pole, ktoré slúži pre lepšiu orientáciu v nastaveniach
   - **Prihlasovacie meno na portál FS** - identifikátor, ktorým sa prihlasujete na portál Finančnej správy
   - **Heslo na portál FS** - heslo, ktorým sa prihlasujete na portál Finančnej správy 
   
   Administrátor klikne na tlačidlo **"Uložiť"**

5. **Načítajte oprávnenie na zastupovanie z účtu na Finančnej správe**
   Administrátor klikne na tlačidlo **"Automaticky vytvoriť schránky"** pri danom prepojení na Finančnú správu. Týmto sa načítajú schránky, na ktoré má účet oprávnenie na zastupovanie

::: callout warning "Upozornenie"
Ak by ste na portáli Finančnej správy zmenili heslo k svojmu účtu, je potrebné aktualizovať aj heslo uložené v GovBox PRO.
:::

## Vlastník prepojenia

Každé prepojenie používa prihlasovacie údaje jedného účtu na portáli Finančnej správy. Administrátor systému GovBox PRO môže prepojeniu nastaviť aj **vlastníka**, teda používateľa GovBox PRO, ktorému tento účet na portáli FS patrí.

Vlastníka sa oplatí nastaviť, ak má viacero vašich používateľov vlastný účet na portáli FS a každý z nich má na Finančnej správe vlastné oprávnenia na zastupovanie klientov. Bez vlastníka môže podanie podpísať ktokoľvek zo skupiny **"Podpisovatelia"**, aj keď daný subjekt zastupovať nesmie. Takéto podanie potom môže na Finančnej správe skončiť chybou. Vlastník prepojenia oprávnenie na zastupovanie má vždy, pretože schránky sa do GovBox PRO načítali práve z jeho účtu.

Pre prepojenie s nastaveným vlastníkom platí:

- vlastník automaticky získa prístup ku schránkam, ktoré sa cez jeho prepojenie načítajú
- podanie sa na Finančnú správu odošle cez účet toho vlastníka, ktorý ho podpísal
- podania za takúto schránku môže podpísať iba vlastník niektorého z jej prepojení, ktorý je zároveň v skupine **"Podpisovatelia"**
- ostatní používatelia môžu podanie pripraviť a [vyžiadať jeho podpis](../signing/request-signature.md), v zozname podpisujúcich sa im ponúknu iba vlastníci
- ak môže podanie podpísať iba jeden vlastník, podanie automaticky dostane štítok **"Na podpis: [meno vlastníka]"**

GovBox PRO pritom kontroluje iba to, ktorý používateľ GovBox PRO podanie podpisuje, nie certifikát použitý pri podpise. Používateľ tak môže podpísať aj iným ako vlastným certifikátom, napríklad ak u vás všetci podpisujú rovnakým kvalifikovaným certifikátom na eID alebo inej karte. Aj majiteľ takého certifikátu však musí mať oprávnenie zastupovať daný subjekt.

Ak chcete mať pri prepojeniach nastavených vlastníkov, kontaktujte podporu na: **podpora@slovensko.digital**.
