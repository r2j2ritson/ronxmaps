#' @title Import KML file to OnX Web Maps
#' @description
#' Use valid OnX Web Maps access token to import a KML file to the web app via the API.
#'
#' @param file A string containing the full file path to the KML file. Shapefiles in R must first be saved as KML files (ex., `sf::st_write(shp_file,"file.kml")`).
#' @param token Character bearer token from the OnX OAuth/Ory session. Derived from `getToken`, typically stored in `Sys.getenv("ONX_TOKEN")`.
#'
#' @returns Markup ID of successfully uploaded file. If upload fails, the HTTP error code is returned in a message.
#'
#' @note
#' If the token is stale, then this function will not work. Refresh by re-running `getToken` then re-run function.
#'
#' @author Robert Ritson <r2j2ritson@gmail.com>
#'
#' @examples
#' ## Not Run:
#' test_file <- ronxmaps::BorahPeak_kml
#' sf::st_write(test_file,"test_file.kml")
#' file <- file.path(getwd(),"test_file.kml")
#' import_kml2OnX(file = file, token = Sys.getenv("ONX_TOKEN", unset = ""))
#' ## End Not Run
#'
#' @import curl
#' @import httr2
#'
#' @export import_kml2OnX
import_kml2OnX <- function(file,
                           token = Sys.getenv("ONX_TOKEN", unset = "")) {
  if (!file.exists(file)) {
    stop("KML file not found: ", file)
  }

  # Placeholder endpoint: replace with the real upload endpoint if OnX exposes it
  # in the authenticated app after the import dialog is exercised.
  upload_path <- "v1/markups/import"

  # The request shape is intentionally minimal and keeps the file upload path
  # separate from the verified GET endpoints discovered in the browser trace.
  req <- httr2::request(onx_api_base()) |>
    httr2::req_url_path_append(upload_path) |>
    httr2::req_headers(!!!onx_auth_headers(token)) |>
    httr2::req_user_agent("ronxmaps/0.0.999") |>
    httr2::req_body_multipart(type = "kml",
                              file = curl::form_file(file, type = "application/octet-stream"))

  req <- req |>
    httr2::req_headers(`Content-Type` = NULL)
  req <- req |> httr2::req_options(verbose = T)
  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) >= 400) {
    stop("KML import request failed with status ", httr2::resp_status(resp), ": ", httr2::resp_body_string(resp))
  }else{
    message("KML file uploaded successfully!")
    return(list("Markup_ID" = httr2::resp_body_json(resp)[[1]][[1]]))
  }
}
