/*! version alpha-1.0  23dec2019 Dylan Balla-Elliott, dballaelliott@hbs.edu */

cap program drop esplot
program define esplot, eclass sortpreserve


version 14.1 

#delimit ;
syntax varlist(max=1) [if], ///
	EVent(varname) /// event(varname, save haslags)
	by(varname numeric) ///
	window(numlist max=2 min=2 integer ascending) ///
 	[ /// 
	** GENERAL OPTIONS **
	compare(varname) /// compare(varname, save haslags)
	estimate_reference ///
	difference ///
	SAVEdata(string) ///
	**START REGRESSION OPTIONS **
	CONTROLs(varlist fv ts) absorb(passthru) vce(passthru) /// 

	**START DISPLAY OPTIONS
	period_length(integer 1) /// 
	colors(passthru) ///
	est_plot(passthru) ci_plot(passthru) ///
	];
# delimit cr

set more off
/* V1.0 options
[SYMmetric /// 
	graph_both ///
	triple_dif ///
	NO_reg ///
	event_type(string) ///
 	absorb(varlist fv ts) ///
	CONTROLs(varlist fv ts) ///
	cluster(varlist) ///
 	Quarters(integer 10) ///
	p_length(integer 3) ///
	yrange(numlist) ///
	tag(string) ///
	label_size(string) ///
	ylab_fmt(string) ///
 	t_col(string) ///
	c_col(string) ///
	filetype(string) ///
	event_suffix(string) ///
	nodd ///
	one_line ///
 	NODROP ///
	mgr_time ///
	graph_all ///
	force ///
	animate ///
	///
	horserace ///
 */

if "$esplot_nolog" == "" global esplot_nolog 1
if $esplot_nolog == 1 global esplot_quietly "quietly :"
else global esplot_quietly
/*****************************************************
		Initial checks and warnings
*****************************************************/
gettoken first_period last_period: (local) window

if `first_period' >= 0 di as error "Warning: No pre-period displayed." as text " Try adjusting " as input "window"

if "`absorb'" == "" local absorb "noabsorb"

$esplot_quietly tsset 
local id `r(panelvar)'
local max_delta = `r(tmax)' - `r(tmin)'

if "`estimate_reference'" != "" local omitted_threshold = - 1
else local omitted_threshold = - `period_length' - 1

preserve

/* TODO order this so that, if we're saving one set of coefs and not the other, we have the one we're saving go first
THEN, after the loop finishes, we do 
restore, not
preserve
so that the new vars are saved  */
local ev_list `event' `compare'
local lags 
local leads 
local L_absorb
local F_absorb
local endpoints

foreach ev of local ev_list{
	/* TODO Add logic to skip
	i.e something like 
	if ``ev'_nogen' == 1 continue */
	
	// Make event lags..
	forvalues i = 0/`max_delta'{
		gen L`i'_`ev' = L`i'.`ev' == 1
		
		if `i' <= `last_period' local lags "`lags' L`i'_`ev' i.`by'#c.L`i'_`ev'" 
		else local L_absorb "`L_absorb' L`i'_`ev' " 
	}
	// .. and event leads
	forvalues i = -`max_delta'/`omitted_threshold'{
		local j = abs(`i')
		gen F`j'_`ev' = F`j'.`ev' == 1
		
		if `i' >= `first_period' local leads "`leads' F`j'_`ev' i.`by'#c.F`j'_`ev'" 
		else local F_absorb " `F_absorb' F`j'_`ev'"
	}

	egen Lend_`ev' = rowmax(`L_absorb')
	egen Fend_`ev' = rowmax(`F_absorb')
	local endpoints "`endpoints' Lend_`ev' Fend_`ev' i.`by'#c.Lend_`ev' i.`by'#c.Fend_`ev' "
}

/* TODO move regression logic here, then call the graph */
$esplot_quietly reghdfe `varlist' `leads' `lags' `endpoints' `controls' `if', `absorb' `vce'

if $esplot_nolog{
	ES_graph `varlist', event(`event') by(`by') compare(`compare') window(`window') /// 
	`estimate_reference' `difference' period_length(`period_length') `colors' `est_plot' `ci_plot'
}
else{
	log_program "ES_graph `varlist', event(`event') by(`by') compare(`compare') window(`window') `estimate_reference' `difference' period_length(`period_length') `colors' `est_plot' `ci_plot'"
}


