#' @title Helper functions for viewing OnX Web Maps content including files and account information
#'
#' @author Robert Ritson <r2j2ritson@gmail.com>
#'
#' @note
#' Some functions were drafted from vibe code sessions with Copilot using an HAR file, but all have been tested, authenticated, and modified to suite package architecture and functionality.
#'
#'#' Fetch the current subscriptions for the signed-in account.
#' @export onx_subscriptions
onx_subscriptions <- function(token = Sys.getenv("ONX_TOKEN", unset = ""),as_df = T) {
  onx_subs <-onx_api_request("v2/subscriptions", token = token)
  if(as_df==T){
    onx_subs_df<- tibble(Hunt = onx_subs$hunt$membership_level, Hunt_Started = onx_subs$hunt$started_at, Hunt_Expires = onx_subs$hunt$expires_at,
                         Offroad = onx_subs$offroad$membership_level, Offroad_Started = onx_subs$offroad$started_at, Offroad__Expires = onx_subs$offroad$expires_at,
                         Fish = onx_subs$fish$membership_level, Fish_Started = onx_subs$fish$started_at, Fish_Expires = onx_subs$fish$expires_at,
                         Backcountry = onx_subs$backcountry$membership_level, Backcountry_Started = onx_subs$backcountry$started_at, Backcountry__Expires = onx_subs$backcountry$expires_at,

    )
    return(onx_subs_df)
  }else{
    return(onx_subs)
  }

}

#' Fetch the current profile from the OnX production API.
#' @export onx_profile
onx_profile <- function(token = Sys.getenv("ONX_TOKEN", unset = ""),as_df = T) {
  onx_prof <-onx_api_request("v1/profile", token = token)
  if(as_df==T){
    onx_prof_df<- tibble(ID = onx_prof$account_id, Name = paste(onx_prof$first_name,onx_prof$last_name), Email = onx_prof$email,Last_updated = onx_prof$updated_at
    )
    return(onx_prof_df)
  }else{
    return(onx_prof)
  }
}

#' Helper function for parsing markup files
#' @export parse_markups
parse_markups <- function(x){
  out <- as.data.frame(unlist(x)) %>%
    tibble::rownames_to_column(.) %>%
    `colnames<-`(.,c("rowname","vals")) %>%
    tidyr::pivot_wider(names_from = rowname,
                       values_from = vals) %>%
    dplyr::mutate(geometry = sf::st_read(jsonlite::toJSON(x, auto_unbox = TRUE), quiet = T)[["geometry"]]) %>%
    as.data.frame()
  return(out)
}

#' List user markups by type.
#'
#' @param markup_type Character one of "waypoints", "tracks", "lines", "shapes".
#' @param limit Integer page size.
#' @param token Character bearer token.
#' @param parse Boolean whether to return 'cleaned' output as a data frame.
#' @param include.notes Boolean whether to attempt to include 'notes' column. Warning, if none of the features have notes, then function will fail.
#' @return Parsed JSON response from the OnX markup endpoint.
#' @export
onx_list_markups <- function(markup_type = c("waypoints", "tracks", "shapes"),
                             limit = 1000,
                             token = Sys.getenv("ONX_TOKEN", unset = ""),
                             parse = T, include.notes = F) {
  tryCatch({
    markup_type <- match.arg(markup_type)
  }, error = function(e){
    stop("`markup_type` must be ONE of 'waypoints', 'tracks', or 'shapes'!",call. = F)
  })

  onx_markups <- onx_api_request(
    path = paste0("v1/markups/", markup_type),
    token = token,
    query = list(limit = limit)
  )
  if(parse){
    parsed <- purrr::map_dfr(onx_markups,parse_markups)
    if(include.notes){
      parsed <- parsed %>%
        #coords_as_sf(.,"geo_json.geometry.coordinates1","geo_json.geometry.coordinates2") %>%
        dplyr::select(name,type,uuid,updated_at,geo_json.geometry.type,geo_json.type,created_at,notes,has_active_shares,geometry) %>%
        as.data.frame()
      return(parsed)
    }else{
      parsed <- parsed %>%
        #coords_as_sf(.,"geo_json.geometry.coordinates1","geo_json.geometry.coordinates2") %>%
        dplyr::select(name,type,uuid,updated_at,geo_json.geometry.type,geo_json.type,created_at,has_active_shares,geometry) %>%
        as.data.frame()
      return(parsed)
    }
  }else{
    return(onx_markups)
  }
}

#' Helper function for parsing folder information
#' @export parse_folders
parse_folders <- function(x){
  out <- as.data.frame(unlist(x)) %>%
    tibble::rownames_to_column(.) %>%
    `colnames<-`(.,c("rowname","vals")) %>%
    tidyr::pivot_wider(names_from = rowname,
                       values_from = vals) %>%
    #unname() %>%
    as.data.frame()
  return(out)
}

#' Fetch OnX content collections for the current account.
#'
#' @param type Character content collection type, default "hunt".
#' @param include_entities Logical whether to include entities in the response.
#' @param token Character bearer token.
#' @return Parsed JSON response from the OnX content collections endpoint.
#' @export
onx_content_collections <- function(type = "hunt",
                                    include_entities = TRUE,
                                    token = Sys.getenv("ONX_TOKEN", unset = ""),
                                    parse = T) {
  onx_content <- onx_api_request(
    path = "v1/content-collections",
    token = token,
    query = list(type = type, includeEntities = tolower(as.character(include_entities)))
  )
  if(parse){
    parsed <- purrr::map_dfr(onx_content,parse_folders) %>%
      as.data.frame()
    return(parsed)
  }else{
      return(onx_content)
    }
}


