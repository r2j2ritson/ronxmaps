#' @title Coerce dataframe with coordinates to an `sf` object
#' @description
#' Convert dataframe with coordinate infromation into a plottable 'sf' style object
#'
#' @param df A data frame containing coordinate information
#' @param x A character string coresponding to column name in `df` containing the 'x' coordinate of the waypoint (aka. Longitude).
#' @param y A character string coresponding to column name in `df` containing the 'y' coordinate of the waypoint (aka. Latitude).
#' @param crs A character string coresponding to coordinate reference system of the waypoint. Defaults to "wgs84", use this for unprojected coordinates (Longitude & Latitude).
#'
#' @returns A dataframe with `sf` geometry column appended
#'
#' @author Robert Ritson <r2j2ritson@gmail.com>
#'
#' @import dplyr
#' @import sf
#'
#' @export coords_as_sf
coords_as_sf <- function(df,x,y,crs = "wgs84"){
  df_sf <- df %>% dplyr::mutate(xx = as.numeric(df[[x]]), yy = as.numeric(df[[y]])) %>%
    dplyr::rowwise(.) %>%
    dplyr::mutate(geometry = list(sf::st_point(c(xx,yy)))) %>%
    as.data.frame(.) %>% dplyr::select(-xx,-yy) %>% sf::st_as_sf(.,crs=crs)
  return(df_sf)
}
