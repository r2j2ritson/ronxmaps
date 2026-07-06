## ronxmaps package creation
usethis::create_package("ronxmaps")

# run after adding function
devtools::document()

# Document packages and versions
usethis::use_package("dplyr", min_version = TRUE)
usethis::use_package("chromote", min_version = TRUE)
usethis::use_package("rvest", min_version = TRUE)
usethis::use_package("jsonlite", min_version = TRUE)
usethis::use_package("sf", min_version = TRUE)
usethis::use_package("httr2", min_version = TRUE)
usethis::use_package("purrr", min_version = TRUE)
usethis::use_package("curl", min_version = TRUE)
#usethis::use_latest_dependencies()

devtools::load_all()

## Create and Load Data Objects to package
BorahPeakTrail_kml <- sf::st_read("C:\\Users\\r2j2r\\Downloads\\BORAH_TEST_LINE_OnX.kml")
usethis::use_data(BorahPeakTrail_kml,internal = F)

BorahPeakUSGSQuad_kml <- sf::st_read("C:\\Users\\r2j2r\\Downloads\\BORAH_TEST_POLY_OnX.kml")
usethis::use_data(BorahPeakUSGSQuad_kml,internal = F)

BorahPeak_kml <- sf::st_read("C:\\Users\\r2j2r\\Downloads\\BORAH_TEST_LOC_OnX.kml")
sf::st_coordinates(BorahPeak_kml)
BorahPeak_kml$geometry <- BorahPeak_kml$geometry + c((-113.7811)*2,0)

library("ronxmaps")
BorahPeak_kml <- ronxmaps::BorahPeak_kml
BorahPeak_kml <- sf::st_set_crs(BorahPeak_kml,"wgs84")
usethis::use_data(BorahPeak_kml,internal = F,overwrite = T)


## Github
usethis::use_git()
usethis::use_github()
usethis::pr_resume()
usethis::pr_init("working")
remotes::install_github("r2j2ritson/ronxmaps")

## Terminal commands for committing changes
# git add .
# git commit -m "Descriptive commit message."
# git push origin
## Try inside script
system("git add .")
system('git commit -m "Automated commit from R script"')
system("git push origin")
