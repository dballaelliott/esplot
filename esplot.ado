/*! v 0.9.1 26feb2021 Dylan Balla-Elliott, dballaelliott@gmail.com */

program define esplot, eclass sortpreserve

version 11

#delimit ;
/* TODO : make difference a by sub-option */
syntax varlist(max=2) [if] [in] [fweight pweight aweight/], ///
	[EVent(string asis)] /// event(varname, save nogen)
 	[ /// 
	/** GENERAL OPTIONS **/
	by(varname numeric) ///
	compare(string asis) /// compare(varname, save nogen)
	ESTimate_reference ///
	difference ///
	SAVEdata(string asis) ///
	recenter		///
	
	/** START REGRESSION OPTIONS **/
	CONTROLs(varlist fv ts) absorb(passthru) vce(passthru) /// 

	/**START DISPLAY OPTIONS */
	Window(numlist max=2 min=2 integer ascending) ///
	PERIOD_length(integer 1) /// 
	COLors(passthru) ///
	est_plot(passthru) ci_plot(passthru) ///
	legend(passthru) /// 
	save_sample(name) /// 

	/** quantile regression **/
	Quantile(real -1) ///
	* ];
# delimit cr

if "$esplot_nolog" == "" global esplot_nolog 1
if $esplot_nolog == 1 global esplot_quietly "quietly :"

if "$esplot_quietly" == "" global esplot_quietly "quietly :"
else global esplot_quietly

local wildcard_options `options'

/*****************************************************
		Initial checks and warnings
*****************************************************/
/* process quantile regression */
if `quantile' == -1 {
	local regression reghdfe
} 
else if `quantile' >= 100 | `quantile' <= 0{
	di as error "`quantile' is not a valid quantile; try .5 for median regression."
	exit 198  
}
else if `quantile' >= 1{
	local q = `quantile'/100
	local regression bsqreg
}
else {
	local q = `quantile'
	local regression bsqreg
}

/* parse FE for quantile regression */
if !missing("`absorb'") local main_absorb `absorb'
else local main_absorb "noabsorb"

if `quantile' != -1 & !missing("`absorb'"){

	local absorb_var: subinstr local absorb "absorb(" ""
	local absorb_var: subinstr local absorb_var ")" ""
	extract_varlist `absorb_var'
		
	local qreg_fe = r(varlist)


}

if !missing("`save_sample'"){
	/* if it is a variable this is a problem */
	/* this will exit with an error */
	gen `save_sample' = .
	qui: ds
	local save_sample_vars_to_keep = r(varlist)
} 
/* pull out outcome */
local y: word 1 of `varlist'
local e_t: word 2 of `varlist'

if `:word count `varlist'' == 2 & !missing("`event'`compare'") {
	di as error "Compare and Event indicators not compatible with existing event time variable."
	di  "Try either" as input "esplot y, event(<event_indicator>)" as text "or" as input "esplot y <event_time>"
	exit 
}


if "`window'" != "" {
	gettoken first_period last_period: (local) window
	if `first_period' >= 0 di as text "Warning: No pre-period displayed. Try adjusting " as input "window"
}

if missing("`e_t'"){
	$esplot_quietly tsset 
	local id `r(panelvar)'
	local max_delta = `r(tmax)' - `r(tmin)'

	if "`window'" == ""{
		local first_period = -`max_delta'
		local last_period = `max_delta'
	}
}
else {
	qui: su `e_t'

	local max_delta = max(abs(r(min)),r(max))

	if "`window'" == ""{
		local first_period = r(min)
		local last_period = r(max)
	}
}

if "`estimate_reference'" != "" local omitted_threshold = - 1
else local omitted_threshold = - `period_length' - 1

if "`by'" != "" local pass_by = "by(`by')"
local pass_window = "window(`first_period' `last_period')"

if "`by'" == "" & "`difference'" != ""{
	di as error "Error:" as input "by" as error "is required to use" as input "difference"
	exit 
}

