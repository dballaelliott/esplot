_version alpha-1_

# esplot {hline 2} event study plots

## Syntax

> __esplot__ varname [_if_] [_in_]
[_weight_], _event(varname [, suboptions]_) [_options_ ]  

_or_

> __esplot__ outcome [_if_] [_in_]
[_weight_], _event(varname [, suboptions]_) [_options_ ]  
  # Documentation

## Core Syntax 

__esplot__ can be called one of two ways. 

1. with an event-time variable:

    _esplot <outcome> <event_time> [, options]_

2. or with an event indicator (on panel data):

    _esplot <outcome>, event(<event_indicator> [, options])_

## Options  

### General Options  

> __compare(<event_indicator> [, options])__ _Only available when using the event(<event_indicator>) syntax._ Plot the _difference_ between the event-time coefficents associated with the event in _event_ and the event given in _compare_. For example, _esplot infected, event(treatment) compare(placebo)_ will estimate event-time coefficents around the _treatment_ event and the _placebo_ event and will plot the difference between the _treatment_ and _placebo_ arms.  

#### event_indicator suboptions (for compare and event)
  
> __save__ this causes the vector of relative-time indicators created by _esplot_ around the event given in either _event_ or _compare_ to be saved to memory. This option is useful when running many specifications of the same event study, as it can save time when used with _nogen_ by creating this vector only once.  
  
> __nogen__ this vector tells _esplot_ that the vector of relative-time indicators around this particular event already exist (probably after being created by an earlier call to _esplot_ with the _save_ option.)  

> __replace__ allows _esplot_ to write over the existing vector of relative-time indicators (rarely used.)  

> __by(varname)__ estimate coefficents seperately for each level of _by_. For example, _esplot wage years_since_policy, by(education)_ will estimate the event-time coefficients for the relative time given in _years_since_policy_ seperately for each level of _education_ and plot as many series as there are levels of education. 

> __difference__ estimate coefficents relative to the base-level of _by_. For example, if _education_ has _k_ levels, then typing _esplot wage years_since_policy, by(education)_ will estimate the event-time coefficients for the relative time given in _years_since_policy_ seperately for each level of _education_ and plot the difference between each of the _k-1_ sets of event-time coefficients and the base level of the _by_ variable.

> Using _difference_ in combination with _compare_ allows for the estimation of difference-in-difference-in-difference coefficients. 

> __estimate_reference__  by default, _esplot_ includes indicator variables for all relative time periods except for -1. If the _estimate_reference_ option is specified, the indicator for -1 is included and explicitly differenced out of the rest of the coefficients. When used with _by_, it recenters each series indepently, so that each series is mechanically 0 at time -1.

> __savedata(filename [,replace])__  in addition to plotting directly, _esplot_ will save the estimated coefficients to _filename_. This allows for the greatest flexibility in plotting the estimates. Coefficents are saved _after_ applying all operations, like differencing (_difference_ or _compare_), or pooling (_period_length_). Can be abbreviated _save(...)_.

> __save_sample(varname)__ store the output of _e(sample)_ in _varname_ following the internal regression call. 

### Regression Options 

> __controls(varlist)__ additional control variables to be included in the internal regression call.

> __absorb(varlist)__ a vector of fixed effects to absorbed and not estimated in the internal regression call. _help reghdfe##absvar_ for more information. 

> __vce(vcetype, subopt))__ specify the types of standard errors computed. _help reghdfe##opt_vce_ for more information. Not compatible with _quantile_.

> __quantile(0 < k < 100)__ if this option is specified, _esplot_ will use a quantile regression, rather than OLS. _quantile(50)_ and _quantile(.5)_ are synonyms, and will cause _esplot_ to estimate a median regression. 

> weights are allowed when using OLS (default), but not when _quantile_ is specified. 

### Display Options 

> __window(start end)__ display dynamic effect estimates (event-time coefficents) ranging from _start_ to _end_. _start_ should be less than zero; _end_ should be greater than zero. 

> __period_length(integer)__ pool dynamic effect coefficients in groups of _period_length_ before plotting. 

> __colors(colorstylelist)__ ordered list of colors; used for point estimates and confidence intervals.  


Additional _twoway_ options can be specified and will be passed through to the internal _twoway_ call. _help twoway_options_
More complicated options are discussed below.  
  
### Relative Event-Study Coefficients with difference and compare

__esplot__ has two suboptions to estimate and "difference out" reference coefficients; __difference__ and __compare__: 

> __difference__ plots all series relative to the base level of __by__. It is helpful here to consider an example; let __by__ be a dummy variable that is 1 when the individual is a female, 0 when it is a male. By default, passing this variable to __by__ will cause two series to be estimated: one set of coefficients for males, and one for females. However, perhaps we are mainly interested in the difference in response across genders. Then, we could select the __difference__ option. __esplot__ will then estimate the male and female coefficients, but will plot their difference (female - male) in every period. 

