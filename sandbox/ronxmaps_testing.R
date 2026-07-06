## ronxmaps testing
remotes::install_github("r2j2ritson/ronxmaps")
library("ronxmaps")
#ronxmaps::BorahPeak_kml

ronxmaps::setCredentials("robert.ritson@idfg.idaho.gov","IDFG2020")
ronxmaps::getToken(onx_email = Sys.getenv("ONX_EMAIL"),
                   onx_password = Sys.getenv("ONX_PASSWORD"),
                   url = onx_login_base(),
                   verbose = T)

ronxmaps::onx_profile()
ronxmaps::onx_subscriptions()
ronxmaps::onx_list_markups()
ronxmaps::onx_content_collections()


foo <- ronxmaps::onx_list_markups(parse = T) %>%
  sf::st_as_sf() %>%
  terra::vect()
terra::plot(foo)
terra::plet(foo)

foo2 <- foo[which(foo$name == "67P"),]

foo <- ronxmaps::onx_list_markups(markup_type = c("waypoints","shapes"),parse=T)
parsed <- purrr::map_dfr(foo,parse_markups)

foo2 <- foo[[1]]

writeLines(jsonlite::toJSON(foo[[1]], auto_unbox = TRUE), "temp.geojson")
x <- st_read("temp.geojson", quiet = T)
x
plot(x)

y <- sf::st_read(jsonlite::toJSON(foo[[1]], auto_unbox = TRUE), quiet = T)





library(terra)


library(leaflet)
foo_vect1 <- terra::vect(foo[,"geometry"])
plot(foo_vect1)
plot(foo$geometry)
terra::plet(foo_vect1)

foo2 <- foo[1,]
leaflet(data = foo2$geometry) %>%
  addTiles() %>%
  addMarkers()

library(leaflet)
m <- terra::plet(foo_vect)
htmlwidgets::saveWidget(m,"map.html")
viewer <- getOption("viewer")
viewer("map.html")
