# SYSEN 5300 Solar Panel Code Presentation

Charlotte Pendock, Emma Pellecer, Julianne Berry-Stoelze, Domi Swedek

18 October 2025 

Systems Engineering & Six Sigma

Group: Trucker Gals

**Introduction**:

💡 Our objective was to answer Prompt #3 offered for the October 17th Six Sigma Hackathon, 
which was to design a quality control system to track and mitigate solar panel failure. 
To address this question, we defined the following parameters for what our objective with this code is to be: 

>Primary Audience Member: Operations & Maintenance Technician/Manager at the Solar Farm 

Our R code is meant to have two functions: 

1. *Track* solar panel failures by comparing measured solar flux being collected against the expected solar flux for that region using process control chart checks. 

2. *Predict* solar panel failures due to the finite service lifetime of the panels using typical MTTF analysis with a Weibull lifetime distribution.

This is based off of our main fishbone analysis for what the two root causes of solar panel failures can be narrowed down to: 

![Fishbone Diagram](/cloud/project/Images/fishbone.png "Fishbone Analysis confirming longevity and environmental conditions as main failure modes")

## Analysis

*Calculating Ideal Solar Flux*: 

All analysis was done using solar irradiance equations from *Energy Systems Engineering: Evaluation and Implementation, 4th Edition* by Francis M. Vanek et al. The primary inputs required from the technician
are the following to the main script[2]: 

* *Solar irradiance data* for given region, provided as a .csv. This is a readily measurable quantity 
that is frequently collected from ground based devices like pyranometers, but can also be estimated using satellite data. 
* *Latitude* angle for the location of the farm in New York
* *Tilt Angle* for the solar panels on the farm. 
* *Azimuth Angle* for the solar panels on the farm. 
* *Lambda* for the mean failure rate for the panels on the farm. This is a value that can be found from the manufacturer (or 1/lifetime) and is based on the make and model of the solar panels.
* *Number of solar panels* for the total panel count on the farm.
* *In field solar flux data* to compare what the current output is against what the ideal output should be for that farm location annually, as a .csv input. 
* *Age* for how old the solar panels are in years (assuming all panels were installed at the same time for the purposes of this tool).


to be inputted into the solar flux calculation function: 

![Description of Angles for Solar Panel](/SixSigmaHackathon/Images/Angle Graph.png "Description of Angles for Solar Panel [3]")

>Our Demonstration Solar Farm is Located in Syracuse, New York and runs year round, with a solar panel tilt angle of 30 degrees and a 0 degree azimuth. 

## Input Justification

While we are asking for a larger amount of inputs, we believe that these are relatively reasonable expectations for information that a solar farm already has, 
with the two data collection variables required on their end being the watts data array and information on the solar panel lifetime specifications. Any 
information for the other parameters (tilt of the solar panels on the farm, age of the panels, etc.) should require no additional analysis from the farm's side as they are constant knowns 
based on where the solar farm is and how it is set up. 

## Initial Solar Flux Calculations 

From this information and location, we made the following average solar irradiance per hour plot over the course of 12 months: 

![Ideal Solar Flux Syracuse Over the Year](/cloud/project/Images/Ideal Solar Flux.png "Ideal Syracuse Solar Flux Annually")

Then calculated the solar flux from the given irradiance given the equations below: 

![Solar Panel Equation Chart](/cloud/project/Images/equations.png)



Where Where N is the day of the year starting from January 1, 
𝜔 is the hour angle in degrees (+/- 15 degrees per hour from noon), L is the latitude, I is the available solar flux in that hour from Figure 4.1, 
𝛽 is the tilt angle (+ south, - north), 𝛾 is the azimuth angle (0 is south, 180 is north), 
and In is the solar flux hitting the panel in that hour. All angles are in degrees. 
This ideal data can then be compared against true solar flux being measured at the farm to track any discrepancies and predict/track failures at any of the solar panel locations. 

## Creating Sample Data Arrays

The two sample data arrays that we have representing true solar flux collected are as follows compared to the ideal Syracuse solar flux: 


![Data Arrays with Ideal Solar Flux](/cloud/project/Images/Data Array Graph.png "Data Arrays with ideal Solar Flux")

