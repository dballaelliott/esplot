version 14.1

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
tokenize `program', parse(",")
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
/* 
capture program drop log_wrapper
program log_wrapper
syntax, EXECUTE_these(string) [depth(integer 1)]
/*
log_wrapper is a simple wrapper that take a list of commands 
as they would be typed interactively and passes them to log_program. 

EXECUTE_these() should recieve a command as it would be typed interactively.

NOTE: This program has a known issue with splitting on white space in the for-loop.
options may be specified without issue, provided there are no spaces.

i.e. reg y x, robust will fail where reg y x,robust will run. 

*/

di "called log_wrapper"

foreach p in `execute_these' {
	di `" calling `p' "'
	log_program, program(`p') depth(`depth')
}
end */