/* PARSE EVENT AND COMPARE */
tokenize `: subinstr local event "," "|" ', parse("|")
local event_name `1'
if "`3'" != ""{
tokenize `3' 
foreach arg in 1 2 3{
	if "``arg''" != ""{
		if inlist("``arg''", "save", "nogen", "replace"){
			local ``arg''_event "``arg''"
		}
		else{ 
			di as error "``arg'' not a valid sub-option of " as input "event"
			exit
		}
	}
}
}

if "`compare'" != ""{
tokenize `: subinstr local compare "," "|" ', parse("|")
local compare_name `1'
if "`3'" != ""{
tokenize `3' 
foreach arg in 1 2 3{
	if "``arg''" != ""{
		if inlist("``arg''", "save", "nogen", "replace"){
			local ``arg''_compare "``arg''"
		}
		else{ 
			di as error "``arg'' not a valid sub-option of " as input "compare"
			exit
		}
	}
}
}
}

// make sure we didn't get both save and nogen, that doesn't make sense 
foreach ev in "compare" "event"{
if "`save_`ev''`nogen_`ev''" == "savenogen"{
	 di as error "Please select at most one of save and nogen in `ev'."
	 exit
}  
if "`nogen_`ev''`replace_`ev''" == "nogenreplace"{
	 di as error "Please select at most one of replace and nogen in `ev'."
	 exit
}  
}

if "`save_compare'" == "save" & "`save_event'" == "" local ev_list compare event
else local ev_list event compare

// if we aren't saving anything, preserve now
if "`save_compare'`save_event'" == "" preserve
if "`save_compare'`save_event'" == "savesave"{
	local save_compare saveLater
	local save_event saveLater
}
/* prepare weights  */

local reg_weights 
if "`exp'" != "" & "`weight'" !="" local reg_weights "[`weight'=`exp']"
else if "`exp'" != "" /* and weight is missing */ local reg_weights "[aw=`exp']"

local lags 
local leads 
local L_absorb
local F_absorb
local endpoints

local e_t_name `e_t' 
if !missing("`e_t'") local ev_list "e_t"

