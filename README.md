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

## Petit projet : Écran Magique

Ce petit projet en 3 séances vous propose de concevoir une version numérique du télécran, en utilisant la sortie HDMI de la carte DE10-Nano. Le stylet numérique sera toujours déplacé par deux boutons, les deux encodeurs de la carte mezzanine.

### Gestion des encodeurs

L'objectif est d'incrémenter la valeur d'un registre lorsque l'on tourne l'encodeur vers la droite, et de le décrémenter lorsqu'on le tourne vers la gauche. La taille du registre doit être configurable. On pourra choisir une taille de 10 dans cette partie pour afficher la valeur en binaire sur les LED.

Un encodeur renvoie deux signaux A et B en quadrature.

- Il y a deux conditions possible pour incrémenter le registre :
   - Front montant sur A et B à l'état bas.
   - Front descendant sur A et B à l'état haut.
- Il y a deux conditions possible pour décrémenter le registre :
   - Front montant sur B et A à l'état bas.
   - Front descendant sur B et A à l'état haut

Vous aurez besoin d'une structure de ce type pour détecter les fronts montants :

<img width="582" height="193" alt="image" src="https://github.com/user-attachments/assets/ff7dd072-dda6-468f-9bf8-48706040eb56" />


1. On a commencé à travailler dans le projet fourni dans ce [lien](https://github.com/lfiack/ENSEA_2A_FPGA_Public/blob/main/mineure/3-tp/telecran.zip).
2. À l'aide du schéma ci-dessus, expliquez comment un front montant ou descendant peut être détecté.

   Un front montant peut être détecté en utilisant une porte NOT et une porte AND dans le dernier composant de l'image d'avant. Cela permet de détecter l'état précédent et l'état actuel. 
   

### Contrôleur HDMI

Cette partie du projet consiste à mettre en oeuvre le contrôleur HDMI.


### Déplacement d'un pixel

Cette étape du projet consiste à afficher un seul et unique pixel qui se déplace en fonction des deux encodeurs. L'encodeur gauche déplace le pixel à l'horizontal, l'encodeur gauche déplace le pixel à la verticale.

### Mémorisation

Cette partie est un peu plus complexe. On veut mémoiriser les pixels parcourus pour afficher le dessin, comme sur un véritable écran magique. Il faudra utiliser un framebuffer pour stocker les pixels déjà allumés. Le code d'une mémoire est fourni dans le fichier dpram.vhd. Il s'agit d'une mémoire RAM dual-port.

1. Mémoire dual-port : est un type de mémoire vive qui permet l'accès simultané par deux ensembles indépendants d'adresses, de données et de lignes de contrôle. Cela signifie que les données stockées dans la mémoire RAM à double accès peuvent être consultées deux fois au cours du même cycle.

   La mémoire vidéo (VRAM) est une forme courante de mémoire RAM dynamique à double port principalement utilisée pour la mémoire vidéo, permettant à l'unité centrale de traitement (CPU) de dessiner l'image en même temps que le matériel vidéo la lit à l'écran.

2. Proposer un schéma pour mémoiriser les pixels.

   

### Effacement

Ici on veut pouvoir effacer l'écran lors de l'appui sur un bouton (par exemple sur l'encodeur gauche). C'est plus compliqué qu'il n'y parait : Il faut parcourir toutes les adresses de la RAM pour y écrire un zéro.