## Tracking Solar Farm Failures
*Process Control Charts to Quantify Standard Deviation Divergence*


Tracking the performance of the solar panel farms was done by comparing the output power (in units of flux) at the farms per hour per day over the course of the year and comparing it to the calculated ideal solar flux based on the 
location of annual solar irradiation calculated in the graph above. A failure is defined using our process control chart criteria, which flags if a mean for the day drops below the lower control limit.


For each of the two data arrays used, the lower control limit and a weighted moving average were calculated. Only the lower control limit was used as we only care if the solar farm power production drops unexpectedly. A trailing weighted moving average was used to calculate the total statistics from the data set, as the amount of power that the solar farm can produce varies greatly throughout the year due to the seasons and weather trends. From this, the data is processed and flags the need for maintenance if the mean power of solar production for a day drops beneath the lower control limit. Data arrays and script generation for those can be found in /cloud/project/Sample Data & Generation, but are not included in the main customer script. These graphs can be found below:


![Solar Panel Control Chart](/cloud/project/Images/solarpanel1.png "Data Array #1")
![Solar Panel Control Chart](/cloud/project/Images/solarpanel2.png "Data Array #2")


The former graph is based on data set 1 and flags no maintenance necessary. The latter graph, has a drop in solar power production, and the script successfully flags maintenance necessary starting at day 250. 


## Overall Lifespan Reliability Analysis

Now for the second aspect of our project: predicting the overall lifespan for the solar panels and providing a tool to optimize maintenance. The lifetime distribution of the solar panel is based on a Weibull lifetime distribution because it is representative of the slower decay of solar panels early in their lifetimes, and higher decay near the end of their lifetime, around 20-30 years depending on the model and environmental conditions. For the input data, a lambda of 0.04 matches this lifetime, while the Weibull scale parameter c is equal to 1/lambda. A reasonable shape factor of m = 4 was determined based on a balance of expected solar panel degradation throughout its life and expected degradation early in its lifetime [1].

The mttf function calculates the mean time to failure of an individual solar panel based on the MTTF formula for a Weibull distribution shown below. This function uses the parameter c calculated from lambda, the scale factor m, and the R function gamma.

$$
MTTF = c \, \Gamma\left(1 + \frac{1}{m}\right)
$$

The fsolar function calculates the failure probability of a solar panel within the desired time period for the Weibull distribution. For data where the solar panels are not brand new, the following conditional probability formula is used to get the probability of a panel continuing to run given its current age. 
 
$$
F(t) = 1 - e^{-\left(\frac{t}{c}\right)^m}
$$

$$
P(\text{Outcome} = 1 \mid \text{Condition} = 1) = \frac{P(\text{Outcome} = 1 \,\&\, \text{Condition} = 1)}{P(\text{Condition} = 1)}
$$

$$
F_{\text{cond}}(t) = \frac{F(t + \text{age}) - F(\text{age})}{1 - F(\text{age})}
$$

The tsolar function outputs the time at which a given percentage of solar panels are expected to have failed on the solar farm by solving the Weibull failure function for time. For a 5% expected failure of solar panels and 1% total failure the tsolar function outputs the time it will take to reach these failure points. Similar to the fsolar function, conditional probability is used based on the age of the solar panels. These equations are shown below. 

$$
F(t + a) = p \cdot (1 - F(a)) + F(a)
$$

$$
t = c \cdot \left[-\log\left(1 - \left[p \cdot (1 - F(a)) + F(a)\right]\right)\right]^{1/m} - a
$$

Finally, the lifetime_dist function calls both the fsolar and tsolar functions. It uses the fsolar function to graph the lifetime distribution of the solar farm by multiplying the resulting failure probabilities by the total number of solar panels on the farm. The calculated time in years from the tsolar functions are printed for the user to view, as these are convenient markers for required maintenance checks. 

![Expected Solar Panel Failures Over Time Based on Weibull Lifetime Distribution](/cloud/project/Images/Failureplot.png "Expected Solar Panel Failures Over Time Based on Weibull Lifetime Distribution")

## Outputs