foreach ev of local ev_list{
	//if "`nogen_`ev''" == "nogen" continue
	if "``ev'_name'" == "" continue
	// Make event lags..
	forvalues i = 0/`max_delta'{
		if !missing("`e_t'") gen L`i'_``ev'_name' = `e_t' == `i'
		else if "`nogen_`ev''" == "" cap: gen L`i'_``ev'_name' = L`i'.``ev'_name' == 1
		if _rc == 110{
			local old_rc _rc
			if "`replace_`ev''" == "replace" $esplot_quietly replace L`i'_``ev'_name' = L`i'.``ev'_name' == 1
			else {
				di as error "variable  L`i'_``ev'_name' already defined."
				di as text "Type ..." as input "`ev'(``ev'_name', replace)" as text "... if you'd like to overwrite existing lags/leads"
				di as text "Type ..." as input "`ev'(``ev'_name', nogen)" as text "... if you'd like to use the lags/leads in memory"
				error `old_rc'
			}
		}
		/* else error _rc  */

		if `i' <= `last_period'{
			if "`by'" == "" local lags "`lags' L`i'_``ev'_name'" 
			else local lags "`lags' L`i'_``ev'_name' i.`by'#c.L`i'_``ev'_name'" 
		}
		else local L_absorb "`L_absorb' L`i'_``ev'_name' " 
	}
	// .. and event leads
	forvalues i = -`max_delta'/`omitted_threshold'{
		local j = abs(`i')
		if !missing("`e_t'") gen F`j'_``ev'_name'  = `e_t' == -`j'
		else if "`nogen_`ev''" == "" cap: gen F`j'_``ev'_name' = F`j'.``ev'_name' == 1
		if _rc == 110{
			local old_rc _rc
			if "`replace_`ev''" == "replace" $esplot_quietly replace F`j'_``ev'_name' = F`j'.``ev'_name' == 1
			else {
				di as error "variable F`j'_``ev'_name' already defined."
				di as text "Type ..." as input "`ev'(``ev'_name', replace)" as text "... if you'd like to overwrite existing lags/leads"
				di as text "Type ..." as input "`ev'(``ev'_name', nogen)" as text "... if you'd like to use the lags/leads in memory"
				error `old_rc'
			}
		}
		/* else error _rc  */

		if `i' >= `first_period'{
			if "`by'" == "" local leads "`leads' F`j'_``ev'_name'"
			else local leads "`leads' F`j'_``ev'_name' i.`by'#c.F`j'_``ev'_name'"
		}	
		else local F_absorb " `F_absorb' F`j'_``ev'_name'"
	}

	
	if "`by'" == "" local endpoints "`endpoints' `F_absorb' `L_absorb'"
	else local endpoints "`endpoints' i.`by'#(`F_absorb' `L_absorb')"
	
	/* just save if we said to save, not to save later 
		(this is because if both passed save, it'll try to preserve twice,
		so we switch to "saveLater" if both pass save)
		We should only have it as save if one is save and the 
		other is NOT save*/
	if "`save_`ev''" == "save" preserve
}
/* preserve after both are made if both passed save */
if "`save_compare'`save_event'" == "saveLatersaveLater" preserve

/* double check that we preserved things somewhere */
/* ! DELETE BEFORE RELEASE */
cap: preserve
assert _rc == 621

if "`regression'" == "reghdfe"{
	$esplot_quietly reghdfe `y' `leads' `lags' `endpoints' `controls' `if' `in' `reg_weights', `main_absorb' `vce'
}
else if "`regression'" == "bsqreg"{
	if !missing("`vce'") di "Warning: option `vce' ignored with quantile regression"
	$esplot_quietly bsqreg `y' `leads' `lags' `endpoints' `controls' `qreg_fe' `if' `in' `reg_weights',  quantile(`q')
}
if !missing("`save_sample'"){
	/* confirm we can make the variable */
	replace `save_sample' = e(sample)
	tempfile sample_info
	save `sample_info', replace 
}

/* if we have event time, then that's our event */
local event_name "`e_t'"
if $esplot_nolog{
	ES_graph `y', event(`event_name') `pass_by' compare(`compare_name') `pass_window' /// 
	`estimate_reference' `difference' period_length(`period_length') `colors' `est_plot' `ci_plot' `legend' `wildcard_options' `recenter' 
}
else{
	log_program `"ES_graph `y', event(`event_name') `pass_by' compare(`compare_name') `pass_window' `estimate_reference' `difference' period_length(`period_length') `colors' `est_plot' `ci_plot' `legend' `wildcard_options' `recenter' "'
}

if "`savedata'" != ""{
	keep $ESPLOT_TIME_VAR lo_* hi_* b_* p_* se_*
	rename $ESPLOT_TIME_VAR t 
	if `period_length' > 1 label var t "Time (averaging over `period_length' periods)"
	else label var t "Time"
	/* see if replace is specified */
	tokenize `"`savedata'"', parse(",")
	if "`3'" != "" save `1' , `3'
	else save `1'
}
restore 

if !missing("`save_sample'"){
	use `sample_info', clear 

	keep `save_sample_vars_to_keep'
}
end


/* TODO break the actual plotting and the preparation into two different programs
i.e. have ES_graph be able to run on the reloaded data */
capture program drop ES_graph
program ES_graph

#delimit ;
syntax varlist(max=1), ///
	EVent(varname) /// event(varname, save nogen)
 	[ /// 
	by(varname) ///
	** GENERAL OPTIONS **
	compare(passthru) /// compare(varname, save nogen)
	estimate_reference ///
	difference ///
	recenter /// 
	**START DISPLAY OPTIONS *
	window(numlist max=2 min=2 integer ascending) ///
	period_length(integer 1) /// 
	colors(namelist) ///
	est_plot(name) ci_plot(name) ///
	legend(string asis) * ///
	];
# delimit cr

if "`by'" != ""{
	$esplot_quietly su `by'
	local base_value "base_value(`r(min)')"
	local base_value_id `r(min)'
}
if "`by'" != "" local pass_by = "by(`by')"

/* takes in a pass thru arg of the form varname(arg) and returns "arg" */

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

if "`by'" == "" local raw_by_groups = 0
else qui: levelsof `by', local(raw_by_groups)

if !missing("`by'") & !missing("`difference'") local by_groups : list raw_by_groups - base_value_id 
else local by_groups `raw_by_groups'

** check that by_groups is non-empty 
if missing("`by_groups'") {
	tempname diff_msg
	if !missing("`difference'") local `diff_msg' "after applying difference"
	di as error "No remaining groups found in by variable ``diff_msg''."
	exit
}

foreach x of local by_groups{
	mat b_`x' = 0
	mat se_`x' = 0
	mat p_`x' = 0

	// Get pre-period coefficients
	forvalues t = `first_period'(`period_length')`omitted_threshold'{
		local j = abs(`t')
		if $esplot_nolog{
			aggregate_periods, lead event(`event') `base_value' `pass_by' `compare' `estimate_reference' `difference' coef_id(`x') time(`j') period_length(`period_length')
		}
		else{
			log_program `"aggregate_periods, lead event(`event') `base_value' `pass_by' `compare' `estimate_reference' `difference' coef_id(`x') time(`j') period_length(`period_length')"'
		}
	}
	// If we aren't estimating the reference category, then we add the zero 
	if "`estimate_reference'" == "" {
		mat b_`x' = (b_`x',.)
		mat se_`x' = (se_`x',.)
		mat p_`x' = (p_`x',.)
	}

	//Add dot at event-time 0 
	aggregate_periods, lag event(`event') `base_value' `pass_by' `compare' `estimate_reference' `difference' coef_id(`x') time(0)

	forvalues t = `period_length'(`period_length')`last_period'{
		aggregate_periods, lag event(`event') `base_value' `pass_by' `compare' `estimate_reference' `difference' coef_id(`x') time(`t') period_length(`period_length')
	}
	//Add post-period coefficients
	** transpose all the matrices
	mat b_`x' = b_`x''
	mat se_`x' = se_`x''
	mat p_`x' = p_`x''

	svmat b_`x'
	svmat se_`x'
	svmat p_`x'

	if !missing("`recenter'"){
		local reference_to_shift ""
		
		forval period_elems = 1/`period_length'{
			local reference_to_shift "`reference_to_shift' F`period_elems'_`event' == 1"
			if `period_elems' != `period_length' local reference_to_shift "`reference_to_shift' |"
		}

		
		$esplot_quietly su `varlist' if (`reference_to_shift') & `by' == `x', meanonly
		gen shift`x' = r(mean)	

		if !missing("`difference'") {
			$esplot_quietly su `varlist' if (`reference_to_shift') & `by' == `base_value_id', meanonly
			replace shift`x' = shift - r(mean)	
		}

		replace b_`x'1 = b_`x'1 + shift`x'	

	}


}



