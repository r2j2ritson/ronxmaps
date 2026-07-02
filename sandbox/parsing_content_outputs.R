## Testing

Sys.setenv(ONX_EMAIL = onx_email)
Sys.setenv(ONX_PASSWORD = onx_password)
Sys.setenv(ONX_TOKEN = getToken())
Sys.getenv("ONX_TOKEN")

foo2 <- as.data.frame(unlist(foo[[3]])) %>%
  tibble::rownames_to_column(.) %>%
  `colnames<-`(.,c("rowname","vals")) %>%
  tidyr::pivot_wider(names_from = rowname,
                     values_from = vals) %>%
  as.data.frame()

foo[[2]]

unlist(foo[[1]])
foo2 <- as.data.frame(unlist(foo[[1]])) %>%
  tibble::rownames_to_column(.) %>%
  `colnames<-`(.,c("rowname","vals")) %>%
  tidyr::pivot_wider(names_from = rowname,
                     values_from = vals) %>%
  dplyr::select(name,type,permissions,uuid,updated_at,geo_json.geometry.type,geo_json.type,created_at,notes,has_active_shares,last_synced_at) %>%
  as.data.frame()
foo2

parse_markups <- function(x){
  out <- as.data.frame(unlist(x)) %>%
    tibble::rownames_to_column(.) %>%
    `colnames<-`(.,c("rowname","vals")) %>%
    tidyr::pivot_wider(names_from = rowname,
                       values_from = vals) %>%
    as.data.frame()
  return(out)
}
foo2 <- parse_markups(foo[[3]])
foo2

foo <- onx_list_markups(markup_type = "shapes", limit = 1000)
parsed <- purrr::map_dfr(foo,parse_markups) %>%
  dplyr::select(name,type,uuid,updated_at,geo_json.geometry.type,geo_json.type,created_at,has_active_shares) %>%
  as.data.frame()

foo <- onx_list_markups(markup_type = "waypoints", limit = 1000)
parsed <- purrr::map_dfr(foo,parse_markups) %>%
  dplyr::select(name,type,uuid,updated_at,geo_json.geometry.type,geo_json.type,created_at,notes,has_active_shares) %>%
  as.data.frame()

head(foo)
as.data.frame(foo)
as.data.frame(unlist(foo[[1]]))

parse_markups(foo[[1]])

foo <- onx_content_collections()
parsed <- purrr::map_dfr(foo,parse_markups) %>%
  dplyr::select(name,type,uuid,updated_at,created_by,created_at,updated_at,entity_count) %>%
  as.data.frame()
