# Espeo Budget

### A redmine plugin by Espeo Software.

Plan the budget of your project - plan its' roles, manhours, costs and incomes, and see it all in a nice summary view!

### Description

In polish for now only, sorry.

> Projekt -> Budżet
  * nowa zakładka na stronie projektu - "Budżet"
    * wyświetla wszystkie dane z "Ustawień budżetu" w przejrzystej formie, a także:
    * historia stawek, oraz jeśli przydatne, także historia przepracowanych godzin (i za jaką stawkę?) przez każdą osobę w projekcie
    * ogólne statystyki:
      * kwota całkowitego/pozostałego budżetu
      * j.w., ale dla poszczególnych ról
    * zakładka ta widoczna jest tylko dla określonych ról (administrator, project manager?)

> Projekt -> Ustawienia -> Ustawienia budżetu
  * nowa zakładka w Projekt -> Ustawienia - "Ustawienia budżetu"
  * data początkowa i końcowa trwania projektu
  * "Przyznany budżet godzinowy", czlyi ilość godzin do przepracowania przez każdą z ról
  2 tabelki dla wszystkich ról, określające stawki dla danego okresu i roli za godzinę: "Stawki dla klienta za - godzinę" i "Koszty za godzinę":
  * dodaj powiadomienie e-mail, gdy X% całkowitego budżetu zostanie przekroczone
  * razem z tym:
    * gdy ktoś doda wpis w dzienniku dla określonej daty, brana pod uwagę jest stawka dla tamtej daty (nawet, jeśli zdążyła się zmienić w międzyczasie)
    * gdy ktoś zostanie odsunięty od projektu, godziny jakie przepracował w projekcie (jego wpisy z dziennika w tym projekcie) nadal są brane pod uwagę w budżecie
    * gdy tworzony jest podprojekt, ustawienia budżetu powinny zostać dla niego zduplikowane

### Requirements

* installed [Espeo Additional Project Settings plugin](https://github.com/espeo/redmine_additional_project_settings)


### Installation

1. Make sure your redmine installation already meets the above *requirements*.

2. Copy this plugin's contents or check out this repository into `/redmine/plugins/espeo_budget` directory.

3. Run `bundle exec rake redmine:plugins:migrate`.
