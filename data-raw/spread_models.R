library(DATRASextra)
library(tidyverse) #:P
library(here)

#devtools::load_all()

surveys <- c("NS-IBTS", "EVHOE", "SWC-IBTS", "BITS", "IE-IGFS",
             "FR-CGFS", "NIGFS", "ROCKALL", "PT-IBTS",
             "SP-NORTH", "SP-ARSA", "SP-PORC")

# create temporary directory
tmp <- tempdir()

# download
download_datras(surveys = surveys, dir = tmp)

# read in
raw <- read_datras(file.path(tmp, surveys))

# only hh
hh <- raw[['HH']] 

# remove unwanted gears 
hh <- hh %>% filter(
  !(Survey == "NS-IBTS" &
      Gear %in% c('ABD','BOT','DHT','FOT','GRT',
                  'H18','HOB','HT','KAB','VIN')),
  !(Survey == "BITS" &
      Gear %in% c('CAM','CHP','DT','EGY','ESB',
                  'EXP','FOT','GRT','H20','HAK',
                  'LBT','SON')),
  !(Survey == "PT-IBTS" & Gear == "CAR")) %>% filter(HaulVal %in% c("V","N")) # change this with clean_datras()

# lms adapted from https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/source_DATRAS_wing_doorspread.R

# Global manual corrections -----------------------------------------------
# need to do the same in the predict functions
hh$WingSpread[hh$WingSpread == 0] <- NA
hh$DoorSpread[hh$DoorSpread == 0] <- NA
hh$Distance[hh$Distance == 0] <- NA
hh$SweepLngt[hh$SweepLngt == 0] <- NA # this is not present in FishGlob


# remove outliers  --------------------------------------------------------

hh <- hh %>%
  group_by(Survey, Gear) %>%
  mutate(
    ds_q1 = quantile(DoorSpread, 0.25, na.rm = TRUE),
    ds_q3 = quantile(DoorSpread, 0.75, na.rm = TRUE),
    ds_iqr = ds_q3 - ds_q1,
    ds_low = ds_q1 - 1.5 * ds_iqr,
    ds_high = ds_q3 + 1.5 * ds_iqr,
    
    ws_q1 = quantile(WingSpread, 0.25, na.rm = TRUE),
    ws_q3 = quantile(WingSpread, 0.75, na.rm = TRUE),
    ws_iqr = ws_q3 - ws_q1,
    ws_low = ws_q1 - 1.5 * ws_iqr,
    ws_high = ws_q3 + 1.5 * ws_iqr
  ) %>%
  filter(
    is.na(DoorSpread) | (DoorSpread >= ds_low & DoorSpread <= ds_high),
    is.na(WingSpread) | (WingSpread >= ws_low & WingSpread <= ws_high)
  ) %>%
  ungroup() %>%
  select(-starts_with("ds_"), -starts_with("ws_"))

# North Sea ---------------------------------------------------------------
ns <- subset(hh, Survey == "NS-IBTS")

#ns$SweepLngt <- as.numeric(ns$SweepLngt)
#ns$SweepLngt[ns$SweepLngt > 110] <- NA # too high
#ns$SweepLngtCat <- ifelse(ns$SweepLngt >= 40 & ns$SweepLngt <= 68,
#                          "short", "long")
# SweepLngt has some problems, better not use it. I am gonna use depth instead
#ns$SweepLngt[is.na(ns$SweepLngt)] <- 60 # if you don't know, it's 60 FISHGLOB
# convert sweep length into factor short/long as in https://www.ices.dk/data/Documents/DATRAS/NS-IBTS_swept_area_km2_algorithms.pdf#page=1.06 short is 50/60 long is 100/110 m

# DoorSpread model https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L71
door_ns_primary <- lm(
  DoorSpread ~ log(Depth) + Ship,
  data = ns
)

door_ns_fallback <- lm(
  DoorSpread ~ log(Depth) + Country,
  data = ns
)

door_ns_fallback2 <- lm(
  DoorSpread ~ log(Depth),
  data = ns
)

