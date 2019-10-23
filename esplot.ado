version 15.1

capture program drop do_event_study
program do_event_study
syntax varlist,  From(string) To(string) by(varname) ///
 [SYMmetric graph_both triple_dif NO_reg event_type(string) ///
 absorb(varlist fv ts) CONTROLs(varlist fv ts) cluster(varlist) ///
 Quarters(integer 10) p_length(integer 3) yrange(numlist) tag(string) label_size(string) ylab_fmt(string) ///
 t_col(string) c_col(string) filetype(string) event_suffix(string) one_line ///
 NODROP mgr_time graph_all]

if "`one_line'" != ""{
	if "`triple_dif'" != "" {
		di as error "Please specify at most one of one_line and triple_dif"
		exit 198
	}
	else if "`symmetric'" != "" {
		di as error "Please specify at most one of one_line and symmetric"
		exit 198
	}
}
//clear graphs so it doesn't build up
graph close _all
timer clear

if "`ylab_fmt'" == "" local ylab_fmt "%9.0g"

foreach option in "absorb" "controls" ///
	"quarters" "cluster" "yrange" "tag" "t_col" "c_col" "filetype" ///
	"event_suffix" "label_size" "p_length" {
	if "``option''" != "" local pass_`option' `option'(``option'')
	}

if "`event_suffix'" == "access" {
	local lo_access = "ev_tag(_low_access)"
	local hi_access = "ev_tag(_high_access)"
}
else if "`event_suffix'" == "gh"{
	local ghost "ev_tag(_gh)"
}

****** INFER EVENT TYPE ***********
if "`event_type'" == "" {
	if inlist("`from'","F","M") local event_type "gender"
	else if inlist("`from'","N","S") local event_type "smoke"
	else if inlist("`from'","O","E") local event_type "placebo"
	else if inlist("`from'","H","L") local event_type "kpi"
}
local final_period = `p_length'*`quarters'