if "`savedata'" != ""{
	keep x lo_* hi_* b_* p_* se_*
	rename x t 
	if `period_length' > 1 label var t "Time (averaging over `period_length' periods)"
	else label var t "Time"
	/* see if replace is specified */
	tokenize `"`savedata'"', parse(",")
	if "`3'" != "" save `1'.dta , `3'
	else save `1'.dta
}
restore 

end


/* TODO break the actual plotting and the preparation into two different programs
i.e. have ES_graph be able to run on the reloaded data */
capture program drop ES_graph
program ES_graph

#delimit ;
syntax varlist(max=1), ///
	EVent(varname) /// event(varname, save haslags)
	by(varname) ///
	window(numlist max=2 min=2 integer ascending) ///
 	[ /// 
	** GENERAL OPTIONS **
	compare(passthru) /// compare(varname, save haslags)
	estimate_reference ///
	difference ///
	**START DISPLAY OPTIONS *
	period_length(integer 1) /// 
	colors(namelist) ///
	est_plot(name) ci_plot(name) ///
	];
# delimit cr


/* TODO WRITE EXTRACT ARG 
takes in a pass thru arg of the form varname(arg) and returns "arg" */

gettoken first_period last_period: (local) window

if "`estimate_reference'" != "" local omitted_threshold = -`period_length'
else local omitted_threshold = - 2*`period_length'

numlist "`first_period'(`period_length')`omitted_threshold'"

local passed_first_period `first_period'

while strpos("`r(numlist)'","`omitted_threshold'") == 0 {
	local first_period = `first_period' + 1
	numlist "`first_period'(`period_length')`omitted_threshold'"
}

if `passed_first_period' != `first_period' di as error "`passed_first_period' is not divisible by `period_length', starting pre-period at `first_period'"

/* syntax varlist(max=1) [if], //
To(string) From(string) by(varname) ///
 [symmetric triple_dif ghost ///
 Quarters(integer 10) p_length(integer 3) ///
 t_col(string) c_col(string) yrange(numlist) ylab_fmt(string) label_size(string) ///
 filetype(string) tag(string) ev_tag(string) nodd NODROP mgr_time force animate estimate_reference]
 */