/********************************************

TRANSFORM MATRIX TO PLOT

**********************************************/

$esplot_quietly drop in 1 //drop the initial 0 in all the matrices

local periods = floor(abs(`first_period')/`period_length') + floor(`last_period'/`period_length') + 1
*x values
tempvar t 
global ESPLOT_TIME_VAR `t'
$esplot_quietly gen `t' = _n - abs(floor(`first_period'/`period_length')) - 1 if _n <= `periods' 
label variable `t' "event time"

foreach x of local by_groups{
	
	$esplot_quietly gen lo_`x' = b_`x'1 - se_`x'1*1.96
	$esplot_quietly gen hi_`x' = b_`x'1 + se_`x'1*1.96
}

//matlist b_0 b_1 
 
if "$esplot_quietly" == "" list `t' lo_* hi_* b_* in 1/`periods'

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
if strpos("`r(varlist)'","`by'") & "`by'" != "" local make_legend 1
else local make_legend 0

/* Make the twoway logic */
local plot_command "twoway"
local plot_id = 1
local legend_info

gr_setscheme

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
	
	/* todo: let people pass whatever they want to ci and est opts, including suboptions */
	if "`est_plot'" == "line"{
		local b_to_plot `"line b_`x' `t', lcolor(`"`color_id'"')"'
	}
	else if "`est_plot'" == "scatter" | "`est_plot'" == "" {
		local b_to_plot `"scatter b_`x' `t', mcolor(`"`color_id'"')"'
	}
	else {
		di as error "Unsupported plot type for estimates: `est_plot'. Using default"
		local b_to_plot `"scatter b_`x' `t', mcolor(`"`color_id'"')"'
	}


	if "`ci_plot'" == "line"{
		local ci_to_plot `"line lo_`x' hi_`x' `t', lcolor(`"`color_id'%80*.75"' `"`color_id'%80*.75"')"' // lpattern(dash)
		local legend_num = `plot_id'*3

	}
	else if "`ci_plot'" == "rcap" | "`ci_plot'" == "" {
		local ci_to_plot `"rcap lo_`x' hi_`x' `t', lcolor(`"`color_id'%80*.75"')"'
		local legend_num = `plot_id'*2 
	}
	else {
		if "`ci_plot'" != "rarea" di as text "Unsupported plot type for confidence intervals: " as input "`est_plot'" as text " . Using default"
		local ci_to_plot `" rarea lo_`x' hi_`x' `t', fcolor(`"`color_id'%30"') lcolor(`"`color_id'%0"') "'
		local legend_num = `plot_id'*2 
	}
	
	local new_plot " `ci_to_plot' || `b_to_plot' "

	local plot_command `"`plot_command' `new_plot'"'

	local plot_id = `plot_id' + 1

	if `make_legend' { 
		local legend_info `"`legend_info' `legend_num' "`:label (`by') `x''"  "'
	}
	
	if "`by'" != "" {
		if "`:label (`by') `x''" != "`x'"{
			label var b_`x'1 "Estimates: `:label (`by') `x'' "
			label var lo_`x' "Lower 95 CI : `:label (`by') `x''"
			label var hi_`x' "Upper 95 CI : `:label (`by') `x''"
			label var se_`x'1 "Estimate SE : `:label (`by') `x''"
			label var p_`x'1 "P-Value : `:label (`by') `x''"
		}
		else{
			label var b_`x'1 "Estimates: `by' == `x'  "
			label var lo_`x' "Lower 95 CI : `by' == `x' "
			label var hi_`x' "Upper 95 CI : `by' == `x' "
			label var se_`x'1 "Estimate SE : `by' == `x' "
			label var p_`x'1 "P-Value : `by' == `x' "
		} 
	}
	else{
		label var b_`x'1 "Estimates"
		label var lo_`x' "Lower 95 CI"
		label var hi_`x' "Upper 95 CI"
		label var se_`x'1 "Estimate SE"
		label var p_`x'1 "P-Value"
	}
}

/* todo: have option defaults that people can overwrite if they want. 
in particular, by default should make sure there isn't unneccessary white space.
this looks pretty dumb when used with rarea */
if `make_legend' local legend_info = `"order(`legend_info')"'

if !missing(`"`legend'"') {
	if strpos(`"`legend'"',"order") | strpos(`"`legend'"',"label") local legend_info `"`legend'"'
	else local legend_options `"`legend'"'
}

if !missing(`"`legend_info'`legend_options'"') local twoway_option `" legend(`legend_info' `legend_options') `options' "'
else if !missing(`"`options'"') local twoway_option `" `options'"'


`plot_command' `twoway_option' 

//saveCoefs `coefs', as(`varlist'_`from'2`to'`tag') `triple_dif' `symmetric' `dd'

end


capture program drop aggregate_periods
program aggregate_periods

#delimit ;
syntax , ///
	EVent(varname) /// event(varname, save haslags)
	Time(integer) ///
	coef_id(integer) ///
 	[ ///
	by(varname) ///
	base_value(integer 0) ///
	compare(varname) /// compare(varname, save haslags)
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
	di as error "Please select either lag or lead, not both in aggregate_periods"
	exit 198
}
else if "`lead'" != "" local t "F"
else if "`lag'" != "" local t "L"
else { // both are missing
	di as error "Please select either lag or lead in aggregate_periods"
	exit 198
}

local ref = `period_length'
forval j = 1/`period_length' {
	foreach list in event_list comp_list event_list_itr comp_list_itr ///
			ref_event_list ref_comp_list ref_event_list_itr ref_comp_list_itr {
		if `j' == 1 local `list'	  // first time, empty out the lists....
		else local `list' "``list''+" // otherwise, add the plus sign between args
	}

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

if `coef_id' > `base_value' { //if it's not the base case, add the interaction term
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

	$esplot_quietly lincom `base_pair' `interaction'

	mat b_`coef_id' = (b_`coef_id',r(estimate))
	mat se_`coef_id' = (se_`coef_id',r(se))
	mat p_`coef_id' = (p_`coef_id',r(p))
}

end

program extract_varlist, rclass 
syntax varlist(fv ts)

return local varlist `"`varlist'"' 

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
			}
			macro shift
		}

		return scalar N = `q'
end