replace male = female == 0
foreach outcome of local varlist{
	if "`no_reg'" == "" log_program, program(`"ES_reg `outcome', event_type(`event_type')  `pass_absorb' `pass_controls' `nodrop'  `one_line' final_period(`final_period') `pass_cluster' `mgr_time' `pass_event_suffix'"')
	log_program, program(`"ES_graph `outcome', to(`to') from(`from') by(`by') `mgr_time' `ghost' `pass_quarters' `pass_yrange' `nodrop'  `pass_tag' `pass_t_col' `pass_c_col' `pass_filetype' `symmetric' `triple_dif' `lo_access' `pass_label_size' `one_line' ylab_fmt(`ylab_fmt') `pass_p_length'"')
	// for now, skip the tables if we're doing the heterogeneity analysis
	** TO-DO: Add support for this!! **
	*if "`hi_access'" == "" log_program, program(`"make_ES_tables `outcome', switch(`from'2`to') by(`by') `pass_tag'"')

	if "`graph_all'" != "" {
		*Make both DD
		ES_graph `outcome', to(`to') from(`from') by(`by') `pass_p_length' `mgr_time' `nodrop' `one_line' `pass_quarters' `pass_yrange' `pass_tag' `pass_t_col' `pass_c_col'  `pass_filetype'  `pass_label_size' ylab_fmt(`ylab_fmt')
		ES_graph `outcome', to(`from') from(`to') by(`by') `pass_p_length' `mgr_time' `nodrop' `one_line' `pass_quarters' `pass_yrange' `pass_tag' `pass_t_col' `pass_c_col'  `pass_filetype'  `pass_label_size' ylab_fmt(`ylab_fmt')

		*Make both DDD
		ES_graph `outcome', to(`to') from(`from') by(`by') `pass_p_length' `mgr_time' `nodrop' `one_line' `pass_quarters' `pass_yrange' `pass_tag' `pass_t_col' `pass_c_col'  `pass_filetype' triple_dif  `pass_label_size' ylab_fmt(`ylab_fmt')
		ES_graph `outcome', to(`from') from(`to') by(`by') `pass_p_length' `mgr_time' `nodrop' `one_line' `pass_quarters' `pass_yrange' `pass_tag' `pass_t_col' `pass_c_col'  `pass_filetype' triple_dif  `pass_label_size' ylab_fmt(`ylab_fmt')

		*make symmetric DD and DDD
		ES_graph `outcome',triple_dif symmetric to(`to') from(`from') by(`by') `pass_p_length' `mgr_time' `nodrop' `one_line' `pass_quarters' `pass_yrange' `pass_tag' `pass_t_col' `pass_c_col'  `pass_filetype'  `pass_label_size' ylab_fmt(`ylab_fmt')
		ES_graph `outcome',symmetric to(`to') from(`from') by(`by') `pass_p_length' `mgr_time' `nodrop' `one_line' `pass_quarters' `pass_yrange' `pass_tag' `pass_t_col' `pass_c_col'  `pass_filetype'  `pass_label_size' ylab_fmt(`ylab_fmt')

		*make_ES_tables `outcome', switch(`to'2`from') by(`by') `pass_tag'
	}

	if "`graph_both'" != ""{
		ES_graph `outcome', to(`from') from(`to') by(`by') `mgr_time' `ghost' `pass_quarters' `pass_yrange' `nodrop' `pass_tag' `pass_t_col' `pass_c_col' `pass_filetype' `symmetric' `triple_dif' `lo_access' `pass_label_size' `one_line' ylab_fmt(`ylab_fmt') `pass_p_length'
	}
		
	if "`hi_access'" != "" {
		log_program, program(`"ES_graph `outcome', to(`to') from(`from') by(`by') `one_line' `nodrop'  `ghost' `pass_quarters' `pass_yrange' `pass_tag' `pass_t_col' `pass_c_col' `pass_filetype' `symmetric' `triple_dif' `hi_access' `pass_label_size' `pass_p_length' ylab_fmt(`ylab_fmt')"')

	}
}

end

capture program drop ES_reg
program ES_reg
syntax varlist(max=1), event_type(string) [ghost absorb(varlist fv ts) CONTROLs(varlist fv ts) ///
 final_period(integer 30) cluster(varlist) horserace one_line event_suffix(string) ///
 NODROP mgr_time]

if "`absorb'" == "" local absorb "noabsorb"
else local absorb absorb(`absorb')

if "`cluster'" != "" local SE_clustering "vce(cluster `cluster')"

if `final_period' == 0 {
	di as error "Can't graph 0 windows!"
	exit 198
}
else if `final_period' < 1 {
	di as error "Can't graph negative windows!"
	exit 198
}


if "`mgr_time'" != "" & "`event_type'" == "foo"{
	reghdfe `varlist' i.emp_smoke_predicted##c.L0_mgr_N2N ///
		i.emp_smoke_predicted##c.F1_mgr_N2N i.emp_smoke_predicted##c.L0_mgr_N2S ///
		i.emp_smoke_predicted##c.F1_mgr_N2S, `absorb' `SE_clustering' noconstant
}
else {
	if "`event_suffix'" == "access" {
		*local lo_access = "ev_tag(_low_access)"
		*local hi_access = "ev_tag(_high_access)"
		log_program, program(load_ES_macros, event_type(`event_type') `one_line' `nodrop' `ghost' threshold(`final_period') ev_tag(_low_access _high_access))
		*load_ES_macros, event_type(`event_type') `ghost' threshold(`max_window') `hi_access' append
	}
	else if  "`event_suffix'" == "gh"{
		log_program, program(load_ES_macros, event_type(`event_type') `nodrop' `one_line' ev_tag(_gh) threshold(`final_period'))
	}
	else if "`horserace'" != "" { // if we DO select horserace - get a macro with ALL the events
		load_ES_macros, event_type("gender") `ghost' threshold(`final_period') `nodrop'
		load_ES_macros, event_type("smoke") `ghost' threshold(`final_period') `nodrop' append
	} // if horserace isn't selected, just get the gender or smoke events
	else log_program, program(load_ES_macros, event_type(`event_type') `nodrop' `one_line' `ghost' threshold(`final_period'))
	reghdfe `varlist' $EVENT_LAGLEADS `controls', `absorb' `SE_clustering'
}
est store `varlist'_results
end

capture program drop load_ES_macros
program load_ES_macros
syntax, event_type(string) [ghost threshold(integer 30) append ev_tag(string) one_line NODROP]

get_event_properties, event_type(`event_type') `ghost'
local event_list `"`r(e_list)'"'
local cat_var `r(cat_var)'

if "`append'" == "" global EVENT_LAGLEADS

di "using these events `event_list'"
local threshold = `threshold' + 1

foreach event of local event_list {
// 	cap: drop Lend_mgr_`event'*
// 	cap: drop Fend_mgr_`event'*
//
// 	gen Lend_mgr_`event' = 0
// 	gen Fend_mgr_`event' = 0
// 	label var Lend_mgr_`event' "`event': Periods [`threshold',$panel_window] absorbed"
// 	label var Fend_mgr_`event' "`event': Periods [-$panel_window,-`threshold'] absorbed"
//
// 	forvalues p = `threshold'/$panel_window {
// 		*if `p' <= 32 continue
//
// 		*after rebuild, make endpoints
// 		replace Lend_mgr_`event' =  Lend_mgr_`event' +  L`p'_mgr_`event' // if !missing(L`p'_mgr_`event')
// 		replace Fend_mgr_`event' =  Fend_mgr_`event' +  F`p'_mgr_`event' // if !missing(F`p'_mgr_`event')
//
// 		qui cap: ds L`p'_mgr_`event'*
// 		if _rc != 0 di "Couldn't find L`p'_mgr_`event'"
// 		else drop `r(varlist)'
//
// 		qui cap: ds F`p'_mgr_`event'*
// 		if _rc != 0 di "Couldn't find F`p'_mgr_`event'"
// 		else drop `r(varlist)'
//
// 	}
//
// 	*Lend_mgr_`event'
// 	qui: su monthn
// 	replace Fend_mgr_`event' = Fend_mgr_`event'/($panel_window - `threshold')
// 	replace Lend_mgr_`event' = Fend_mgr_`event'/($panel_window - `threshold')
//
// 	su Fend_mgr_`event' Lend_mgr_`event', det

	qui cap: ds F1_mgr_`event'* F2_mgr_`event'*  F3_mgr_`event'*  //F4_mgr_`event'* F5_mgr_`event'*  F6_mgr_`event'*
	if _rc != 0 di "Couldn't drop F1_mgr_`event'-F6_mgr_`event'. Ensure the reference category has been dropped"
	else if "`nodrop'" == "" {
		di "dropping `r(varlist)'"
		drop `r(varlist)'
	}

	qui: ds F*_mgr_`event' L*_mgr_`event'
	qui: global `event'_switch "`r(varlist)'"

	if "`ev_tag'" != "" {
		local add_events
		foreach raw_event in ${`event'_switch} {
			if strpos("`raw_event'", "end") continue
			foreach tag of local ev_tag {
				local add_events `add_events' `raw_event'`tag'
			}
		}
		qui: global `event'_switch `add_events'

	}

	local alt_reference
	if "`one_line'" != "" & "`nodrop'" == ""{
		tsset idn monthn
		forval t = 1/3 {
// 			gen F`t'_mgr_`event'_itr = cond(`cat_var', 0, F`t'.L0_mgr_`event')
// 			local alt_reference `alt_reference' F`t'_mgr_`event'_itr

			gen F`t'_mgr_`event' = F`t'.L0_mgr_`event'
			global `event'_switch ${`event'_switch} F`t'_mgr_`event'
		}
	}

	global `event'_int
	foreach ev of global `event'_switch {
		qui: global `event'_int "${`event'_int} i.`cat_var'#c.`ev'"
	}


	qui: global EVENT_LAGLEADS $EVENT_LAGLEADS ${`event'_switch} ${`event'_int} `alt_reference'
}
end

capture program drop get_event_properties
program get_event_properties, rclass
syntax , event_type(string) [ghost]


if !inlist("`event_type'", "gender", "smoke", "placebo","kpi") {
	di as error "Expected gender, smoke, kpi, or placebo; got `event_type' instead"
	exit
}
*********************
local event_list
*********************

if "`event_type'" == "gender" local event_list M2F F2M F2F M2M
else if "`event_type'" == "placebo" local event_list O2E O2O E2E E2O
else if "`event_type'" == "smoke" local event_list S2S N2N N2S S2N
else if "`event_type'" == "kpi" local event_list L2L L2H H2L H2H

********************
local cat_var
********************

if "`event_type'" == "gender" local cat_var "male"
else if "`event_type'" == "placebo" local cat_var "own_oddbd"
else if "`event_type'" == "smoke" local cat_var "emp_smoke_predicted"
else if "`event_type'" == "kpi" local cat_var "male"

return local e_list `"`event_list'"'
return local cat_var `"`cat_var'"'

end

capture program drop ES_graph
program ES_graph
syntax varlist(max=1), To(string) From(string) by(varname) ///
 [symmetric triple_dif ghost ///
 Quarters(integer 10) p_length(integer 3) ///
 t_col(string) c_col(string) yrange(numlist) ylab_fmt(string) label_size(string) ///
 filetype(string) tag(string) ev_tag(string) one_line NODROP mgr_time]

 if "`one_line'" != "" & "`triple_dif'" != ""{
	di as error "Please specify at most one of one_line and triple_dif"
	exit 198
}
foreach option in "ev_tag" {
	if "``option''" != "" local pass_`option' `option'(``option'')
}

if "`tag'" != "" local tag "_`tag'"
local tag "`tag'`ev_tag'"

if "`t_col'" == "" local t_col "blue"
if "`c_col'" == "" local c_col "red"
if "`label_size'" == "" local label_size "large"
if "`filetype'" == "" local filetype "png"
if "`ylab_fmt'" == "" local ylab_fmt "%9.0g"

cap: est restore `varlist'_results
if _rc == 111 {
	di as error "Estimation results for `varlist' not found. Try calling ES_reg first"
	exit 111
}
else if _rc != 0 {
	exit _rc
}

if "`by'" == "male" {
	local treat "Male"
	local control  "Female"
	local t_sym "O"
	local c_sym "S"
}
else if "`by'" == "emp_smoke_predicted" {
	local treat "Smoking"
	local control "Non-Smoking"
	local t_sym "T"
	local c_sym "D"
}
else if "`by'" == "own_oddbd" {
	local treat "Odd BD"
	local control "Even BD"
	local t_sym "Oh"
	local c_sym "Sh"
}

*if "`one_line'" != "" local event_condition "& L0_mgr_`from'2`to'`ev_tag' == 1"
if "`symmetric'" != "" local event_condition "& (L0_mgr_`from'2`to'`ev_tag' == 1 | L0_mgr_`from'2`from'`ev_tag' == 1 |  L0_mgr_`to'2`to'`ev_tag' == 1 | L0_mgr_`to'2`from'`ev_tag' == 1)"
else local event_condition "& (L0_mgr_`from'2`to'`ev_tag' == 1 | L0_mgr_`from'2`from'`ev_tag' == 1)"

/****************************************************
GET COUNTS
*****************************************************/

foreach i in 0 1 {
	if `i' == 0 local group "C"
	else if `i' == 1 local group "T"

	su `varlist' if e(sample) == 1 & `by' == `i'
		local `group'max = string(`r(max)', "%9.2fc")
		local `group'min = string(`r(min)', "%9.2fc")
		local `group'mean = string(`r(mean)', "%9.2fc")
		local `group'sd = string(`r(sd)', "%9.2fc")
		local `group'Nobs = `r(N)'

		quietly{ 
			levelsof idn if e(sample) == 1 & `by' == `i'
			local `group' 0
			foreach level in `r(levels)' {
				local ++`group'
			}
			levelsof idn if e(sample) == 1 & `by' == `i' `event_condition'
			local `group'_ev 0
			foreach level in `r(levels)' {
				local ++`group'_ev
			}
		}
}

local total = `TNobs' + `CNobs'
local ind = `T'+`C'

local t = string(`T', "%9.0fc")
local c = string(`C', "%9.0fc")
local t_ev = string(`T_ev', "%9.0fc")
local c_ev = string(`C_ev', "%9.0fc")

local ind = string(`T'+`C', "%9.0fc")
local ind_ev = string(`T_ev'+`C_ev', "%9.0fc")

est restore `varlist'_results
local last_period = `p_length'*`quarters'
local F_cap = 2*`p_length'

local switch "`from'2`to'"
local pair "`from'2`from'"

preserve
if "`triple_dif'" != "" local coefs T
else if "`one_line'" != "" local coefs T C T_alt C_alt
else local coefs T C

foreach x of local coefs {
	mat b_`x'=0
	mat se_`x'=0


	*Add pretrends (event leads)
	forval i = `last_period'(-`p_length')`F_cap' {
		if "`x'" == "T_alt" {
			lincom_quarter, `pass_ev_tag' one_line `symmetric' ///
			`triple_dif' by(`by') switch("`from'2`from'") pair("`from'2`from'") ///
			month(`i') group(T_alt)  p_length(`p_length') lead
		}
		else if "`x'" == "C_alt" {
			lincom_quarter, `pass_ev_tag' one_line `symmetric' ///
			`triple_dif' by(`by') switch("`from'2`from'") pair("`from'2`from'") ///
			month(`i') group(C_alt)  p_length(`p_length') lead
		}  //"normal" coefs
		else log_program, ///
			program(`"lincom_quarter, `pass_ev_tag' `one_line' `symmetric' `triple_dif' by(`by') switch("`from'2`to'") pair("`from'2`from'") month(`i') group(`x')  p_length(`p_length') lead"')
		}

		if "`one_line'`nodrop'" != "" { //if it's either nodrop or oneline
			lincom_quarter, `one_line' `nodrop' `symmetric' `triple_dif' by(`by') switch("`from'2`to'") pair("`from'2`from'") month(`p_length') group(`x')  p_length(`p_length') lead
		}
		else {
			**try the placeholder**
			mat b_`x' = (b_`x',0)
			mat se_`x' = (se_`x',0)
			**try the placeholder**
		}

		/************************
		*** Add point at t = 0***
		*************************/
		if !inlist("`x'","C_alt","T_alt"){// i.e. it's not the extra F2F or M2M coefs on the non-DD

			if "`symmetric'" != "" {		// if M2F (from = M; to = F)
			local alt_switch "`to'2`from'" 	//alt_switch is F2M and
			local alt_pair "`to'2`to'"		//alt_pair is F2F

			local sym_base "- (L0_mgr_`alt_switch'`ev_tag' - L0_mgr_`alt_pair'`ev_tag')"
			if "`one_line'" != "" local sym_base "- (L0_mgr_`alt_switch'`ev_tag'"

			local sym_itr " - (1.`by'#L0_mgr_`alt_switch'`ev_tag' - 1.`by'#L0_mgr_`alt_pair'`ev_tag')"
			if "`one_line'" != "" local sym_itr " - (1.`by'#L0_mgr_`alt_switch'`ev_tag'"

			}
			if "`x'" == "T" { //for smoke, male, odd_bd, etc, add the interaction terms back in
				** for the control, this local will be empty, so we always append it to the lincom
				if "`one_line'" != "" local interactions "+ 1.`by'#L0_mgr_`switch'`ev_tag'"
				else local interactions "+ 1.`by'#L0_mgr_`switch'`ev_tag' - 1.`by'#L0_mgr_`pair'`ev_tag' `sym_itr'"
			}
			else local interactions

		local base_pair "L0_mgr_`switch'`ev_tag' - L0_mgr_`pair'`ev_tag'`sym_base'"
		if "`triple_dif'" != ""  local base_pair 0
		if "`one_line'" != ""  local base_pair "L0_mgr_`switch'`ev_tag'`sym_base'"
		** if it's not a treatment group ,the interactions local is empty and ignored

		if "`symmetric'" != "" qui lincom .5*(`base_pair'`interactions') // if symmetric divide by 2
		else qui lincom `base_pair' `interactions'


		mat b_`x' = (b_`x',r(estimate))
		mat se_`x' = (se_`x',r(se))
	}
	else { // it IS one of the one_line "extra" coefs
		if "`x'" == "T_alt" { //for smoke, male, odd_bd, etc, add the interaction terms back in
			if "`one_line'" != "" local interactions "+ 1.`by'#L0_mgr_`pair'`ev_tag'"
			else local interactions
		}
		if "`one_line'" != ""  local base_pair "L0_mgr_`pair'`ev_tag'`sym_base'"

		else qui lincom `base_pair' `interactions'

		mat b_`x' = (b_`x',r(estimate))
		mat se_`x' = (se_`x',r(se))
	}
	***
	***

	*Add post-trend (event lags)
	forval i = `p_length'(`p_length')`last_period'{
		if "`x'" == "T_alt" {
			lincom_quarter, `pass_ev_tag' one_line `symmetric' ///
			`triple_dif' by(`by') switch("`from'2`from'") pair("`from'2`from'") ///
			month(`i') group(T_alt)  p_length(`p_length') lead
		}
		else if "`x'" == "C_alt" {
			lincom_quarter, `pass_ev_tag' one_line `symmetric' ///
			`triple_dif' by(`by') switch("`from'2`from'") pair("`from'2`from'") ///
			month(`i') group(C_alt)  p_length(`p_length') lead
		}
		else if "`mgr_time'" == ""{
			lincom_quarter, by(`by') `pass_ev_tag' `symmetric' ///
			`triple_dif' `one_line' switch("`from'2`to'") pair("`from'2`from'") ///
			month(`i') p_length(`p_length') group(`x') lag
		}
	}

	mat b_`x' = b_`x''
	mat se_`x' = se_`x''

	svmat b_`x'
	svmat se_`x'
}

/********************************************
TRANSFORM MATRIX TO PLOT
**********************************************/

*x values
gen x = _n - `quarters' - 2 if _n <= 2*`quarters'+2 // preperiod
*replace x = _n - `quarters' -1 if _n > `quarters'  & _n <= 2*`quarters' + 1 // 0 and post period
*replace x = -1 if _n == 2*`quarters' + 2 // add the manual dot for t = -1
*if "`triple_dif'" == "" replace b_C = . if x == -1
*replace b_T = . if x == -1
replace x = . if abs(x) > `quarters'
if "`mgr_time'" != ""{
	sort x
	replace x = 2 if x == 1
	replace x = 1 if x == 0
	replace x = . if x > 1

	local quarters = 1.67
}

if "`triple_dif'" == "" gen lo_C= b_C1-se_C1*1.96
if "`triple_dif'" == "" gen hi_C= b_C1+se_C1*1.96

gen lo_T= b_T1-se_T1*1.96
gen hi_T= b_T1+se_T1*1.96

if "`one_line'" != "" gen lo_C_alt= b_C_alt-se_C_alt*1.96
if "`one_line'" != "" gen hi_C_alt= b_C_alt+se_C_alt*1.96

if "`one_line'" != "" gen lo_T_alt= b_T_alt-se_T_alt*1.96
if "`one_line'" != "" gen hi_T_alt= b_T_alt+se_T_alt*1.96

if inlist("`ev_tag'","_low_access","_high_access") & "`varlist'" == "pc" {
	local vars T
	if "`triple_dif'" == "" local vars C T 
	foreach var of local vars {
		replace lo_`var' = max(lo_`var',-1)
		replace hi_`var' = min(hi_`var',1)
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

** name the file we're going to save
if "`triple_dif'" != "" local ddd "DDD"
if "`symmetric'" != "" local sym "SYM"
local graph_name "`sym'`ddd'`varlist'_`from'2`to'"

** label the variables
label var b_T1 "`treat' Emp. (`t'; `t_ev' w/event)"
if "`triple_dif'" != "" label var b_T1 "DDD: `treat' - `control' (`ind', `ind_ev' with event)"
else label var b_C1 "`control' Emp. (`c'; `c_ev' w/event)"

if "`one_line'" != "" label var b_C_alt1 "`c_alt_ev' `from'2`from'"
if "`one_line'" != "" label var b_T_alt1 "`t_alt_ev'  `from'2`from'"

//set up the x label with the "+" added to positive time
local xlab "xlabel(-`quarters'(1)0"
forvalues i = 1/`quarters' {
	local xlab `"`xlab' `i' "+`i'""'
}

if "`mgr_time'" != "" local xlab `"xlabel(-1 "Before Switch" 0 " " +1 "After Switch", labsize(medium))"'
else local xlab `xlab', angle(45) format(%-9.0g) labsize(`label_size'))

if `p_length' == 3 local x_title "Quarters Relative to Manager Switch"
else if `p_length' == 6 local x_title "Half-Years Relative to Manager Switch"
else local x_title "Time Relative to Manager Switch: T = `p_length' Mo. Groupings"

if "`mgr_time'" != "" local x_title " "

if "`mgr_time'" != "" local connected  "connect(l) lpattern(########-)"
// if "`mgr_time'" != "" {
// 	lincom (1.`by'#L0_mgr_`from'2`to' - 1.`by'#L0_mgr_`from'2`from')
// 	local note  `"note("DDD point estimate: `r(estimate)', t score `r(t)' -> p == 0 `r(p)'", alignment(bottom) margin(top))"'
// }

if "`triple_dif'" != "" { //plot DDD graph
	scatter b_T x, mc(green) lc(green) msize(small) msymbol(`t_sym') || ///
	rcap hi_T lo_T x, lc(green) msize(small) ///
	xscale(range(-`quarters' `quarters')) `xlab' ///
	xtitle("`x_title'", size(`label_size')  height(-3)) legend(col(1) order(1 3) nobox lwidth(none) region(color(none)) position(11) ring(0)) ///
	graphregion(style(none) color(gs16)) `note' ///
	xline(0,lp(dash)) scheme(s1mono) yline(0,lp(dash)) xscale(titlegap(*.25)) ///
	`y_settings' ytitle("`ytitle'", size(`label_size')) name("`graph_name'", replace)
	*legend(col(1) order(1 - "Events: ``gender_blab'Nevents_`switch'' & ``gender_blab'Nevents_`pair''.") bexpand)
}
else if "`one_line'" != "" {
	twoway ///
	scatter b_C1 x, mc("`c_col'") lc("`c_col'") msize(small) msymbol(`c_sym') || ///
	rcap lo_C hi_C x, lc("`c_col'") msize(small) || ///
	scatter b_T1 x, mc("`t_col'") lc("`t_col'") msize(small) msymbol(`t_sym') || ///
	rcap hi_T lo_T x, lc("`t_col'") msize(small) || ///
	scatter b_C_alt x, mc(`c_col'*.8) lc(`c_col'*.8) msize(small) msymbol(`c_sym'h) || ///
	rcap lo_C_alt hi_C_alt x, lc(`c_col'*.8) msize(small) || ///
	scatter b_T_alt x, mc(`t_col'*.8) lc(`t_col'*.8) msize(small) msymbol(`t_sym'h) || ///
	rcap hi_T_alt lo_T_alt x, lc(`t_col'*.8) msize(small) ///
	xscale(range(-`quarters' `quarters')) `xlab' ///
	xtitle("`x_title'", size(`label_size') height(-3)) legend(col(2) order(1 5 3 7) nobox lwidth(none) region(color(none)) position(11) ring(0)) ///
	graphregion(style(none) color(gs16)) `note' ///
	xline(0,lp(dash)) scheme(s1mono) yline(0,lp(dash)) xscale(titlegap(*.25)) ///
	`y_settings' ytitle("`ytitle'", size(`label_size')) name("`graph_name'", replace)
}
else { // plot DD (MAIN) graph
	twoway ///
	scatter b_C x, mc("`c_col'") lc("`c_col'") msize(small) msymbol(`c_sym') `connected' || ///
	rcap lo_C hi_C x, lc("`c_col'") msize(small) || ///
	scatter b_T x, mc("`t_col'") lc("`t_col'") msize(small) msymbol(`t_sym')  `connected' || ///
	rcap hi_T lo_T x, lc("`t_col'") msize(small) ///
	xscale(range(-`quarters' `quarters')) `xlab' `note' ///
	xtitle("`x_title'", size(`label_size') height(-3)) legend(col(1) order(1 3) nobox lwidth(none) region(color(none)) position(11) ring(0)) ///
	graphregion(style(none) color(gs16)) ///
	xline(0,lp(dash)) scheme(s1mono) yline(0,lp(dash)) xscale(titlegap(*.25)) ///
	`y_settings' ytitle("`ytitle'", size(`label_size')) name("`graph_name'", replace)
}

if "`triple_dif'" != "" cap: mkdir "$out_dir/DDD"
if "`triple_dif'" != "" local DD_path "DDD/"
else local DD_path

//if sym AND DDD, put it in symmetric
if "`symmetric'" != "" cap: mkdir "$out_dir/symmetric"
if "`symmetric'" != "" local DD_path "symmetric/"

if "`filetype'" == "gph" graph save "$out_dir/`DD_path'`graph_name'`tag'.gph", replace
else cap: graph export "$out_dir/`DD_path'`graph_name'`tag'.`filetype'", replace
if _rc != 0 graph export "$out_dir/`DD_path'`graph_name'`tag'.eps", replace

restore

// 		"`qual'" ///
// 		"Obs = `total'. Individuals = `ind'; odd BD = `o' and even BD = `e'." ///
// 		"Destination big mgrs: O = `i_bmgr_odd'; E = `i_bmgr_even'. Small mgrs: O = `i_smgr_odd'; NS = `i_smgr_even'." ///
// 		"Odd BD employees mean: `Omean'; SD: `Osd'; min: `Omin'; max: `Omax'." ///
// 		"Even BD employees mean: `Emean'; SD: `Esd'; min: `Emin'; max: `Emax'." ///
// 		"Restriction that new exog manager stays at least 3 contiguous months in unit." ///
// 		"Top 1% of manager events NO LONGER replaced with event = 0." ///
// 		"Endpoints `left_endpoint' and `right_endpoint' absorbed and not graphed." ///
// 		"Reference: (t-1), (t-2), & (t-3). Individual & month-year FEs. Control for all manager switches." ///
// 		"Events O2O: `mean_mgr_O2O'; O2E: `mean_mgr_O2E'; E2E: `mean_mgr_E2E'; E2O: `mean_mgr_E2O'." ///
// 		"All events enter regression together. Missing $n_missing/$tot month level estimates")
//

end

capture program drop lincom_quarter
program lincom_quarter
syntax ,switch(string) pair(string) by(varname) MOnth(int) group(string) p_length(integer) [one_line lead lag triple_dif SYMmetric ev_tag(string) NODROP]

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

if "`symmetric'" != "" {
	tokenize "`switch'", parse("2") //if switch is M2F, then..
	local alt_switch "`3'2`1'" 		//alt_switch is F2M and
	local alt_pair "`3'2`3'"		//alt_pair is F2F
}

local i = `month'

forval j = 1/`p_length' {
	foreach list in switch_list pair_list switch_list_itr pair_list_itr ///
			alt_switch_list alt_pair_list alt_switch_list_itr alt_pair_list_itr {
		if `j' == 1 local `list'	  // first time, empty out the lists....
		else local `list' "``list''+" // otherwise, add the plus sign between args
	}
	local switch_list "`switch_list'`t'`i'_mgr_`switch'`ev_tag'"
	local pair_list "`pair_list'`t'`i'_mgr_`pair'`ev_tag'"

	local switch_list_itr "`switch_list_itr'1.`by'#`t'`i'_mgr_`switch'`ev_tag'"
	local pair_list_itr "`pair_list_itr'1.`by'#`t'`i'_mgr_`pair'`ev_tag'"

	local alt_switch_list "`alt_switch_list'`t'`i'_mgr_`alt_switch'`ev_tag'"
	local alt_pair_list "`alt_pair_list'`t'`i'_mgr_`alt_pair'`ev_tag'"

	local alt_switch_list_itr "`alt_switch_list_itr'1.`by'#`t'`i'_mgr_`alt_switch'`ev_tag'"
	local alt_pair_list_itr "`alt_pair_list_itr'1.`by'#`t'`i'_mgr_`alt_pair'`ev_tag'"

	local --i
}

check_omitted_events "`switch_list'"
local n_switch = `r(N)'
check_omitted_events "`pair_list'"
local n_pair = `r(N)'

if "`one_line'" !="" {
	local pair_list 0
	local n_pair 1
}

if "`symmetric'" != "" {
	check_omitted_events "`alt_switch_list'"
	local n_alt_switch = `r(N)'
	local normed_alt_switch_list "(`alt_switch_list')/`n_alt_switch'"

	check_omitted_events "`alt_pair_list'"
	local n_alt_pair = `r(N)'
	local normed_alt_pair_list "(`alt_pair_list')/`n_alt_pair'"


	check_omitted_events "`alt_switch_list_itr'"
	local n_alt_switch_itr = `r(N)'
	local normed_alt_switch_itr "(`alt_switch_list_itr')/`n_alt_switch_itr'"

	check_omitted_events "`alt_pair_list_itr'"
	local n_alt_pair_itr = `r(N)'
	local normed_alt_pair_itr "(`alt_pair_list_itr')/`n_alt_pair_itr'"

	if "`one_line'" !="" {
		local normed_alt_pair_list 0
		local normed_alt_pair_itr 0
	}
	local sym_itr "- (`normed_alt_switch_itr' - `normed_alt_pair_itr')"
	local sym_base "- (`normed_alt_switch_list' - `normed_alt_pair_list')"
}

if inlist("`group'","T","T_alt") { //for smoke, male, odd_bd, etc, add the interaction terms back in
	check_omitted_events "`switch_list_itr'"
	local n_switch_itr = `r(N)'
	check_omitted_events "`pair_list_itr'"
	local n_pair_itr `r(N)'
	** for the control, this local will be empty, so we always append it to the lincom

	if "`one_line'" !="" {
		local pair_list_itr 0
		local n_pair_itr 1
	}
	local interactions "+ (`switch_list_itr')/`n_switch_itr' - (`pair_list_itr')/`n_pair_itr' `sym_itr'"

	** check that one of these isn't zero! **
	if inlist(0,`n_switch_itr',`n_pair_itr') {
		*plot missing and go to next quarter
		mat b_`group' = (b_`group',.)
		mat se_`group' = (se_`group',.)
		exit
	}
}

if "`triple_dif'" == "" & inlist(0,`n_switch',`n_pair') { // ** check that one of these isn't zero**
	*plot missing
	mat b_`group' = (b_`group',.)
	mat se_`group' = (se_`group',.)
}
else { // both of these varlists are non-empty
	** if it's not a treatment group ,the interactions local is empty and ignored
	local base_pair "(`switch_list')/`n_switch' - (`pair_list')/`n_pair'`sym_base'"
	if "`triple_dif'" != "" local base_pair 0

	if "`symmetric'" != "" qui lincom .5*(`base_pair' `interactions')
	else qui lincom `base_pair' `interactions' //if triple difference ,just look at the interaction terms

	mat b_`group' = (b_`group',r(estimate))
	mat se_`group' = (se_`group',r(se))
}

end

capture program drop check_omitted_events
program check_omitted_events, rclass
	args event_list
		local q = 0

		*di "made it to check omitteds"
		tokenize "`event_list'", parse("+")

		while "`1'" != "" {
			if "`1'" != "+" {
				global tot = $tot + 1

				if _se[`1'] != 0 local q = `q' + 1
				else {
					di "smoothing over missing cell for `1'"
					global n_missing = $n_missing + 1
				}
			}
			macro shift
		}

		return scalar N = `q'
end

capture program drop make_ES_tables
program make_ES_tables
syntax varlist, by(varname) switch(string) [pair(string) final_period(integer 30) tag(string)]

if "`tag'" != "" local tag "_`tag'"
if "`pair'" == "" {
tokenize "`switch'", parse("2")
local pair "`1'2`1'"
}

cap: est restore `varlist'_results
if _rc == 111 {
	di as error "Estimation results for `varlist' not found. Try calling ES_reg first"
	exit 111
}
else if _rc != 0 {
	exit _rc
}

local table_path : subinstr global out_dir "figures" "tables"
cap mkdir "`table_path'"

local ref = 3

foreach t of numlist 0/`final_period' {
		if `t' < 12 { //append the "short run" variables to their varlists, subtracting the comparison groups
			local post_short_event "`post_short_event'1.`by'#L`t'_mgr_`switch'+"
			local post_short_comp "`post_short_comp'1.`by'#L`t'_mgr_`pair'+"
			if `t' > `ref' {
				local pre_short_event "`pre_short_event'1.`by'#F`t'_mgr_`switch'+"
				local pre_short_comp "`pre_short_comp'1.`by'#F`t'_mgr_`pair'+"
			}
		}
		else if `t' == 12 { // if the last observation in the time period, don't add a plus at the end.

			local post_short_event "`post_short_event'1.`by'#L`t'_mgr_`switch'"
			local post_short_comp "`post_short_comp'1.`by'#L`t'_mgr_`pair'"
			local pre_short_event "`pre_short_event'1.`by'#F`t'_mgr_`switch'"
			local pre_short_comp "`pre_short_comp'1.`by'#F`t'_mgr_`pair'"

		} // do the same for long run
		else if `t' < `final_period' {
			if `t' < (`final_period' - 2) {
				local pre_long_event "`pre_long_event'1.`by'#F`t'_mgr_`switch'+"
				local pre_long_comp "`pre_long_comp'1.`by'#F`t'_mgr_`pair'+"
			}
			else if `t' == `final_period' - 2 {
				local pre_long_event "`pre_long_event'1.`by'#F`t'_mgr_`switch'"
				local pre_long_comp "`pre_long_comp'1.`by'#F`t'_mgr_`pair'"
			}
			local post_long_event "`post_long_event'1.`by'#L`t'_mgr_`switch'+"
			local post_long_comp "`post_long_comp'1.`by'#L`t'_mgr_`pair'+"

		}
		else if `t' == `final_period' {
			local post_long_event "`post_long_event'1.`by'#L`t'_mgr_`switch'"
			local post_long_comp "`post_long_comp'1.`by'#L`t'_mgr_`pair'"
		}
}


local group_name: variable label `by'
if "`group_name'" == "" local group_name "`by'"

qui: putexcel set "`table_path'/`varlist'_`switch'`tag'", replace
qui: putexcel C1="In-Group `group_name' Effect"
qui: putexcel A3="Post-Treatment" A4="Months 1- 12" A6="Months 13-`final_period'"
qui: putexcel A9="Pre-Treatment (Falsification)"
local month = `ref' + 1
qui: putexcel A10 ="Months `month'- 12" A12="Months 13-`final_period'"

local col = 2

global n_missing = 0
global tot = 0

local x: word `col' of `c(ALPHA)'
*local col = `col' + 1

local DV_name: variable label `varlist'
if "`DV_name'" == "" local DV_name "`varlist'"
qui: putexcel `x'2="`varlist'"

di "writing coefficients to table"
** Short run, post period**

check_omitted_events "`post_short_event'"
local event_len = `r(N)'
check_omitted_events "`post_short_comp'"
local comp_len = `r(N)'

qui: lincom (`post_short_event')/`event_len' - (`post_short_comp')/`comp_len'
add_stars
qui: putexcel `x'4="`r(B)'" `x'5="(`r(se)')"

** Long run, post period**
check_omitted_events "`post_long_event'"
local event_len = `r(N)'
check_omitted_events "`post_long_comp'"
local comp_len = `r(N)'

qui: lincom (`post_long_event')/`event_len' - (`post_long_comp')/`comp_len'
add_stars
qui: putexcel `x'6="`r(B)'" `x'7="(`r(se)')"

** Short run, pre period**
check_omitted_events "`pre_short_event'"
local event_len = `r(N)'
check_omitted_events "`pre_short_comp'"
local comp_len = `r(N)'

qui: lincom (`pre_short_event')/`event_len' - (`pre_short_comp')/`comp_len'
add_stars
qui: putexcel `x'10="`r(B)'" `x'11="(`r(se)')"

** Long run, pre period**
check_omitted_events "`pre_long_event'"
local event_len = `r(N)'
check_omitted_events "`pre_long_comp'"
local comp_len = `r(N)'

qui: lincom (`pre_long_event')/`event_len' - (`pre_long_comp')/`comp_len'
add_stars
qui: putexcel `x'12="`r(B)'" `x'13="(`r(se)')"
qui: putexcel `x'14="$n_missing/$tot"

if "`controls'" == "" local ctrl_text "No additional controls"
else local ctrl_text "Controlling for : `controls'"

qui: putexcel A14="Missing Cells^"
qui: putexcel A15="Note: * p <= .1 ** p <= .05 *** p <= .01"  A16="Absorbing: `absorb'. `ctrl_text'"

if "`cluster'" != "" qui: putexcel A17="Standard Errors clustered by `cluster'"
qui: putexcel A18="DDD setup is `by' & `switch' - `by' & `compare'"
qui: putexcel A19="^Groupings by Time x Event x `group_name'"

di "results written to `c(pwd)'/`varlist'_`switch'`tag'.xlsx"
end

capture program drop add_stars
program add_stars, rclass
	if `r(p)' <= .01 local stars "***"
	else if `r(p)' <= .05 local stars "**"
	else if `r(p)' < .1 local stars "*"

	local coef = string(`r(estimate)',"%9.4g")
	local B_se = string(`r(se)',"%9.4g")

	return local B = "`coef'`stars'"
	return local se = `B_se'
end

capture program drop impose_only_male
program impose_only_male
syntax [, Quarters(integer 10) p_length(integer 3)]
keep if female == 0

local max_t = `quarters'*`p_length'
*drop events where destination manager is female
forvalues t = 0/`max_t' {
	foreach switch in N2S N2N S2S S2N {
		if `t' <= 3 cap: bysort own_id (monthn): replace  F`t'_mgr_`switch' = 0 if mgr_fem[_n + `t'] == 1 | mgr_smoke[_n + `t'] == .
		else cap: bysort own_id (monthn): replace  F`t'_mgr_`switch' = 0 if mgr_fem[_n + `t'] == 1 | mgr_smoke[_n + `t'] == .
		if _rc != 0 di "Unable to update  F`t'_mgr_`switch' in impose_only_male"
		bysort own_id (monthn): replace  L`t'_mgr_`switch' = 0 if mgr_fem[_n - `t'] == 1 | mgr_smoke[_n - `t'] == .
	}
}
// foreach switch in N2S N2N S2S S2N {
// 	bysort own_id (monthn): replace  Fend_mgr_`switch' = 0 if mgr_fem[_n + `max_t' + 1] == 1 | mgr_smoke[_n + `max_t' + 1] == .
// 	bysort own_id (monthn): replace  Lend_mgr_`switch' = 0 if mgr_fem[_n - `max_t' - 1] == 1 | mgr_smoke[_n - `max_t' - 1] == .
// }

end


import delimited training.csv, replace 