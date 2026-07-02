#' @title Helper functions for authenticating and accessing OnX Web Maps
#'
#' @author Robert Ritson <r2j2ritson@gmail.com>
#'
#' @note
#' Some authentication functions were drafted from vibe code sessions with Copilot using an HAR file, but all have been tested, authenticated, and modified to suite package architecture and functionality.
#'
#' @export onx_api_base
onx_api_base <- function() {
"https://api.production.onxmaps.com"
}

#' @export onx_identity_base
onx_identity_base <- function() {
  "https://identity.onxmaps.com"
}

#' @export onx_login_base
onx_login_base <- function(){
  "https://webmap.onxmaps.com/hunt/login"
}

#' @export onx_web_base
onx_web_base <- function(){
  "https://webmap.onxmaps.com/hunt/map/"
}

#' Build OnX auth headers for production API calls
#'
#' @param token Character bearer token from the OnX OAuth/Ory session. Derived from `getToken`, typically stored in `Sys.getenv("ONX_TOKEN")`.
#' @param application_id Character application id, default "hunt".
#' @param application_platform Character application platform, default "web".
#' @param application_version Character application version, default "4.0.0".
#' @return Named character vector suitable for `httr2::req_headers()`.
#' @export onx_auth_headers
onx_auth_headers <- function(token,
                             application_id = "hunt",
                             application_platform = "web",
                             application_version = "4.0.0") {
  c(
    Authorization = paste("Bearer", token),
    `content-type` = "application/json",
    `onx-application-id` = application_id,
    `onx-application-platform` = application_platform,
    `onx-application-version` = application_version,
    referer = "https://webmap.onxmaps.com/"
  )
}

#' Create a session object that stores the bearer token and headers.
#'
#' @param token Character bearer token. Derived from `getToken`, typically stored in `Sys.getenv("ONX_TOKEN")`.
#' @param application_id Character application id. Defaults to "hunt"
#' @return List with token, headers, and api base URL.
#' @export onx_login_from_token
onx_login_from_token <- function(token,
                                 application_id = "hunt") {
  list(
    token = token,
    application_id = application_id,
    headers = onx_auth_headers(token, application_id = application_id),
    base_url = onx_api_base()
  )
}

#' Make an authenticated request to the OnX production API.
#'
#' @param path Character request path under the production API.
#' @param token Character bearer token; if missing, uses ONX_TOKEN env var when present.
#' @param method Character HTTP method.
#' @param query Named list of query parameters.
#' @param body Optional body for JSON payloads.
#' @param application_id Character application id.
#' @return Parsed JSON response or raw text when JSON is not available.
#' @export onx_api_request
onx_api_request <- function(path,
                            token = NULL,
                            method = "GET",
                            query = NULL,
                            body = NULL,
                            application_id = "hunt") {
  if (is.null(token)){
    token <- Sys.getenv("ONX_TOKEN", unset = "")
  }
  if (identical(token, "")) {
    stop("Set ONX_TOKEN or pass token=... before calling the OnX API.")
  }

  req <- httr2::request(onx_api_base()) |>
    httr2::req_url_path_append(path) |>
    httr2::req_headers(!!!onx_auth_headers(token, application_id = application_id)) |>
    httr2::req_user_agent("ronxmaps/0.0.0.9000")

  if (!is.null(query)) {
    req <- httr2::req_url_query(req, !!!query) |>
      httr2::req_error(is_error = function(resp) FALSE)
  }

  if (!is.null(body)) {
    req <- httr2::req_body_json(req, body) |>
      httr2::req_error(is_error = function(resp) FALSE)
  }

  if (method != "GET") {
    req <- httr2::req_method(req, method) |>
      httr2::req_error(is_error = function(resp) FALSE)
  }

  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  resp <- req |>
    httr2::req_perform()

  status <- httr2::resp_status(resp)
  if (status >= 400) {
    stop("OnX API request failed with status ", status)
  }else if(grepl("application/json", httr2::resp_content_type(resp), ignore.case = TRUE)){
    return(httr2::resp_body_json(resp))
  }else{
    return(httr2::resp_body_string(resp))
  }
}