>NB: when a using a factor variable with more than two levels with __by__, stata treats the _lowest_ value as the base case. At this time, to change the reference category, it is neccessary to create a new variable where the desired reference category is the lowest value. In the above example, we would use an indicator variable for "is male" rather than one for "is female".

> __compare__ takes an additional event dummy, and estimates the main event coefficients relative to this event. Here, it is also helpful to consider an example from [Cullen & Perez-Truglia, 2019](https://www.nber.org/papers/w26530). Cullen & Perez-Truglia use the quasi-random rotation of managers across units to identify the effects of manager gender on the career progression of male and female employees. For example, they consider the effect of switching from a female manager to male manager _relative_ to switching from a female manager to another female manager. This would be coded as __... event(to_male_manager) compare(to_female_manager)...__. By including the comparison event, the authors adjust for the effects of switching managers _per se_ and isolate the differences associated with the gender of the manager. 

> __compare__ and __difference__ can be used together. See [Cullen & Perez-Truglia, 2019](https://www.nber.org/papers/w26530) for an in depth discussion, examples, and econometric specification

### Efficiently Estimating Many Event-Study Plots: save, replace, nogen

__event__ (and __compare__) have the sub-options __save__, __nogen__, and __replace__, which are of primary use when estimating multiple specifications, or multiple outcomes. These options save, (and then subsequently read from the data in memory), event "lags and leads". The __replace__ example is provided for completeness, but should be used with caution, as it overwrites "lags and leads" saved in memory. By default, __esplot__ does not change the data in memory. 

> __save__ saves event lags _L<t>_<event>_ (or _L<t>_<compare>_) and leads _F<t>_<event>_ (or _F<t>_<compare>_). This sub-option can be selected for either, or both __event__ and __compare__.

> __nogen__ tells __esplot__ that lags and leads of the above form are present in the data in memory (often as a result of selecting __save__ on an earlier run) and that it should use the lags and leads in memory. If lags and leads are present and __nogen__ (or __replace__ ) is not selected, __esplot__ will throw an error.

> __replace__ tells __esplot__ that lags and leads are present in the data and that it should overwrite them. This option should be used with caution, especially when lags and leads are user defined. There are two primary use-cases for __replace__, most often used with __save__. 
 
> - if an earlier __esplot__ call used __save__, and the __window__ is adjusted. This is because __esplot__ calculates lags and leads only up to the endpoints given in __window__. (Example 2)

> - if an earlier __esplot__ call used __save__, and you now wish to use __estimate_reference__ (or vice versa). Since, __esplot__ only keeps the lags and leads that it needs, if __save__ is used without __estimate_reference__, then the necessary leads for the omitted periods will not be saved. (Example 3)

#### Examples with save, replace, and nogen

__Example 1__  
/_ event lags and leads are saved _/  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) estimate_reference}  
/_ esplot saves time by simply using the lags/leads from the previous call _/  
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}  

__Example 2__  
/_ event lags and leads are saved _/  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3) estimate_reference}  
/_ esplot saves time by simply using the lags/leads from the previous call _/  
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}  
/_we wish to expand the window of the first plot. we tell esplot that it will find lags and leads in memory, but it can ignore and overwrite them _/  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, replace) window(-40 60) period(6) estimate_reference}

__Example 3__  
/_ event lags and leads are saved _/  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3)}  
/_ esplot saves time by simply using the lags/leads from the previous call _/  
{cmd:. esplot ln_sal, by(male) event(to_male_mgr, nogen) window(-20 30) period_length(3)}  
/_ There are differences in levels between males and females; we would like both series to go through the origin at t = -1.
we now want to use estimate_reference, 
so we tell esplot that it will find lags and leads in memory, but it can ignore and overwrite them _/  
{cmd:. esplot paygrade, by(male) event(to_male_mgr, save) window(-20 30) period(3) estimate_reference}  

## Remarks

See [website](https://dballaelliott.github.io/esplot/) for further discussion and for examples.

## Acknowledgements

Katherine Fang and Jenna Anders made extensive contributions to early versions of the underlying code, which this package extends. Any remaining errors are mine.

## Author 

Dylan Balla-Elliott  
Research Associate, Harvard Business School  
dballaelliott@gmail.com  
[github](https://github.com/dballaelliott) | [twitter](https://twitter.com/dballaelliott)

## Additional Features

Bug-fixes, feature requests, and general comments are welcome via email, or directly as issues on github.  

I currently plan on adding support for :  
    - additional plot options

Extensions via forks/pull requests by github users are welcomed.  

- - -

This help file was dynamically produced by 
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) 
