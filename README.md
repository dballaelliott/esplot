# esplot: a stata package for event study plots

Event study plots are increasingly popular in applied research. `esplot` is a new command for stata allowing researchers to quickly and easily create event study plots.

## Install

1. Install from within stata

   `net install esplot, from("https://raw.githubusercontent.com/dballaelliott/esplot/pkg/") replace`

*OR* 2. Download/clone this repository

#### Examples 

The `examples` folder contains a .do file and a .csv with example data. Users may find it useful to download the folder and run (or simply browse) `make_examples.do` for sample syntax. 

These data can also be used to experiment with the examples provided on the help [site](https://dballaelliott.github.io/esplot). Note that `example.csv` uses the same variable names for ease of use, but that the values have been randomized, so plots may not align with the example images.

## Additional Information

See [site](https://dballaelliott.github.io/esplot) for introduction and overview. 

Type `help esplot` after installation for internal stata help documentation.
