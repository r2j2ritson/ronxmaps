## ronxmaps testing
library("ronxmaps")
ronxmaps::BorahPeak_kml

ronxmaps::setCredentials("robert.ritson@idfg.idaho.gov","IDFG2020")
ronxmaps::getToken(onx_email = Sys.getenv("ONX_EMAIL"),
                   onx_password = Sys.getenv("ONX_PASSWORD"),
                   url = onx_login_base(),
                   verbose = T)

ronxmaps::onx_profile()
ronxmaps::onx_subscriptions()
ronxmaps::onx_list_markups()
ronxmaps::onx_content_collections()

foo <- ronxmaps::onx_list_markups(parse = F)
foo
foo[[1]]

parsed <- purrr::map_dfr(foo,parse_markups)
parsed

foo_shp <- coords_as_sf(parsed,"geo_json.geometry.coordinates1","geo_json.geometry.coordinates2")
plot(foo_shp$geometry)

remotes::install_github("rspatial/terra")
foo_vect <- terra::vect(foo_shp)
terra::plot(foo_vect)
unique(parsed$type)
