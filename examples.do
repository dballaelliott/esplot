import delimited "training2.csv", clear
rename idn id
encode id, gen(idn)


cap: mkdir docs 
cap: mkdir docs/img 

global esplot_nolog 1

/* LABEL */
label define male 0 Female 1 Male
label values male male

tsset idn monthn 

/* through zero */
/* global esplot_nolog 0

log_program `" esplot paygrade, by(male) event(to_male_mgr) compare(to_fem_mgr) absorb(idn i.male##i.monthn) window(-30 30) period_length(3) vce(cluster idn mgr_id) estimate_reference "'
graph export img/img5.svg, replace  */

esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) estimate_reference
graph export img/img1.svg, replace 

set scheme s1rcolor
esplot paygrade, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)
graph export img/img2a.svg, replace 

set scheme s1color
esplot paygrade, by(male) event(to_male_mgr, nogen) window(-24 30) period_length(12)
graph export img/img2b.svg, replace 

/* esplot paygrade, by(male) event(to_male_mgr) window(-20 30) period_length(12) savedata(event_study_coefs, replace)
/* Add custom graph command */
graph export img/img3.svg, replace  */

/* full specification */
esplot paygrade, by(male) event(to_male_mgr, nogen) compare(to_fem_mgr, save) absorb(idn i.male##i.monthn) window(-30 30) period_length(3) vce(cluster idn mgr_id)
graph export img/img4.svg, replace 

esplot paygrade, by(male) event(to_male_mgr, nogen) compare(to_fem_mgr, nogen) absorb(idn i.male##i.monthn) window(-30 30) period_length(3) vce(cluster idn mgr_id) est_plot(line) ci_plot(rarea) colors(maroon navy)
graph export img/img4a.svg, replace 
graph export img/img4a.png, replace 

/* through zero */
log_program `" esplot paygrade, by(male) event(to_male_mgr, replace save) compare(to_fem_mgr, replace save) absorb(idn i.male##i.monthn) window(-30 30) period_length(3) vce(cluster idn mgr_id) estimate_reference "'
graph export img/img5.svg, replace 


esplot paygrade, by(male) event(to_male_mgr, nogen) compare(to_fem_mgr, nogen) window(-30 30) period_length(3) vce(cluster idn mgr_id) estimate_reference
graph export img/img5a.svg, replace 