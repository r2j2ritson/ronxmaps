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