The output of this system are three graphs and four printed statements with the following information:

- A graph of the monthly average solar flux through the year for the given location
- A graph of the solar panel flux control chart over time
- A graph of expected number of solar panel failures over time
- A statement of whether maintenance is required and when the issue was noticed, ex. “Maintenance flagged starting at day: 250”
- A statement giving the mean time to failure of the solar panels
- A statement giving the predicted time until 1% of the solar panels on the farm fail
- A statement giving the predicted time until 5% of the solar panels on the farm fail

These outputs are intended to provide a holistic failure tracking and maintenance overview of the solar farm to give a maintenance company insights into the timeline of future maintenance checks and alerts to failed solar panels that should be replaced to keep the solar farm producing at its highest capacity. 


## Final Test Code to Run Functions 

Our function for running our database is main_run.R in our project database, with the following example inputs that our customer would put in to generate 
our analysis: 

```R 
##EXAMPLE RUNS WITH VARIABLE INPUTS 
results_sample1 = finalrun(0.04, 300, "syracuse_hourly.csv", 43, 30, 0,0,"Sample Data & Generation/sampledata1.csv")
results_sample2 = finalrun(0.04, 300, "syracuse_hourly.csv", 43, 30, 0,5,"Sample Data & Generation/sampledata2.csv")

```

## Citations:
[1] Tan, V., Dias, P. R., Chang, N., & Deng, R. (2022). Estimating the Lifetime of Solar 
Photovoltaic Modules in Australia. Sustainability, 14(9), 5336. https://doi.org/10.3390/su14095336

[2] Vanek, F. M., Albright, L. D., Angenent, L. T., Ellis, M. W., & Dillard, D. A. (2021). Energy Systems Engineering: Evaluation and implementation, Fourth edition. McGraw-Hill Education. 

[3] (Image) *Azimuth Angle vs. Tilt Angle on Solar Panel*. GoSolarQuotes. https://gosolarquotes.com.au/azimuth-angle/



## Appendix: 

*Sample Data Array Input* 


| Variable Name  | Units/Type       | Example Value |  Description|         
| :---            | :---------  | :------------ |:----|
| Day          | days/numeric          | 5            | Days throughout the year |
| Hour          | hours/numeric          | 22            | Increasing total hours throughout the year|
| Irradiance         | Watts/m^2/numeric        | 80.42   |Total energy that can be emitted by the sun |
| Month         | months/numeric          | 3            | Current month in the year|
| omega          | angle/numeric          | -180            |Hour angle in degrees |
| delta          | angle/numeric          | -23            |Solar declination angle |
| alpha_s          | angle/numeric          | 12            |Solar altitude angle|
| gamma_s         | angle/numeric          | -15            |Solar azimuth angle|
| theta_i          | angle/numeric          | 95°            |Angle of incidence to the surface|
| IncidentFlux          | W/m^2/numeric          | 273.76            |Total solar flux  whole solar panel farm (sum of flux from all zones)|
| ZoneFluxes_Zone1        | W/m^2/numeric  | 23.18   | Total flux for for zone 1 of solar panel farm|
| ZoneFluxes_Zone2        | W/m^2/numeric          | 178.61            |Total flux for for zone 2 of solar panel farm |
| ZoneFluxes_Zone3        | W/m^2/numeric          | 12.92            |Total flux for for zone 2 of solar panel farm |
| ZoneFluxes_Zone4        | W/m^2/numeric          | 79.32            | Total flux for for zone 2 of solar panel farm|
| ZoneFluxes_Zone5        | W/m^2/numeric          | 245.12            | Total flux for for zone 2 of solar panel farm|

*Solar Irradiance Input*

| Variable Name  | Units/Type       | Example Value |  Description|         
| :---            | :---------  | :------------ |:----|
| Day          | days/numeric          | 5            | Days throughout the year |
| Hour          | hours/numeric          | 22            | Increasing total hours throughout the year|
| Irradiance         | Watts/m^2/numeric        | 80.42   |Total energy that can be emitted by the sun for the chosen area|


read_html("https://emmapellecer.github.io/SixSigmaHackathon/README.html")

