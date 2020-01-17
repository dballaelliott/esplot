/*! version 0-alpha-4  17jan2020 Dylan Balla-Elliott, dballaelliott@gmail.com */

cap program drop esplot
program define esplot, eclass sortpreserve


version 14.1 

#delimit ;
/* TODO : make difference a by sub-option */
syntax varlist(max=1) [if] [in] [fweight pweight aweight], ///
	EVent(string asis) /// event(varname, save nogen)
 	[ /// 
	** GENERAL OPTIONS **
	by(varname numeric) ///
	compare(string asis) /// compare(varname, save nogen)
	ESTimate_reference ///
	difference ///
	SAVEdata(string asis) ///
	**START REGRESSION OPTIONS **
	CONTROLs(varlist fv ts) absorb(passthru) vce(passthru) /// 

	**START DISPLAY OPTIONS
	Window(numlist max=2 min=2 integer ascending) ///
	PERIOD_length(integer 1) /// 
	COLors(passthru) ///
	est_plot(passthru) ci_plot(passthru) ///
	legend(passthru) /// 
	* ];
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
/* TODO: Think about how to remove window, and by */

if "$esplot_nolog" == "" global esplot_nolog 1
if $esplot_nolog == 1 global esplot_quietly "quietly :"
else global esplot_quietly

/*****************************************************
		Initial checks and warnings
*****************************************************/

if "`window'" != "" {
	gettoken first_period last_period: (local) window
	if `first_period' >= 0 di as text "Warning: No pre-period displayed. Try adjusting " as input "window"
}

if "`absorb'" == "" local absorb "noabsorb"

$esplot_quietly tsset 
local id `r(panelvar)'
local max_delta = `r(tmax)' - `r(tmin)'

if "`window'" == ""{
	local first_period = -`max_delta'
	local last_period = `max_delta'
}

if "`estimate_reference'" != "" local omitted_threshold = - 1
else local omitted_threshold = - `period_length' - 1

/* foreach var in "by" "window"{
	if "``var''" != "" local pass_`var' = "`var'(``var'')"
} */
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
		//di `"|``arg''_event| == |'``arg''_event'| "'

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

/*!  Add check that I can save the file if you want me to save it
** want to throw the error now, not after everything has run */
/* 	if "`replace'"=="" {
		if `"`savegraph'"'!="" {
			if regexm(`"`savegraph'"',"\.[a-zA-Z0-9]+$") confirm new file `"`savegraph'"'
			else confirm new file `"`savegraph'.gph"'
		}
		if `"`savedata'"'!="" {
			confirm new file `"`savedata'.csv"'
			confirm new file `"`savedata'.do"'
		}
	}
 */
local lags 
local leads 
local L_absorb
local F_absorb
local endpoints

foreach ev of local ev_list{
	//if "`nogen_`ev''" == "nogen" continue
	if "``ev'_name'" == "" continue
	// Make event lags..
	forvalues i = 0/`max_delta'{
		if "`nogen_`ev''" == "" cap: gen L`i'_``ev'_name' = L`i'.``ev'_name' == 1
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
		else error _rc 

		if `i' <= `last_period'{
			if "`by'" == "" local lags "`lags' L`i'_``ev'_name'" 
			else local lags "`lags' L`i'_``ev'_name' i.`by'#c.L`i'_``ev'_name'" 
		}
		else local L_absorb "`L_absorb' L`i'_``ev'_name' " 
	}
	// .. and event leads
	forvalues i = -`max_delta'/`omitted_threshold'{
		local j = abs(`i')
		if "`nogen_`ev''" == "" cap: gen F`j'_``ev'_name' = F`j'.``ev'_name' == 1
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
		else error _rc 

		if `i' >= `first_period'{
			if "`by'" == "" local leads "`leads' F`j'_``ev'_name'"
			else local leads "`leads' F`j'_``ev'_name' i.`by'#c.F`j'_``ev'_name'"
		}	
		else local F_absorb " `F_absorb' F`j'_``ev'_name'"
	}

	if "`nogen_`ev''" == "" & "`window'" != "" cap: egen Lend_``ev'_name' = rowmax(`L_absorb')
	if _rc == 110{
			local old_rc _rc
			if "`replace_`ev''" == "replace"{
				$esplot_quietly drop Lend_``ev'_name'
				$esplot_quietly egen Lend_``ev'_name' = rowmax(`L_absorb')
			} 
			else {
				di as error "variable Lend_``ev'_name' already defined."
				di as text "Type ..." as input "`ev'(``ev'_name', replace)" as text "... if you'd like to overwrite existing lags/leads"
				di as text "Type ..." as input "`ev'(``ev'_name', nogen)" as text "... if you'd like to use the lags/leads in memory"
				error `old_rc'
			}
		}
		else error _rc 

	if "`nogen_`ev''" == ""  & "`window'" != "" cap: egen Fend_``ev'_name' = rowmax(`F_absorb')
		if _rc == 110{
			local old_rc _rc
			if "`replace_`ev''" == "replace"{
				$esplot_quietly drop Fend_``ev'_name'
				$esplot_quietly egen Fend_``ev'_name' = rowmax(`F_absorb')
			} 
			else {
				di as error "variable Fend_``ev'_name' already defined."
				di as text "Type ..." as input "`ev'(``ev'_name', replace)" as text "... if you'd like to overwrite existing lags/leads"
				di as text "Type ..." as input "`ev'(``ev'_name', nogen)" as text "... if you'd like to use the lags/leads in memory"
				error `old_rc'
			}
		}
		else error _rc 

	if "`window'" != "" {
		if "`by'" == "" local endpoints "`endpoints' Lend_``ev'_name' Fend_``ev'_name'"
		else local endpoints "`endpoints' Lend_``ev'_name' Fend_``ev'_name' i.`by'#c.Lend_``ev'_name' i.`by'#c.Fend_``ev'_name' "
	}
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

$esplot_quietly reghdfe `varlist' `leads' `lags' `endpoints' `controls' `if' `in' `weight', `absorb' `vce'

if $esplot_nolog{
	ES_graph `varlist', event(`event_name') `pass_by' compare(`compare_name') `pass_window' /// 
	`estimate_reference' `difference' period_length(`period_length') `colors' `est_plot' `ci_plot' `legend' `options'
}
else{
	log_program `"ES_graph `varlist', event(`event_name') `pass_by' compare(`compare_name') `pass_window' `estimate_reference' `difference' period_length(`period_length') `colors' `est_plot' `ci_plot' `legend' `options' "'
}

