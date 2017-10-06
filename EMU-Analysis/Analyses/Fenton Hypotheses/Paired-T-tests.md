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


### Session Information


```
R version 3.4.0 (2017-04-21)
Platform: x86_64-apple-darwin15.6.0 (64-bit)
Running under: OS X El Capitan 10.11.6

Matrix products: default
BLAS: /Library/Frameworks/R.framework/Versions/3.4/Resources/lib/libRblas.0.dylib
LAPACK: /Library/Frameworks/R.framework/Versions/3.4/Resources/lib/libRlapack.dylib

locale:
[1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] bindrcpp_0.2    dplyr_0.7.1     tidyr_0.6.3     lubridate_1.6.0

loaded via a namespace (and not attached):
 [1] Rcpp_0.12.11     assertthat_0.2.0 digest_0.6.12    rprojroot_1.2   
 [5] R6_2.2.2         backports_1.1.0  magrittr_1.5     evaluate_0.10   
 [9] rlang_0.1.1      stringi_1.1.5    rmarkdown_1.6    tools_3.4.0     
[13] stringr_1.2.0    glue_1.1.1       yaml_2.1.14      compiler_3.4.0  
[17] pkgconfig_2.0.1  htmltools_0.3.6  bindr_0.1        knitr_1.16      
[21] tibble_1.3.3    
```
