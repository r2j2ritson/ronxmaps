## An R interface for managing OnX Web Maps 
<img width="300" height="300" alt="ChatGPT Image Jul 3, 2026, 12_03_01 PM" src="https://github.com/user-attachments/assets/11b66ea5-351d-4b3b-a30b-722a9bde2c2a" />

Under active development. Manage files in your OnX Web Maps account, format and convert KML files, and import features to access from your mobile app.

### Install development version
remotes::install_github("r2j2ritson/ronxmaps")

### Login example
ronxmaps::setCredentials("myonx_email@example.com","myonxpassword")

ronxmaps::getToken(onx_email = Sys.getenv("ONX_EMAIL"),
                   onx_password = Sys.getenv("ONX_PASSWORD"),
                   url = ronxmaps::onx_login_base(),
                   verbose = T)

### Check profile and subscription information
ronxmaps::onx_profile()

ronxmaps::onx_subscriptions()

### List Markups and content
ronxmaps::onx_list_markups()

ronxmaps::onx_content_collections()

### Import a KML to OnX from R
test_file <- ronxmaps::BorahPeak_kml

sf::st_write(test_file,"test_file.kml")

file <- file.path(getwd(),"test_file.kml")

ronxmaps::import_kml2OnX(file = file, token = Sys.getenv("ONX_TOKEN", unset = ""))

## Planned functions under development
- formatting and saving shapefiles as KML files
- folder management (creation, deletion, adding markups to folders, etc.)
- sharing files with other users
- Vignette and demonstrated use cases
