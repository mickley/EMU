---
title: "Fenton Paired T-tests"
author: "James Mickley"
output:
  html_document:
    keep_md: yes
    theme: readable
  html_notebook:
    theme: readable
graphics: yes
editor_options: 
  chunk_output_type: console
---





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



### PFD

The woods gets less light than the meadow by about 306 µmol/m^2/s


```

	Paired t-test

data:  pfd by transect
t = -56.304, df = 7214, p-value < 2.2e-16
alternative hypothesis: true difference in means is not equal to 0
95 percent confidence interval:
 -316.8756 -295.5530
sample estimates:
mean of the differences 
              -306.2143 
```



### VWC

The woods is drier than the meadow by about 0.13 m^3/m^3


```

	Paired t-test

data:  vwc by transect
t = -178.23, df = 7214, p-value < 2.2e-16
alternative hypothesis: true difference in means is not equal to 0
95 percent confidence interval:
 -0.1387390 -0.1357204
sample estimates:
mean of the differences 
             -0.1372297 
```


### Session Information


```
R version 3.4.3 (2017-11-30)
Platform: x86_64-w64-mingw32/x64 (64-bit)
Running under: Windows 7 x64 (build 7601) Service Pack 1

Matrix products: default

locale:
[1] LC_COLLATE=English_United States.1252 
[2] LC_CTYPE=English_United States.1252   
[3] LC_MONETARY=English_United States.1252
[4] LC_NUMERIC=C                          
[5] LC_TIME=English_United States.1252    

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
 [1] bindrcpp_0.2.2  lubridate_1.7.4 forcats_0.3.0   stringr_1.3.0  
 [5] dplyr_0.7.6     purrr_0.2.4     readr_1.1.1     tidyr_0.8.0    
 [9] tibble_1.4.2    ggplot2_3.0.0   tidyverse_1.2.1

loaded via a namespace (and not attached):
 [1] Rcpp_0.12.16     cellranger_1.1.0 pillar_1.2.2     compiler_3.4.3  
 [5] plyr_1.8.4       bindr_0.1.1      tools_3.4.3      digest_0.6.15   
 [9] jsonlite_1.5     evaluate_0.10.1  nlme_3.1-131     gtable_0.2.0    
[13] lattice_0.20-35  pkgconfig_2.0.1  rlang_0.2.2      psych_1.8.4     
[17] cli_1.0.0        rstudioapi_0.7   yaml_2.1.18      parallel_3.4.3  
[21] haven_1.1.1      withr_2.1.2      xml2_1.2.0       httr_1.3.1      
[25] knitr_1.20       hms_0.4.2        rprojroot_1.3-2  grid_3.4.3      
[29] tidyselect_0.2.4 glue_1.2.0       R6_2.2.2         readxl_1.1.0    
[33] foreign_0.8-69   rmarkdown_1.9    modelr_0.1.1     reshape2_1.4.3  
[37] magrittr_1.5     codetools_0.2-15 backports_1.1.2  scales_0.5.0    
[41] htmltools_0.3.6  rvest_0.3.2      assertthat_0.2.0 mnormt_1.5-5    
[45] colorspace_1.3-2 stringi_1.1.7    lazyeval_0.2.1   munsell_0.4.3   
[49] broom_0.4.4      crayon_1.3.4    
```
