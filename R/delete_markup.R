#' @title Delete Markup file from OnX Web Maps
#' @description
#' Use valid OnX Web Maps access token to delete a markup file from the web app via the API.
#'
#' @param uuid A character string containing the UUID of the markup file to be deleted. This can be found running `ronxmaps::onx_list_markups(parse = T)` and filtering by name.
#' @param token A Character string corresponding to the bearer token from the OnX OAuth/Ory session. Derived from `getToken`, typically stored in `Sys.getenv("ONX_TOKEN")`.
#'
#' @returns Message if delete request was successful or HTTP error code if failed.
#'
#' @note
#' If the token is stale, then this function will not work. Refresh by re-running `getToken` then re-run function.
#'
#' @author Robert Ritson <r2j2ritson@gmail.com>
#'
#' @examples
#' ## Not Run:
#' markup_lst <- ronxmaps::onx_list_markups(parse = T)
#' markup_toDelete <- markup_lst[which(markup_lst$name == "Borah Peak"),]
#' delete_markup(uuid = markup_toDelete$uuid, token = Sys.getenv("ONX_TOKEN", unset = ""))
#' ## End Not Run
#'
#' @import httr2
#'
#' @export delete_markup
delete_markup <- function(uuid,
                          token = Sys.getenv("ONX_TOKEN", unset = "")) {

  # Placeholder endpoint
  delete_path <- paste0("v1/markups/waypoints/",uuid)

  # The request shape is intentionally minimal and keeps the file upload path
  # separate from the verified GET endpoints discovered in the browser trace.
  req <- httr2::request(onx_api_base()) |>
    httr2::req_url_path_append(delete_path) |>
    httr2::req_headers(!!!onx_auth_headers(token)) |>
    httr2::req_method("DELETE") |>
    httr2::req_user_agent("ronxmaps/0.0.999") |>
    #httr2::req_headers(`Content-Type` = NULL) |>
    httr2::req_options(verbose = T)

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) >= 400) {
    stop("Markup file delete request failed with status ", httr2::resp_status(resp), ": ", httr2::resp_body_string(resp))
  }else{
    message("Markup file ",uuid, " deleted successfully!")
  }
}


# delete_folder <- function(uuid,
#                           token = Sys.getenv("ONX_TOKEN", unset = "")) {
#
#   # Placeholder endpoint
#   delete_path <- paste0("v1/content-collections/delete_content_collection/",uuid)
#
#   # The request shape is intentionally minimal and keeps the file upload path
#   # separate from the verified GET endpoints discovered in the browser trace.
#   req <- httr2::request(onx_api_base()) |>
#     httr2::req_url_path_append(delete_path) |>
#     httr2::req_headers(!!!onx_auth_headers(token)) |>
#     httr2::req_method("DELETE") |>
#     httr2::req_user_agent("ronxmaps/0.0.999") |>
#     #httr2::req_headers(`Content-Type` = NULL) |>
#     httr2::req_options(verbose = T)
#
#   resp <- httr2::req_perform(req)
#
#   if (httr2::resp_status(resp) >= 400) {
#     stop("Folder delete request failed with status ", httr2::resp_status(resp), ": ", httr2::resp_body_string(resp))
#   }else{
#     message("Folder ",uuid, " deleted successfully!")
#   }
# }
