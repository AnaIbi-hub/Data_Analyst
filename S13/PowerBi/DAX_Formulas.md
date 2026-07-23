# Fórmules DAX — West Bank Settlements

Document de suport a l'informe final. Conté totes les mesures DAX creades al model de dades
de Power BI (`West_Bank_Settlements.pbix`), agrupades per taula, amb una breu descripció
funcional de cadascuna.

---

## Dim_Settlements

**N assentaments**
```dax
DISTINCTCOUNT(Dim_Settlements[name])
```
Nombre total d'assentaments formals únics.

**Anys amb poblacio**
```dax
COUNTROWS(RELATEDTABLE(Fact_Population))
```
Nombre d'anys amb dades de població disponibles per a l'assentament seleccionat.

**Assentaments acumulats**
```dax
CALCULATE(
    COUNTROWS(Dim_Settlements),
    FILTER(
        ALL(Dim_Settlements),
        Dim_Settlements[year_established] <= MAX(Dim_Calendari[Year]) &&
        NOT ISBLANK(Dim_Settlements[year_established])
    )
)
```
Nombre acumulat d'assentaments fundats fins a l'any de referència (patró de finestra acumulativa amb `FILTER` + `ALL`).

**% Assentaments pre-1993**
```dax
VAR Pre1993 = CALCULATE(COUNTROWS(Dim_Settlements), Dim_Settlements[year_established] < 1993)
VAR Total = COUNTROWS(Dim_Settlements)
RETURN DIVIDE(Pre1993, Total)
```
Percentatge d'assentaments fundats abans dels Acords d'Oslo (1993).

---

## Dim_Outposts

**N outposts**
```dax
DISTINCTCOUNT(Dim_Outposts[name])
```
Nombre total d'outposts (assentaments no reconeguts) únics.

**Outposts totals**
```dax
CALCULATE(
    COUNTROWS(Dim_Outposts),
    FILTER(
        ALL(Dim_Outposts[year_established]),
        Dim_Outposts[year_established] <= MAX(Dim_Outposts[year_established])
    )
)
```
Recompte acumulat d'outposts, mateixa lògica que "Assentaments acumulats" però aplicada a la pròpia dimensió.