qui: levelsof `by', local(by_groups)
foreach x of local by_groups{
	mat b_`x' = 0
	mat se_`x' = 0
	mat p_`x' = 0

	// Get pre-period coefficients
	forvalues t = `first_period'(`period_length')`omitted_threshold'{
		local j = abs(`t')
		if $esplot_nolog{
			lincom_quarter, lead event(`event') by(`by') `compare' `estimate_reference' `difference' coef_id(`x') time(`j') period_length(`period_length')
		}
		else{
			log_program `"lincom_quarter, lead event(`event') by(`by') `compare' `estimate_reference' `difference' coef_id(`x') time(`j') period_length(`period_length')"'
		}
	}
	// If we aren't estimating the reference category, then we add the zero 
	if "`estimate_reference'" == "" {
		mat b_`x' = (b_`x',0)
		mat se_`x' = (se_`x',0)
		mat p_`x' = (p_`x',0)
	}

	//Add dot at event-time 0 
	lincom_quarter, lag event(`event') by(`by') `compare' `estimate_reference' `difference' coef_id(`x') time(0)

	forvalues t = `period_length'(`period_length')`last_period'{
		lincom_quarter, lag event(`event') by(`by') `compare' `estimate_reference' `difference' coef_id(`x') time(`t') period_length(`period_length')
	}
	//Add post-period coefficients
	** transpose all the matrices
	mat b_`x' = b_`x''
	mat se_`x' = se_`x''
	mat p_`x' = p_`x''

	svmat b_`x'
	svmat se_`x'
	svmat p_`x'
}

/********************************************

TRANSFORM MATRIX TO PLOT

**********************************************/

$esplot_quietly drop in 1 //drop the initial 0 in all the matrices

local periods = floor(abs(`first_period')/`period_length') + floor(`last_period'/`period_length') + 1
*x values
$esplot_quietly gen x = _n - abs(floor(`first_period'/`period_length')) - 1 if _n <= `periods' 

foreach x of local by_groups{
	$esplot_quietly gen lo_`x' = b_`x'1 - se_`x'1*1.96
	$esplot_quietly gen hi_`x' = b_`x'1 + se_`x'1*1.96
}

//matlist b_0 b_1 
if "$esplot_quietly" == "" list x lo_* hi_* b_* in 1/`periods'

if "`force'" != "" & "`yrange'" != ""{
	tokenize `yrange'
	local plot_low_bound = `1'
	local sweep = 2
	while "``sweep''" != "" {
		local plot_upper_bound = ``sweep''
		local sweep = `sweep' + 1
	}
	
	local vars T
	if "`triple_dif'" == "" local vars C T 
	foreach var of local vars {
		replace lo_`var' = max(lo_`var',`plot_low_bound')
		replace hi_`var' = min(hi_`var',`plot_upper_bound')
	} 
}
/********************************************
BEGIN GRAPH FORMATTING
*********************************************/
local ytitle: variable label `varlist'
if "`ytitle'" == "" local ytitle "`varlist'"

** set up y settings, including the range & font size
if "`yrange'" != "" local y_settings "ylabel(`yrange', format(`ylab_fmt') labsize(`label_size') angle(horizontal)) yscale(range(`yrange') titlegap(*5))"
else local y_settings "ylabel(, format(`ylab_fmt') labsize(`label_size') angle(horizontal)) yscale(titlegap(*5))"

/* get legend info */
$esplot_quietly ds, has(vallabel)
if strpos("`r(varlist)'","`by'") local make_legend 1
else local make_legend 0


/* Make the twoway logic */
local plot_command "twoway"
local plot_id = 1
local legend_info

gr_setscheme
//if "`colors'" == "" local colors "navy maroon dkorange emerald teal"
foreach x of local by_groups{
	if `plot_id' > 1{
		local plot_command `"`plot_command' ||"' 
	}

	/* get colors  */
	local color_id : word `plot_id' of `colors'

	if "`color_id'" == "" {
		if "`colors'" != "" di as error "No color found for plot `plot_id'; using default."

		local color_id `.__SCHEME.color.p`plot_id''
	}
	
	
	if "`est_plot'" == "line"{
		local b_to_plot `"line b_`x' x, lcolor(`color_id')"'
	}
	else if "`est_plot'" == "scatter" | "`est_plot'" == "" {
		local b_to_plot `"scatter b_`x' x, mcolor(`color_id')"'
	}
	else {
		di as error "Unsupported plot type for estimates: `est_plot'. Using default"
		local b_to_plot `"scatter b_`x' x, mcolor(`color_id')"'
	}


	if "`ci_plot'" == "line"{
		local ci_to_plot `"line lo_`x' hi_`x' x, lcolor(`color_id'%80*.75 `color_id'%80*.75)"' // lpattern(dash)
		local legend_num = `plot_id'*3

	}
	else if "`ci_plot'" == "rarea"{
		local ci_to_plot `" rarea lo_`x' hi_`x' x, fcolor(`color_id'%10) lcolor(`color_id'%80*.75) lpattern(dash) "'
		local legend_num = `plot_id'*2
	}
	else if "`ci_plot'" == "rcap" | "`ci_plot'" == "" {
		local ci_to_plot `"rcap lo_`x' hi_`x' x, lcolor(`color_id'%80*.75)"'
		local legend_num = `plot_id'*2 
	}
	else {
		di as error "Unsupported plot type for confidence intervals: `est_plot'. Using default"
		local ci_to_plot `"rcap lo_`x' hi_`x' x, lcolor(`color_id'%80*.75)"'
		local legend_num = `plot_id'*2 
	}
	

	/* TODO add functionality to graph call */
	//local new_plot "rarea lo_`x' hi_`x' x, fcolor(`.__SCHEME.color.p`plot_id''%10) lcolor(`.__SCHEME.color.p`plot_id''%80*.75) lpattern(dash) || line b_`x' x, lcolor(`.__SCHEME.color.p`plot_id'') "
	local new_plot " `ci_to_plot' || `b_to_plot' "

	local plot_command `"`plot_command' `new_plot'"'

	
	local plot_id = `plot_id' + 1

	if `make_legend' local legend_info `"`legend_info' `legend_num' "`:label (`by') `x'' " "'
	
	if "`:label (`by') `x''" != ""{
		label var b_`x' "Estimates: `:label (`by') `x'' "
		label var lo_`x' "Lower 95 CI : `:label (`by') `x''"
		label var hi_`x' "Upper 95 CI : `:label (`by') `x''"
		label var se_`x' "Estimate SE : `:label (`by') `x''"
		label var p_`x' "P-Value : `:label (`by') `x''"
	}
	else{
		label var b_`x' "Estimates: `by' == `x'  "
		label var lo_`x' "Lower 95 CI : `by' == `x' "
		label var hi_`x' "Upper 95 CI : `by' == `x' "
		label var se_`x' "Estimate SE : `by' == `x' "
		label var p_`x' "P-Value : `by' == `x' "
	} 
}
if `make_legend' local twoway_option `", legend(order(`legend_info'))"'

`plot_command' `twoway_option'

//saveCoefs `coefs', as(`varlist'_`from'2`to'`tag') `triple_dif' `symmetric' `dd'

end


capture program drop lincom_quarter
program lincom_quarter

#delimit ;
syntax , ///
	EVent(varname) /// event(varname, save haslags)
	by(varname) ///
	Time(integer) ///
	coef_id(integer) ///
 	[ compare(varname) /// compare(varname, save haslags)
	estimate_reference ///
	period_length(integer 1) ///
	difference ///
	lag lead ///
	];
# delimit cr
/* syntax, switch(string) pair(string) 
by(varname) 
MOnth(int) 
group(string) 
p_length(integer) 
[nodd 
estimate_reference 
lead lag 
triple_dif SYMmetric ev_tag(string) NODROP reference(int 3)]
 */
local i = `time'

if "`lead'" != "" & "`lag'" != "" {
	di as error "Please select either lag or lead, not both in lincom_quarter"
	exit 198
}
else if "`lead'" != "" local t "F"
else if "`lag'" != "" local t "L"
else { // both are missing
	di as error "Please select either lag or lead in lincom_quarter"
	exit 198
}

local ref = `period_length'
forval j = 1/`period_length' {
	foreach list in event_list comp_list event_list_itr comp_list_itr ///
			ref_event_list ref_comp_list ref_event_list_itr ref_comp_list_itr {
		if `j' == 1 local `list'	  // first time, empty out the lists....
		else local `list' "``list''+" // otherwise, add the plus sign between args
	}
	/* TODO update event syntax */
	local event_list "`event_list'`t'`i'_`event'"
	local comp_list "`comp_list'`t'`i'_`compare'"

	local ref_event_list "`ref_event_list'F`ref'_`event'"
	local ref_comp_list "`ref_comp_list'F`ref'_`compare'"

	local event_list_itr "`event_list_itr'`coef_id'.`by'#`t'`i'_`event'"
	local comp_list_itr "`comp_list_itr'`coef_id'.`by'#`t'`i'_`compare'"

	local ref_event_list_itr "`ref_event_list_itr'`coef_id'.`by'#F`ref'_`event'"
	local ref_comp_list_itr "`ref_comp_list_itr'`coef_id'.`by'#F`ref'_`compare'"

	local --i 
	local --ref 
}
check_omitted_events `event_list'

/* Already dealt with the explicit/implicit ref split */
if "`estimate_reference'" == "" {
	foreach refs in ref_event_list ref_comp_list ref_event_list_itr ref_comp_list_itr {
		local `refs' 0 
	}
	local reference 1
}
else {
	check_omitted_events `ref_event_list'
	local reference = `r(N)'
}

/* !maybe need to zero out the reference categories here */
if "`compare'" == "" {
	local comp_list 0
	local comp_list_itr 0
	local ref_comp_list 0
	local ref_comp_list_itr 0
	local n_comp_itr 1
	local n_comp 1
}
else {
	check_omitted_events `comp_list'
	local n_comp = `r(N)'
	if `coef_id' > 0 {
		check_omitted_events `comp_list_itr'
		local n_comp_itr `r(N)'

	}
}

check_omitted_events `event_list'
local n_event = `r(N)'

if `coef_id' > 0 { //if it's not the base case, add the interaction term
	check_omitted_events `event_list_itr'
	local n_event_itr = `r(N)'

	** for the control, this local will be empty, so we always append it to the lincom
	/* !double check parens */
	local interaction "+ (`event_list_itr')/`n_event_itr' - (`ref_event_list_itr')/`reference' - ((`comp_list_itr')/`n_comp_itr' - (`ref_comp_list_itr')/`reference') "

	** check that one of these isn't zero! **
	if inlist(0,`n_event_itr',`n_comp_itr') {
		*plot missing and go to next quarter
		mat b_`coef_id' = (b_`coef_id',.)
		mat se_`coef_id' = (se_`coef_id',.)
		mat p_`coef_id' = (p_`coef_id',.)

		exit
	}
}

if "`difference'" == "" & inlist(0,`n_event',`n_comp') { // ** if either list is empty, plot missing 
	*plot missing
	mat b_`coef_id' = (b_`coef_id',.)
	mat se_`coef_id' = (se_`coef_id',.)
	mat p_`coef_id' = (p_`coef_id',.)
}
else { // **both of these varlists are non-empty
	** if it's not a treatment group ,the interactions local is empty and ignored
	local base_pair "(`event_list')/`n_event' - (`ref_event_list')/`reference' - ((`comp_list')/`n_comp' - (`ref_comp_list')/`reference') "
	if "`difference'" != "" local base_pair 0  //if difference ,just look at the interaction terms

	/* !Make this quiet soon */
	$esplot_quietly lincom `base_pair' `interaction'

	mat b_`coef_id' = (b_`coef_id',r(estimate))
	mat se_`coef_id' = (se_`coef_id',r(se))
	mat p_`coef_id' = (p_`coef_id',r(p))
}

end


/* TODO generalize coefficent labels */
capture program drop saveCoefs
program saveCoefs
	syntax namelist, [symmetric triple_dif nodd as(string)] 

	local coefs `namelist'

	drop if missing(x)

	tempfile to_write 
	save `to_write', replace 

	foreach x of local coefs {
		keep x lo_`x' hi_`x' b_`x' se_`x' p_`x'
		
		rename *_`x'? *
		rename *_`x' *

		local x_0 "`x'"
		if "`triple_dif'" != ""  local x_0 "DDD"
		if "`symmetric'" != "" local x_0  "Sym. DDD"
		if "`dd'" == "nodd" local x_0 "`x'_noDD"

		gen estimate = "`x_0'"
		
		rename x quarter 

		tempfile new_estimate 
		save `new_estimate', replace 

		cap: mkdir "$out_dir/coefs"
		cap: import delimited "$out_dir/coefs/`as'.csv", clear
		if _rc == 0 {
			drop if estimate == "`x_0'"
			append using `new_estimate'
		}
		
		order estimate quarter b p lo hi se 

		export delimited "$out_dir/coefs/`as'.csv", replace 
		use `to_write', clear 
	}
end 


capture program drop check_omitted_events
program check_omitted_events, rclass
	syntax anything(name=event_list id="list of events")
		local q = 0

		*di "made it to check omitteds"
		tokenize "`event_list'", parse("+-")

		while "`1'" != "" {
			if "`1'" == "-"{
				macro shift
			} 
			else if "`1'" != "+" {
				global tot = $tot + 1

				if _se[`1'] != 0 local q = `q' + 1
				else {
					di "smoothing over missing cell for `event'"
					global n_missing = $n_missing + 1
				}
			}
			macro shift
		}

		return scalar N = `q'
end

include log_program.ado
/*
capture program drop log_program 
program log_program

syntax anything(name=program id="command" everything) ,  [depth(integer 1)]
/*
log_program takes in program call and runs it "noisily",
saving output to the log directory

program() should recieve a command as it would be typed interactively.
*/

tokenize `program', parse(" ,")
local prog_name "`1'"
#delimit ;
local skip_progs 
impose_only_male lincom_quarter
add_stars get_event_properties
check_omitted_events load_ES_macros;
#delimit cr

local timer_name 
timer list
if !strpos("`skip_progs'","`prog_name'"){
	forval t = 1/100 {
		if "`r(t`t')'" == "" { //if timer is empty
			local timer_name `t'
			continue, break
		}
	} 
}

if "`timer_name'" != "" timer on `timer_name'
 
cap: log close `prog_name'

set trace on 
set tracedepth 1

log using "logs/v$VERSION/`prog_name'.log", name(`prog_name') replace

tokenize `: subinstr local program "," "|" ', parse("|")
if "`3'" != "" `1', `3'
else `1'

if "`timer_name'" == "" {
	di "Could not time program, perhaps all timers all full. If the list has entries [1,100] try typing timer clear and running again"
	timer list
}
else {
	timer off `timer_name'
	quietly: timer list `timer_name'
	
	if "`r(t`timer_name')'" != "" {
	local seconds = `r(t`timer_name')'
	local hours = floor(`seconds'/3600)
	local mins = floor(mod(`seconds',3600)/60)
	local sec = round(mod(`seconds', 60))
	*---------------------------------------------------------------------------
	******************************TIMER RESULTS*********************************
	*---------------------------------------------------------------------------
	di "took `hours':`mins':`sec' to run `prog_name'"
	}
}


log close `prog_name'
set trace off 

end