if "`savedata'" != ""{
	keep x lo_* hi_* b_* p_* se_*
	rename x t 
	if `period_length' > 1 label var t "Time (averaging over `period_length' periods)"
	else label var t "Time"
	/* see if replace is specified */
	tokenize `"`savedata'"', parse(",")
	if "`3'" != "" save `1' , `3'
	else save `1'
}
restore 

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
}
if "`by'" != "" local pass_by = "by(`by')"

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

if "`by'" == "" local by_groups = 0
else qui: levelsof `by', local(by_groups)

foreach x of local by_groups{
	mat b_`x' = 0
	mat se_`x' = 0
	mat p_`x' = 0

	// Get pre-period coefficients
	forvalues t = `first_period'(`period_length')`omitted_threshold'{
		local j = abs(`t')
		if $esplot_nolog{
			lincom_quarter, lead event(`event') `base_value' `pass_by' `compare' `estimate_reference' `difference' coef_id(`x') time(`j') period_length(`period_length')
		}
		else{
			log_program `"lincom_quarter, lead event(`event') `base_value' `pass_by' `compare' `estimate_reference' `difference' coef_id(`x') time(`j') period_length(`period_length')"'
		}
	}
	// If we aren't estimating the reference category, then we add the zero 
	if "`estimate_reference'" == "" {
		mat b_`x' = (b_`x',.)
		mat se_`x' = (se_`x',.)
		mat p_`x' = (p_`x',.)
	}

	//Add dot at event-time 0 
	lincom_quarter, lag event(`event') `base_value' `pass_by' `compare' `estimate_reference' `difference' coef_id(`x') time(0)

	forvalues t = `period_length'(`period_length')`last_period'{
		lincom_quarter, lag event(`event') `base_value' `pass_by' `compare' `estimate_reference' `difference' coef_id(`x') time(`t') period_length(`period_length')
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
if strpos("`r(varlist)'","`by'") & "`by'" != "" local make_legend 1
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
	
	/* todo: let people pass whatever they want to ci and est opts, including suboptions */
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
	else if "`ci_plot'" == "rcap" | "`ci_plot'" == "" {
		local ci_to_plot `"rcap lo_`x' hi_`x' x, lcolor(`color_id'%80*.75)"'
		local legend_num = `plot_id'*2 
	}
	else {
		if "`ci_plot'" != "rarea" di as text "Unsupported plot type for confidence intervals: " as input "`est_plot'" as text " . Using default"
		local ci_to_plot `" rarea lo_`x' hi_`x' x, fcolor(`color_id'%30) lcolor(`color_id'%0) "'
		local legend_num = `plot_id'*2 
	}
	
	//local new_plot "rarea lo_`x' hi_`x' x, fcolor(`.__SCHEME.color.p`plot_id''%10) lcolor(`.__SCHEME.color.p`plot_id''%80*.75) lpattern(dash) || line b_`x' x, lcolor(`.__SCHEME.color.p`plot_id'') "
	local new_plot " `ci_to_plot' || `b_to_plot' "

	local plot_command `"`plot_command' `new_plot'"'

	local plot_id = `plot_id' + 1

	if `make_legend' local legend_info `"`legend_info' `legend_num' "`:label (`by') `x'' " "'
	
	if "`by'" != "" {
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
	else{
		label var b_`x' "Estimates"
		label var lo_`x' "Lower 95 CI"
		label var hi_`x' "Upper 95 CI"
		label var se_`x' "Estimate SE"
		label var p_`x' "P-Value"
	}
}
/* todo: have option defaults that people can overwrite if they want. 
in particular, by default should make sure there isn't unneccessary white space.
this looks pretty dumb when used with rarea */
if `make_legend' local legend_info = `"order(`legend_info')"'

if "`legend'" != ""{
	if strpos(`"`legend'"',"order") | strpos(`"`legend'"',"label") local legend_info `"`legend'"'
	else local legend_options `"`legend'"'
}

if `"`legend_info'`legend_options'"' != "" local twoway_option `", legend(`legend_info' `legend_options') `options' "'
else if "`options'" != "" local twoway_option ","

`plot_command' `twoway_option' `options'

//saveCoefs `coefs', as(`varlist'_`from'2`to'`tag') `triple_dif' `symmetric' `dd'

end


capture program drop lincom_quarter
program lincom_quarter

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

	/* !Make this quiet soon */
	$esplot_quietly lincom `base_pair' `interaction'

	mat b_`coef_id' = (b_`coef_id',r(estimate))
	mat se_`coef_id' = (se_`coef_id',r(se))
	mat p_`coef_id' = (p_`coef_id',r(p))
}

end


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
			}
			macro shift
		}

		return scalar N = `q'
end