ns$WingSpread[ns$WingSpread==50] <- NA # https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L93

# WingSpread model https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L92
wing_ns <- lm(
  WingSpread ~ log(Depth) + Country + DoorSpread,
  data = ns
)

wing_ns_fallback <- lm(
  WingSpread ~ log(Depth) + DoorSpread,
  data = ns
)

# EVHOE -------------------------------------------------------------------

ev <- subset(hh, Survey == "EVHOE")

# cleaning
ev$WingSpread[!(ev$Year %in% 2016:2018)] <- NA # https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L47

ev$SweepLngtCat <- ifelse(ev$SweepLngt <= 60,
                          "short", "long")

# DoorSpread https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L43
door_evhoe <- lm(
  DoorSpread ~ Depth * as.factor(SweepLngtCat),
  data = ev
)

# WingSpread https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L47
wing_evhoe <- lm(
  WingSpread ~ DoorSpread * as.factor(SweepLngtCat),
  data = ev
)


# SWC-IBTS ----------------------------------------------------------------

swc <- subset(hh, Survey == "SWC-IBTS")

swc$SweepLngt <- as.numeric(swc$SweepLngt)
swc$SweepLngt[is.na(swc$SweepLngt)] <- 60 # it's all 60!

# Doorspread changed from this https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L137
door_swc <- lm(
  DoorSpread ~ log(Depth),
  data = swc
)

# Wingspread https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L142
wing_swc <- lm(
  WingSpread ~ log(Depth) + DoorSpread,
  data = swc
)

# BITS --------------------------------------------------------------------
# https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L155
bits <- subset(hh, Survey == "BITS")

bits$DoorSpread[bits$DoorSpread > 200] <- NA

door_bits_primary <- lm(
  DoorSpread ~ log(Depth) + Country + Gear,
  data = bits
)

door_bits_fallback <- lm(
  DoorSpread ~ log(Depth) + Gear,
  data = bits
)

door_bits_fallback2 <- lm(
  DoorSpread ~ log(Depth),
  data = bits
)

wing_bits <- lm(
  WingSpread ~ DoorSpread,
  data = bits
)

# IEGFS -------------------------------------------------------------------
# changed from https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L199
igfs <- subset(hh, Survey == "IE-IGFS")

igfs$SweepLngtCat <- ifelse(igfs$SweepLngt <= 60,
                            "short", "long")

door_igfs <- lm(
  DoorSpread ~ log(Depth) + as.factor(SweepLngtCat),
  data = igfs
)

door_igfs_fallback <- lm(
  DoorSpread ~ log(Depth),
  data = igfs
)

wing_igfs <- lm(
  WingSpread ~ DoorSpread + as.factor(SweepLngtCat),
  data = igfs
)

wing_igfs_fallback <- lm(
  WingSpread ~ DoorSpread,
  data = igfs
)

# FR-CGFS -----------------------------------------------------------------
# https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L225
cgfs <- subset(hh, Survey == "FR-CGFS")
cgfs$Year <- as.numeric(as.character(cgfs$Year))

# set fallback WS = 10 for pre-2015 *only if missing*
idx_10 <- cgfs$Year <= 2014 & is.na(cgfs$WingSpread)
cgfs$WingSpread[idx_10] <- 10

door_cgfs <- lm(
  DoorSpread ~ log(Depth),
  data = cgfs,
  subset = !is.na(DoorSpread)
)

wing_cgfs <- lm(
  WingSpread ~ DoorSpread,
  data = cgfs,
  subset = Year >= 2015 & !is.na(WingSpread) & !is.na(DoorSpread)
)


# NIGFS -------------------------------------------------------------------
# https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L261
nigfs <- subset(hh, Survey == "NIGFS")

door_nigfs <- lm(
  DoorSpread ~ log(Depth),
  data = nigfs
)

wing_nigfs <- lm(
  WingSpread ~ DoorSpread,
  data = nigfs
)

