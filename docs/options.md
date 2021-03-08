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

`window(start end [, options])`
:   display dynamic effect estimates (event-time coefficents) ranging from `start` to `end`. `start` should be less than zero; `end` should be greater than zero. 

:   `window` recognizes four suboptions that control how endpoints (i.e. periods *outside* the window) should be treated. By default, `esplot` will fully saturate the model with relative time indicators for every possible period, except for the omitted period (t = -1). The `bin`, `bin_pre`, and `bin_post` cause endpoints to be binned; see below for more information.
 
    ??? info "endpoint suboptions (for window)"  
        `saturate`
        :   default option, equivalent to typing nothing. `esplot` will find the maximum and minimum relative time periods supported in the data (i.e. the last period in the data minus the earliest event, and the first period in the data minus the latest event.) Then `esplot` will fully saturate the model will all possible relative time periods. Some of these coefficients may not be well identified (some may even drop out).

        `bin`
        :   Define an indicator for $j <$ start and an indicator for $j >$ end, where $j$ is relative time. Rather than including all possible event-time indicators, we "bin" all event-time indicators before/after the window starts/ends. Thus, rather than estimating the full set of dynamic effects, we estimate dynamic effects only within the specified window, and estimate (but do not plot) constant long-run effects before and after the window. 

        `bin_pre`
        :   Define an indicator for $j <$ start, but use all possible post-event relative time indicators for estimation. 

        `bin_post`
        :   Define an indicator for $j >$ end, but use all possible pre-event relative time indicators for estimation. 

        **Further reading**

        There is a very active applied econometric literature concerning the correct specification of event-study estimates. 

        [Baker, Larcker, & Wang, 2021](https://dx.doi.org/10.2139/ssrn.3794018) show that binned and saturated models can lead to substantively different estimates, especially in the presence of pre-trends. `esplot` therefore makes both options available to users.

        It uses the fully saturated model as the default since this enforces the least structure on the research design. [Borusyak & Jaravel, 2018](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2826228) argue that the fully saturated model is most robust to long run pre- and post- trends, since it does not impose a parametric assumption on dynamic effects before/after a given period.  

        Researchers are then, of course, free to impose that structure as a design choice with any of the three variants of the window sub-options. [Schmidheiny & Siegloch, 2020](https://hdl.handle.net/10419/215676) show that imposing the structure implied by binning (i.e. that effects are constant before/after some periods) can improve identification of time fixed effects. 





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

`vce(vcetype, subopt)`
:   specify the types of standard errors computed. `help reghdfe##opt_vce` for more information. Not compatible with `quantile`.

`quantile(0 < k < 100)`
:   if this option is specified, `esplot` will use a quantile regression, rather than OLS. `quantile(50)` and `quantile(.5)` are synonyms, and will cause `esplot` to estimate a median regression. 

weights are allowed when using OLS (default), but not when `quantile` is specified. 

### Display Options 

`period_length(integer)` 
:   pool dynamic effect coefficients in groups of `period_length` before plotting. 

`colors(colorstylelist)`
:   ordered list of colors; used for point estimates and confidence intervals.  


Additional `twoway` options can be specified and will be passed through to the internal `twoway` call. `help twoway_options`