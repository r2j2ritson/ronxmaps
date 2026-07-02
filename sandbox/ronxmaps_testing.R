## ronxmaps testing
library("ronxmaps")
ronxmaps::BorahPeak_kml

Sys.setenv("ONX_EMAIL" = "robert.ritson@idfg.idaho.gov")
Sys.setenv("ONX_PASSWORD" = "IDFG2020")

onx_email <- Sys.getenv("ONX_EMAIL")
onx_password <- Sys.getenv("ONX_PASSWORD")
ronxmaps::getToken()

