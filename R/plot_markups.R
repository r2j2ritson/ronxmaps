#' Plot markup coordinates.
#'
#' @param markup_type Character one of "waypoints", "tracks", "lines", "shapes".
#' @param limit Integer page size.
#' @param token Character bearer token.
#' @param interactive Boolean whether to return an interactive leaflet plot with 'terra::plet' or a static one with 'terra::plot'.
#' @return A plot visualizing coordinates of markups.
#' @export plot_markups
plot_markups <- function(markup_type = c("waypoints", "tracks", "lines", "shapes"),
                             limit = 1000,
                             token = Sys.getenv("ONX_TOKEN", unset = ""),
                             interactive = T) {
  markup_type <- match.arg(markup_type)
  onx_markups <- onx_api_request(
    path = paste0("v1/markups/", markup_type),
    token = token,
    query = list(limit = limit)
  )
  parsed <- purrr::map_dfr(onx_markups,parse_markups) %>%
    dplyr::select(name,type,uuid,updated_at,geo_json.geometry.type,geo_json.type,created_at,has_active_shares,geometry) %>%
    as.data.frame() %>%
    sf::st_as_sf() %>%
    terra::vect()
  if(interactive){
    terra::plet(parsed)
  }else{
    terra::plot(parsed)
  }
}
