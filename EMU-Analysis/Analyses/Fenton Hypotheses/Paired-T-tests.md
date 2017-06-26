# Fenton Paired T-tests
James Mickley  





## Overview

Paired T-tests between the two transects.  These pair observations by timestamp and order within the transect.  Any times/orders without paired data are thrown out.  

The difference in means is relative to the Woods transect 








### Temperature

The woods is 1.8 ºC cooler than the meadow


```

	Paired t-test

data:  temperature by transect
t = -26.222, df = 5819, p-value < 2.2e-16
alternative hypothesis: true difference in means is not equal to 0
95 percent confidence interval:
 -1.968443 -1.694588
sample estimates:
mean of the differences 
              -1.831515 
```


### Humidity

The woods is 3.4% more humid than the meadow


```

	Paired t-test

data:  humidity by transect
t = 21.041, df = 5820, p-value < 2.2e-16
alternative hypothesis: true difference in means is not equal to 0
95 percent confidence interval:
 3.119606 3.760637
sample estimates:
mean of the differences 
               3.440122 
```



### PAR

The woods gets light than the meadow by about 243 µmol/m^2/s (17300 lux)


```

	Paired t-test

data:  par by transect
t = -54.885, df = 7214, p-value < 2.2e-16
alternative hypothesis: true difference in means is not equal to 0
95 percent confidence interval:
 -251.7498 -234.3867
sample estimates:
mean of the differences 
              -243.0683 
```



### VWC

The woods is drier than the meadow by about 0.19 ml/cm^3


```

	Paired t-test

data:  vwc by transect
t = -169.67, df = 7214, p-value < 2.2e-16
alternative hypothesis: true difference in means is not equal to 0
95 percent confidence interval:
 -0.1961229 -0.1916428
sample estimates:
mean of the differences 
             -0.1938829 
```


