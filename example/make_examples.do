discard 
/* do ../esplot.ado */

adopath ++ "../"

net install allston, from("https://raw.githubusercontent.com/dballaelliott/allston/master/")

set scheme aurora

import delimited "example.csv", clear

** PREPARE DATA
rename male male_string 
encode male_string,  gen(male) 

cap: mkdir ../docs
cap: mkdir ../docs/img 

tsset id month 

** RUN ESPLOT
/* through zero */
esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) estimate_reference
graph export ../docs/img/img1.svg, replace 

esplot paygrade, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)
graph export ../docs/img/img2a.svg, replace 

esplot paygrade, by(male) event(to_male_mgr, nogen) window(-24 30) period_length(12)
graph export ../docs/img/img2b.svg, replace 

/* full specification */
esplot paygrade, by(male) event(to_male_mgr, nogen) compare(to_fem_mgr, save) absorb(id i.male##i.month) window(-30 30) period_length(3) vce(cluster id mgr_id)
graph export ../docs/img/img4.svg, replace 

/* through zero */
esplot paygrade, by(male) event(to_male_mgr, replace save) compare(to_fem_mgr, replace save) absorb(id i.male##i.month) window(-30 30) period_length(3) vce(cluster id mgr_id) estimate_reference
graph export ../docs/img/img5.svg, replace 


esplot paygrade, by(male) event(to_male_mgr, nogen) compare(to_fem_mgr, nogen) window(-30 30) period_length(3) vce(cluster id mgr_id) estimate_reference xtitle("Event Time (Quarters)")
graph export ../docs/img/img5a.svg, replace 
