# Documentation

## Core Syntax 

`esplot` can be called one of two ways. 

1. with an event-time variable:

    `esplot <outcome> <event_time> [, options]`

2. or with an event indicator (on panel data):

    `esplot <outcome>, event(<event_indicator> [, options])`

## Options 

### General Options 

`compare(<event_indicator> [, options])`
:   **Only available when using the `event(<event_indicator>)` syntax.**
    Plot the *difference* between the event-time coefficents associated with the event in `event` and the event given in `compare`. For example, `esplot infected, event(treatment) compare(placebo)` will estimate event-time coefficents around the `treatment` event and the `placebo` event and will plot the difference between the `treatment` and `placebo` arms. 

    ??? info "event_indicator suboptions (for compare and event)"  
    
        `save`
        :   this causes the vector of relative-time indicators created by `esplot` around the event given in either `event` or `compare` to be saved to memory. This option is useful when running many specifications of the same event study, as it can save time when used with `nogen` by creating this vector only once. 

        `nogen`
        :   this vector tells `esplot` that the vector of relative-time indicators around this particular event already exist (probably aftering being created by an earlier call to `esplot` with the `save` option.)

        `replace` 
        :   allows `esplot` to write over the existing vector of relative-time indicators (rarely used.)

        **example**

            esplot income, event(treatment, save)       // saves indicators...
            esplot ln_income, event(treatment, nogen)   // use saved indicators 

`by(varname)`
:   estimate coefficents seperately for each level of `by`. For example, `esplot wage years_since_policy, by(education)` will estimate the event-time coefficients for the relative time given in `years_since_policy` seperately for each level of `education` and plot as many series as there are levels of education. 

`difference`
:   estimate coefficents relative to the base-level of `by`. For example, if `education` has $k$ levels, then typing `esplot wage years_since_policy, by(education)` will estimate the event-time coefficients for the relative time given in `years_since_policy` seperately for each level of `education` and plot the difference between each of the $k-1$ sets of event-time coefficients and the base level of the `by` variable.

    Using `difference` in combination with `compare` allows for the estimation of difference-in-difference-in-difference coefficients. 

`estimate_reference` 
:   by default, `esplot` includes indicator variables for all relative time periods except for -1. If the `estimate_reference` option is specified, the indicator for -1 is included and explicitly differenced out of the rest of the coefficients. When used with `by`, it recenters each series indepently, so that each series is mechanically 0 at time -1.

`savedata(filename [,replace])`
:   in addition to plotting directly, `esplot` will save the estimated coefficients to `filename`. This allows for the greatest flexibility in plotting the estimates. Coefficents are saved *after* applying all operations, like differencing (`difference` or `compare`), or pooling (`period_length`). Can be abbreviated `save(...)`.

`save_sample(varname)`
:   store the output of `e(sample)` in `varname` following the internal regression call. 

### Regression Options 

`controls(varlist)`
:   additional control variables to be included in the internal regression call.

`absorb(varlist)`
:   a vector of fixed effects to absorbed and not estimated in the internal regression call. `help reghdfe##absvar` for more information. 

`vce(vcetype, subopt))`
:   specify the types of standard errors computed. `help reghdfe##opt_vce` for more information. Not compatible with `quantile`.

`quantile(0 < k < 100)`
:   if this option is specified, `esplot` will use a quantile regression, rather than OLS. `quantile(50)` and `quantile(.5)` are synonyms, and will cause `esplot` to estimate a median regression. 

weights are allowed when using OLS (default), but not when `quantile` is specified. 

### Display Options 

`window(start end)`
:   display dynamic effect estimates (event-time coefficents) ranging from `start` to `end`. `start` should be less than zero; `end` should be greater than zero. 

`period_length(integer)` 
:   pool dynamic effect coefficients in groups of `period_length` before plotting. 

`colors(colorstylelist)`
:   ordered list of colors; used for point estimates and confidence intervals.  


Additional `twoway` options can be specified and will be passed through to the internal `twoway` call. `help twoway_options`