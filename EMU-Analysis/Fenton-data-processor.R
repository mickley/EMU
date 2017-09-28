##### EMU Data Processor Script for Fenton data #####
# This takes a folder full of EMU, hobo, & iButton data files and makes 
# a composite data file
#
# It converts timestamps to text date/time and adds site/transect data
#
#####################################


# Load libraries required to data wrangle
require(tidyr)
require(dplyr)
require(lubridate)


#### Light & Soil Calibration Data ####

soil.cal <- read.csv("Analyses/Calibration/soil-calibration.csv")
light.cal <- read.csv("Analyses/Calibration/light-calibration.csv")


#### iButton Data ####
    
# Data folder
datafolder = "Data/EMU-6-21/"

# Read in the iButton data
ibuttons <- read.csv("Data/EMU-6-21/ibuttons-combined.csv") %>%

    # Add the source column and convert the timestamp to POSIXct class
    mutate(source = "iButton", 
        timestamp = as.POSIXct(timestamp, tz = "America/New_York"))

#### EMU Data ####


# Get a list of EMU data files from the folder
emus <- list.files(path = datafolder, pattern = "*-data.csv")

# Make an empty dataset
emu = data.frame()
    
# Process each data file one at a time
for (file in emus) {

    # Get the EMU name from the filename
    name = strsplit(file, "-")[[1]][1]
    
    # Read the datafile in from csv
    tmp <- read.csv(paste(datafolder, file, sep = "")) %>% 
        
        # Add a column for the emu name
        mutate(emu = name)
    
    # append this emu's data onto the dataset
    emu <- rbind(emu, tmp)

}
 
# Read in the site data
sites <- read.csv("Data/emu-sitedata-v2.csv", stringsAsFactors = F)


#### Hobo Microstation Data ####


# Get a list of EMU data files from the folder
micros <- list.files(path = datafolder, pattern = "*_sta.csv")

# Make an empty dataset
micro = data.frame()

# Process each data file one at a time
for (file in micros) {
    
    # Get the transect name from the filename
    name <- strsplit(file, "_")[[1]][1]
    
    # Read the datafile in from csv
    tmp <- read.csv(paste(datafolder, file, sep = "")) %>% 
        
        # Add a column for the transect name
        mutate(hobo = name)
    
    # Append this microstation's data onto the dataset
    micro <- rbind(micro, tmp)
    
}

# Wrangle the microstation data
micro <- micro %>%
    
    # Add columns for site, data source, and transect order
    mutate(source = "Hobo", type = "Micro") %>%

    # Convert the timestamp to POSIXct class
    mutate(Time = as.POSIXct(Time, format = "%m/%d/%y %I:%M:%S %p", 
        tz = "America/New_York")) %>%
    
    # Get lat and long from sites csv
    left_join(sites, by = "hobo") %>%
    
    # Select, rename, and order the columns
    select(timestamp = Time, site, transect, order, lat, long, 
        source, type, par = PAR, vwc = Water.Content)


#### Hobo Pendant Data ####


# Get a list of EMU data files from the folder
pendants <- list.files(path = datafolder, pattern = "F*[1-4].csv")

# Make an empty dataset
pendant = data.frame()

# Process each data file one at a time
for (file in pendants) {
    
    # Get the hobo pendant name from the filename
    name <- strsplit(file, ".csv")[[1]][1] 
    
    # Read the datafile in from csv
    tmp <- read.csv(paste(datafolder, file, sep = "")) %>% 
        
        # Add a column for the hobo name
        mutate(hobo = as.character(name))
    
    # Append this pendants's data onto the dataset
    pendant <- rbind(pendant, tmp)
    
}

# Wrangle the pendant data
pendant <- pendant %>%
    
    # Add a column for data source and hobo type
    mutate(source = "Hobo", type = "Pendant") %>%
    
    # Convert the timestamp to POSIXct class
    mutate(Time = as.POSIXct(Time, format = "%m/%d/%y %I:%M:%S %p", 
        tz = "America/New_York")) %>%
    
    # Get lat and long from sites csv
    left_join(sites, by = "hobo") %>%
    
    # Select, rename, and order the columns
    select(timestamp = Time, site, transect, order, lat, long, 
           source, type, temperature = Temp)


##### Combine Datasets & Wrangle #####
soilint = soil.cal$intercept
soilint

# Manipulate the data
data <- 
    
    
    emu %>%
    
    # Add source column
    mutate(source = "EMU", type = NA) %>%
    
    # Convert timestamp to text date
    mutate(Timestamp = as.POSIXct(Timestamp, origin = "1970-01-01", 
        tz = "America/New_York")) %>%
        
    # Convert column names to lowercase
    `names<-`(tolower(names(.))) %>%
    
    # Join the emu and site specific data
    left_join(sites, by = "emu") %>%
    
    # Replace -100 with NAs for EMU data
    mutate(
        temperature = replace(temperature, temperature < -40, NA), 
        humidity = replace(humidity, humidity == -100, NA), 
        light = replace(light, light == -100, NA), 
        soil = replace(soil, soil == -100, NA)) %>%

    # Add vwc based on fenton soil calibration
    mutate(vwc = soil.cal$intercept + soil.cal$soil * soil + 
        soil.cal$soil.squared * (soil ^ 2)) %>%

    # Add par based on LiCor light calibration
    mutate(par = light.cal$intercept + light.cal$lux * light + 
        light.cal$lux.squared * (light ^ 2)) %>%

    # Add iButton data
    bind_rows(ibuttons, micro, pendant) %>%

    # Add additional date/time columns
    mutate(
        # Days since start
        day = floor(interval(as.POSIXct("2017-05-30"), timestamp) / ddays(1)),
        
        # Hours since start
        hour = floor(interval(as.POSIXct("2017-05-30 12:00"), timestamp) / dhours(1)),
        
        # Minutes since start
        minute = floor(interval(as.POSIXct("2017-05-30 12:00"), timestamp) / dminutes(1)),
        
        # Hour of the day
        day.hr = hour(timestamp),
        
        # Minute of the day
        day.min = minute(timestamp) + (day.hr * 60)
        ) %>%

        
    # Reorder columns
    select(site, transect, order, lat, long, source, type, emu, timestamp, day, hour, 
           minute, day.hr, day.min, temperature, 
           humidity, vwc, par, light, soil, pressure, voltage) %>%
            
    # Filter out all data points that aren't on a 15-minute interval
    filter(minute(timestamp) == 0 | minute(timestamp) == 15 | 
            minute(timestamp) == 30 | minute(timestamp) == 45) %>%
    
    # Filter out all data before the start of the respective sites
    filter(
        
        # Start time for the two Fenton transects
        (site == "Fenton" & 
            timestamp >= as.POSIXct("2017-05-30 13:30")), 
        
        # End time for the two Fenton transects
        (site == "Fenton" & 
             timestamp <= as.POSIXct("2017-06-21 12:45"))

        # Start time for the Fenton transects
        #(site == "Fenton" & 
        #    timestamp >= as.POSIXct("2017-04-15 14:45")) |
            
        # Start time for the third HEEP transect
        #(site == "HEEP" & transect == "Forest" & 
        #    timestamp >= as.POSIXct("2017-05-02 10:00"))
        
        ) %>%
    
    
    
    # Arrange the dataset
    arrange(site, transect, order, source, type, timestamp)


# Write out data to csv
write.csv(data, file = paste(datafolder, "fentondata-all.csv", sep = ""), row.names = F)

# Write out a message
cat(paste("Datafiles processed to: ", datafolder, "fentondata-all.csv", sep = ""))

