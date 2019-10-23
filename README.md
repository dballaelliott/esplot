# esplot

Event study plots are increasingly popular in applied research. _esplot_ is a new command for stata allowing researchers to quickly and easily create event study plots.

## Install

1. Install from within stata

   `net install esplot, from("https://raw.githubusercontent.com/delliotthart/esplot/master/")`

2. Download/clone from github

   The github repository can be found [here](https://raw.githubusercontent.com/delliotthart/esplot/master/README.md).

## Example

syntax can be as simple...  
`esplot wage, event(treatment) by(gender)`  
or as complicated...  
`do - like - all of the options`  
as you want!
