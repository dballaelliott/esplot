cap log close _all
import delimited "training.csv", clear


encode id, gen(idn)
tsset idn time 

/* change as we iterate */
local version 1
global VERSION `version'

cap mkdir logs 
cap mkdir logs/v`version'

/* always test the current version */
discard
run esplot.do

set trace on 
set tracedepth 1

log using "logs/v`version'/esplot_master.log", replace name(master)

global NOLOG 0

log_program `"esplot wage, by(male) event(event) window(-2 4) compare(compare) absorb(age) vce(cluster cluster_var)"' 


set trace off 
cap: log close 