**Nous outputs (2025)** *(nom amb errata al model — hauria de dir "Nous outposts"; no s'utilitza en cap visual del dashboard)*
```dax
CALCULATE(COUNTROWS(Dim_Outposts), Dim_Outposts[year_established] = 2025)
```
Nombre d'outposts nous fundats l'any 2025.

**N Assentaments des de 1993**
```dax
CALCULATE(COUNTROWS(Dim_Settlements), Dim_Settlements[year_established] >= 1993)
```
Nombre d'assentaments formals fundats a partir dels Acords d'Oslo (1993, inclusiu).

**Outposts acumulats**
```dax
CALCULATE(
    COUNTROWS(Dim_Outposts),
    FILTER(
        ALL(Dim_Outposts),
        Dim_Outposts[year_established] <= MAX(Dim_Calendari[Year]) &&
        NOT ISBLANK(Dim_Outposts[year_established])
    )
)
```
Nombre acumulat d'outposts fundats fins a l'any de referència.

---

## Dim_AnyFundacio *(taula de suport per al gràfic de trajectòries, pàgina 3)*

**Assentaments_acumulats**
```dax
CALCULATE(
    COUNTROWS(Dim_Settlements),
    FILTER(
        ALL(Dim_Settlements),
        Dim_Settlements[year_established] <= MAX(Dim_AnyFundacio[Year]) &&
        NOT ISBLANK(Dim_Settlements[year_established])
    )
)
```
Sèrie acumulada d'assentaments per al gràfic de línies "Trajectòries d'expansió".

**Outposts_acumulats**
```dax
CALCULATE(
    COUNTROWS(Dim_Outposts),
    FILTER(
        ALL(Dim_Outposts),
        Dim_Outposts[year_established] <= MAX(Dim_AnyFundacio[Year]) &&
        NOT ISBLANK(Dim_Outposts[year_established])
    )
)
```
Sèrie acumulada d'outposts, equivalent a l'anterior.

---

## Any seleccionat *(taula de suport per al mapa temporal interactiu, pàgina 3)*

**Valor de Any seleccionat**
```dax
SELECTEDVALUE('Any seleccionat'[Any seleccionat], 2026)
```
Recupera l'any triat per l'usuari al control temporal del mapa (per defecte, 2026).

**Visible fins any seleccionat**
```dax
VAR SelYear = [Valor de Any seleccionat]
VAR AnyPunt = SELECTEDVALUE(Map_Settlements_Outposts[year_established])
RETURN
IF(
    NOT ISBLANK(AnyPunt) && AnyPunt <= SelYear,
    1,
    0
)
```
Indicador binari (1/0) que determina si un punt del mapa (assentament o outpost) ja existia a l'any seleccionat — filtre base del mapa temporal.

**% Outposts post-1993**
```dax
VAR Post1993 = CALCULATE(COUNTROWS(Dim_Outposts), Dim_Outposts[year_established] >= 1993)
VAR Total = COUNTROWS(Dim_Outposts)
RETURN DIVIDE(Post1993, Total)
```
Percentatge d'outposts fundats a partir de 1993.

**% Outposts des de 2020**
```dax
VAR Since2020 = CALCULATE(COUNTROWS(Dim_Outposts), Dim_Outposts[year_established] >= 2020)
VAR Total = COUNTROWS(Dim_Outposts)
RETURN DIVIDE(Since2020, Total)
```
Percentatge d'outposts fundats des de 2020.

---

## Fact_Demolitions

**N demolicions totals**
```dax
COUNTROWS(Fact_Demolitions)
```
Recompte total d'esdeveniments de demolició (sense filtrar per any — s'usa a la pàgina d'Overview).

**Total Demolicions**
```dax
COUNTROWS(Fact_Demolitions)
```
Mateix càlcul que l'anterior; s'usa a la pàgina de Demolicions, on el context ve acotat pel filtre de pàgina (2006–2025, exclou el 2026 parcial).

**Persones Desplaçades**
```dax
SUM(Fact_Demolitions[people_homeless])
```
Suma de persones desplaçades per demolicions.

**Menors Desplaçats**
```dax
SUM(Fact_Demolitions[minors_homeless])
```
Suma de menors desplaçats per demolicions.

**% dels desplaçats que són menors**
```dax
DIVIDE([Menors Desplaçats], [Persones Desplaçades])
```
Percentatge de persones desplaçades que són menors d'edat.

**% Estructures no residencials**
```dax
DIVIDE(
    CALCULATE(COUNTROWS(Fact_Demolitions), Fact_Demolitions[structure_type] = "non resedential"),
    COUNTROWS(Fact_Demolitions)
)
```
Percentatge d'estructures demolides que no eren residencials.

---

## Fact_Fatalities

**N victimes totals**
```dax
COUNTROWS(Fact_Fatalities)
```
Recompte total de víctimes mortals a mans de colons/civils israelians (sense filtrar per any — Overview).

**Total víctimes**
```dax
COUNTROWS(Fact_Fatalities)
```
Mateix càlcul; context acotat pel filtre de pàgina de Violència (2001–2025, exclou 2000 i 2026 parcials).

**% dels morts que són menors**
```dax
DIVIDE(
    CALCULATE(COUNTROWS(Fact_Fatalities), Fact_Fatalities[age] < 18),
    COUNTROWS(Fact_Fatalities)
)
```
Percentatge de víctimes menors de 18 anys.

**Edat mitjana**
```dax
AVERAGE(Fact_Fatalities[age])
```
Edat mitjana de les víctimes.

**% causats per arma de foc**
```dax
DIVIDE(
    CALCULATE(COUNTROWS(Fact_Fatalities), Fact_Fatalities[injury_type] = "gunfire"),
    COUNTROWS(Fact_Fatalities)
)
```
Percentatge de víctimes mortes per arma de foc.

**Morts a mans de forces de seguretat (B'Tselem)**
```dax
3485
```
Valor constant introduït manualment, verificat directament a la font (B'Tselem, 2001–2025). No prové d'una taula de fets amb detall per fila perquè no es va important un dataset amb aquest nivell de granularitat — es documenta com a xifra de referència agregada.

---

## Fact_Population

**Poblacio total (ultim any)**
```dax
VAR UltimAny = MAX(Fact_Population[year])
RETURN CALCULATE(SUM(Fact_Population[population]), Fact_Population[year] = UltimAny)
```
Població total en l'últim any disponible al context actual.

**Poblacio 2024**
```dax
CALCULATE(SUM(Fact_Population[population]), Fact_Population[year] = 2024)
```
Població total a l'any 2024 (any de referència per al càlcul de creixement interanual).

**Total files Fact_Population**
```dax
COUNTROWS(Fact_Population)
```
Recompte tècnic de files de la taula (control intern).

**Creixement interanual 2024-2025**
```dax
DIVIDE([Poblacio total (ultim any)] - [Poblacio 2024], [Poblacio 2024])
```
Percentatge de creixement de la població colona entre 2024 i 2025.

**Poblacio mitjana per assentament (2024)**
```dax
DIVIDE(
    CALCULATE(SUM(Fact_Population[population]), Fact_Population[year] = 2024),
    CALCULATE(DISTINCTCOUNT(Fact_Population[settlement]), Fact_Population[year] = 2024)
)
```
Població mitjana per assentament l'any 2024.

---

## post7o_period_comparison *(taula de referència, sense mesures pròpies)*

Taula de 3 files (Demolicions, Víctimes mortals, Nous outposts) amb les columnes `pre_oct7_monthly_rate`,
`post_oct7_monthly_rate` i `ratio_post_vs_pre`, calculades prèviament en Python i importades directament
(no requereixen DAX addicional). S'utilitzen a les targetes KPI de la pàgina "Post-7O" amb el format
personalitzat `0,00"×"`.