# ROCKALL -----------------------------------------------------------------
# changed from https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L286
rock <- subset(hh, Survey == "ROCKALL")

door_rockall <- lm(
  DoorSpread ~ log(Depth),
  data = rock
)

wing_rockall <- lm(
  WingSpread ~ DoorSpread,
  data = rock
)

# PT-IBTS -----------------------------------------------------------------
# https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L311
pt <- subset(hh, Survey == "PT-IBTS")

pt$WingSpread[pt$WingSpread > 20] <- NA
pt$cat <- ifelse(pt$Depth > 120, "deep", "shallow")

wing_pt <- lm(
  WingSpread ~ Depth * cat,
  data = pt
)

wing_pt_fallback <- lm(
  WingSpread ~ Depth * cat,
  data = pt
)

# pt$DoorSpread <- pt$WingSpread / 0.3 # doorspread probably not needed, rough estimate

# SP-NORTH ----------------------------------------------------------------
# changed from https://github.com/fishglob/FishGlob_data/blob/2c275d5dbc91bdcc7e6df51251884c2e670f90f5/cleaning_codes/source_DATRAS_wing_doorspread.R#L340
sp_north <- subset(hh, Survey == "SP-NORTH")

door_sp_north <- lm(
  DoorSpread ~ log(Depth),
  data = sp_north
)

wing_sp_north <- lm(
  WingSpread ~ DoorSpread,
  data = sp_north
)

# SP-ARSA -----------------------------------------------------------------

sp_arsa <- subset(hh, Survey == "SP-ARSA")

# DoorSpread
door_sp_arsa <- lm(
  DoorSpread ~ log(Depth),
  data = sp_arsa
)

# WingSpread
wing_sp_arsa <- lm(
  WingSpread ~ DoorSpread,
  data = sp_arsa)



# SP-PORC -----------------------------------------------------------------

porc <- subset(hh, Survey == "SP-PORC")

door_porc <- lm(
  DoorSpread ~ log(Depth),
  data = porc
)

wing_porc <- lm(
  WingSpread ~ DoorSpread,
  data = porc
)


# combine all the models  -------------------------------------------------

spread_models <- list(
  "NS-IBTS" = list(
    door_primary   = door_ns_primary,
    door_fallback1 = door_ns_fallback,
    door_fallback2 = door_ns_fallback2,
    
    wing_primary   = wing_ns,
    wing_fallback1 = wing_ns_fallback
  ),
  "EVHOE" = list(
    door_primary = door_evhoe,
    wing_primary = wing_evhoe
  ),
  "SWC-IBTS" = list(
    door_primary = door_swc,
    wing_primary = wing_swc
  ),
  "BITS" = list(
    door_primary   = door_bits_primary,
    door_fallback1 = door_bits_fallback,
    door_fallback2 = door_bits_fallback2,
    
    wing_primary   = wing_bits
  ),
  "IE-IGFS" = list(
    door_primary   = door_igfs,
    door_fallback1 = door_igfs_fallback,
    
    wing_primary   = wing_igfs,
    wing_fallback1 = wing_igfs_fallback
  ),
  "FR-CGFS" = list(
    door_primary = door_cgfs,
    wing_primary = wing_cgfs
  ),
  "NIGFS" = list(
    door_primary = door_nigfs,
    wing_primary = wing_nigfs
  ),
  "ROCKALL" = list(
    door_primary = door_rockall,
    wing_primary = wing_rockall
  ),
  "PT-IBTS" = list(
    wing_primary   = wing_pt,
    wing_fallback1 = wing_pt_fallback
  ),
  "SP-NORTH" = list(
    door_primary = door_sp_north,
    wing_primary = wing_sp_north
  ),
  "SP-ARSA" = list(
    door_primary = door_sp_arsa,
    wing_primary = wing_sp_arsa
  ),
  "SP-PORC" = list(
    door_primary = door_porc,
    wing_primary = wing_porc
  )
)

usethis::use_data(spread_models, internal = TRUE, overwrite = TRUE)
