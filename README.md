# 2526_ESE_FPGA_Mineure_DEL_RIO_CISNEROS_CONTION
FPGA Practical work of final year in Embedded Systems.

## Compilation et programmation de la carte

On a modifié le code :



https://github.com/user-attachments/assets/adef3031-247f-484d-8a4e-2e1f855ed3ff



## Faire clignoter une LED

1. Plusieurs horloges sont disponibles sur la carte. Sur quelle broche est connectée l’horloge nommée FPGA_CLK1_50 ?
   L’horloge nommée FPGA_CLK1_50 est dans la broche PIN_V11.

2. Le code VHDL ci-dessous permet de faire simplement clignoter une LED

```
library ieee;
use ieee.std_logic_1164.all;

entity led_blink is
    port (
        i_clk : in std_logic;
        i_rst_n : in std_logic;
        o_led : out std_logic
    );
end entity led_blink;

architecture rtl of led_blink is
    signal r_led : std_logic := '0';
begin
    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_led <= '0';
        elsif (rising_edge(i_clk)) then
            r_led <= not r_led;
        end if;
    end process;
    o_led <= r_led;
end architecture rtl;
```

3. Tracez le schéma correspondant à ce code VHDL:

<img width="449" height="346" alt="image" src="https://github.com/user-attachments/assets/0dc266db-58c0-4ebf-9835-62fd1311238c" />

4. Comparez avec le schéma proposé par quartus:

<img width="1590" height="862" alt="image" src="https://github.com/user-attachments/assets/744a9088-32d0-4963-a191-29f6cbb2719a" />

5. Ce n’est pas la peine de tester ce code sur la carte, la LED clignote à 50MHz : c’est trop rapide.
6. En vous aidant du code ci-dessous, modifiez votre code pour réduire la fréquence :
```
process(i_clk, i_rst_n)
    variable counter : natural range 0 to 5000000 := 0;
begin
    if (i_rst_n = '0') then
        counter := 0;
        r_led_enable <= '0';
    elsif (rising_edge(i_clk)) then
        if (counter = 5000000) then
            counter := 0;
            r_led_enable <= '1';
        else
            counter := counter + 1;
            r_led_enable <= '0';
        end if;
    end if;
end process;
```
7. Proposez un schéma correspondant au nouveau code:

<img width="449" height="346" alt="image" src="https://github.com/user-attachments/assets/0dc266db-58c0-4ebf-9835-62fd1311238c" />
   
8. Vérifiez à l’aide de RTL Viewer




 Comme vous l’avez peut-être remarqué :

        Les entrées commencent par i_
        Les sorties commencent par o_
        Les registres commencent par r_
        Les signaux internes commencent par s_

    C’est une bonne habitude à prendre.

Vous noterez également l’utilisation d’un signal de reset : i_rst_n.

9. C’est important d’avoir un signal de reset, utilisez-le pour chacun de vos registres
10. Vous utiliserez le bouton poussoir nommé KEY0 (AH17 sur le FPGA).
11. Que sigifie _n dans i_rst_n ? Pourquoi ? :

    `_n` veut dire que l'entrée `i_rst` est « active-low ». C'est-à-dire que l'entrée `i_rst` a un comportement inverse : si un signal « low » est connecté à la broche `i_rst`, l'état logique du signal sera « high », et si un signal « high » est connecté à la broche `i_rst`, l'état logique du signal sera « low ». Ce comportement est grâce à une porte logique inverseur (NOT) qui est connectée à la broche. Cette porte est représentée par un petit cercle lié à la broche dans le schéma.

## Chenillard

## Écran Magique

### Gestion des encodeurs

