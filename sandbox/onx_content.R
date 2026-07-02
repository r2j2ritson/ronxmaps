#' Fetch OnX content collections for the current account.
#'
#' @param type Character content collection type, default "hunt".
#' @param include_entities Logical whether to include entities in the response.
#' @param token Character bearer token.
#' @return Parsed JSON response from the OnX content collections endpoint.
#' @export
onx_content_collections <- function(type = "hunt",
                                    include_entities = TRUE,
                                    token = Sys.getenv("ONX_TOKEN", unset = "")) {
  onx_api_request(
    path = "v1/content-collections",
    token = token,
    query = list(type = type, includeEntities = tolower(as.character(include_entities)))
  )
}
foo <- onx_content_collections() #folders


#' List user markups by type.
#'
#' @param markup_type Character one of "waypoints", "tracks", "lines", "shapes".
#' @param limit Integer page size.
#' @param token Character bearer token.
#' @return Parsed JSON response from the OnX markup endpoint.
#' @export
onx_list_markups <- function(markup_type = c("waypoints", "tracks", "lines", "shapes"),
                              limit = 1000,
                              token = Sys.getenv("ONX_TOKEN", unset = "")) {
  markup_type <- match.arg(markup_type)
  onx_api_request(
    path = paste0("v1/markups/", markup_type),
    token = token,
    query = list(limit = limit)
  )
}
foo <- onx_list_markups(markup_type = "shapes", limit = 1000)

#' Fetch the current profile from the OnX production API.
#'
#' @param token Character bearer token.
#' @return Parsed JSON response.
#' @export
onx_profile <- function(token = Sys.getenv("ONX_TOKEN", unset = "")) {
  onx_api_request("v1/profile", token = token)
}
onx_profile()

#' Fetch the current subscriptions for the signed-in account.
#'
#' @param token Character bearer token.
#' @return Parsed JSON response.
#' @export
onx_subscriptions <- function(token = Sys.getenv("ONX_TOKEN", unset = "")) {
  onx_api_request("v2/subscriptions", token = token)
}

# foo <- onx_api_request(path = "v2/subscriptions", 
#                        token = Sys.getenv("ONX_TOKEN", unset = ""),
#                        method = "GET",
#                        query = NULL,
#                        body = NULL,
#                        application_id = "hunt")
