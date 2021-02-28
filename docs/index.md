# Getting Started  

Event study plots are increasingly popular in applied research. `esplot` is a new command for stata allowing researchers to quickly and easily create event study plots.


## Install

1. Install from within stata

    `net install esplot, from("https://raw.githubusercontent.com/dballaelliott/esplot/pkg/")`

2. Download/clone from github

   The github repository can be found [here](https://github.com/dballaelliott/esplot).

## Two options for syntax 

`esplot` is flexible and provides the user with two alternative ways of specifying the event study. 

If we don't have panel data, we simply use the syntax 

`esplot <outcome> <event_time>`

where the `event_time` variable is simply the time of the observation relative to treament (or the event). 

??? example "example: state minimum wage laws" 
    Let's assume we are measuring the effect of minimum wage laws on wage. For the sake of this example, let's say that two states, `CA` and `NY`, have minimum wage increases in 2011 and 2010, respectively. Thus, an observation in `CA` in 2010 would have `event_time` = -1, but an observation in `NY` in 2010 would have `event_time` = 0. 

    We would then simply use the syntax:  
    `esplot wage event_time`.

    | state | year | event_time | wage |
    |-------|------|------------|------|
    | CA    | 2010 | -1         | 10   |
    | CA    | 2011 | 0          | 12   |
    | CA    | 2012 | 1          | 12   |
    | CA    | 2012 | 1          | 15   |
    | CA    | 2009 | -2         | 11   |
    | NY    | 2009 | -1         | 10   |
    | NY    | 2010 | 0          | 15   |
    | NY    | 2011 | 1          | 15   |
    | NY    | 2010 | 0          | 17   |

If we **do** have panel data, then `esplot` has more powerful options. 
In this paradigm, we call `esplot` with the following syntax: 

`esplot <outcome>, event(<event_indicator>)`

Behind the scenes, `esplot` will transform the data to create a vector of event-time indicators. In this paradigm, the `event_indicator` variable should evaluate to 1 in periods where a unit experiences an event and zero elsewhere.  `esplot` has additional features that are reserved for panel data. Currently, the `compare` option is only available when using panel data. 

### event_time vs. event_indicator  variables

A common source of error when using `esplot` is the incorrect definition of and `event_time` or `event_indicator` variable. 

With panel data and `esplot <outcome>, event(<event_indicator>)` syntax, the `event_indicator` variable should be defined as 

`event_indicator = <current_time> == <time of event>`

When using `esplot <outcome> <event_time>` syntax, the `event_time` variable should be defined as 

`event_time = <current_time> - <time of event>`

### unlocking esplot with panel data

With panel data, we have the additional option `compare`, allowing us to estimate a difference-in-difference event study. The syntax 

`esplot <outcome>, event(<event_indicator>) compare(<alt_event_indicator>)`

will return an event study plot of the difference between the `event` coefficients and the `compare` coefficents. For example, this framework can be used to compare the productivity effect of assigning a unit a high-skill manager, relative to a low skill manager.

<!-- *In the current build, this option is only available when using the panel syntax* -->

Additionally, `esplot` appropriately handles sources of common mistakes when manually generating a relative time variable, such as when some units have more than one event (or no event at all). 

<!-- (hint: we should then have an individual ID and a time index (e.g. month, day, minute)) -->

## Advanced 

#### Accessing Regression Output 

In `esplot 0.9.3`  (March, 2021) and later, the internal `reghdfe` call is made available to be user. Typing `estimates` after `esplot` is done running will print the regression output and save the return objects to `e()` and `r()`. This allows `esplot` estimates to be used with post-estimation commands, like `test` and `eststo`/`esttab`. 

See `help reghdfe` for more information on the information that is returned.  

Note that because of the technical implementation, the estimates are stored and then reloaded; this means that `e(sample)` cannot be used (see `help estimates use` for more information.) The `save_sample` option is provided as a workaround. 

