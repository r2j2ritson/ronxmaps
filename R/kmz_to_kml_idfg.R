#' @title Functions for converting KMZ files to KML
#' @description
#' Unzip KMZ files and resave as KML files. Close but TOO TAILORED, NEED TO GENERALIZE AND ADD USER FUNCTIONALITY FOR DESCRIPTION!!!!
#'
#' @note
#' Will work for IDFG Silviculture files (PVZ, YSH, and NavPointID2); but currently too specific for general use.
#'
#' @author Robert Ritson <r2j2ritson@gmail.com>
#'
#' @examples
#' ## Not Run:
#' ### Convert KMZ Point Files to KML
#' files <- dir(fp,pattern = ".kmz",full.names = T)
#' pt_files <- files[stringr::str_detect(files,"PtsForSampling")]
#' lapply(pt_files,pts_kmz_to_kml)
#'
#' ## Convert KMZ Polygon Files to KML
#' stand_files <- files[stringr::str_detect(files,"StandsForSampling")]
#' lapply(stand_files,stands_kmz_to_kml)
#'
#' # Clean-up
#' files <- dir(fp,pattern = ".xsl|.png|doc.kml",full.names = T)
#' file.remove(files)
#' ## End Not Run
#'
#' @import rvest
#' @import stats
#' @import utils
#' @import dplyr
#' @import sf
#'
#' @export parse_html
parse_html <- function(desc){ #function for parsing html description within KMZ
  d <- rvest::read_html(desc)
  tds <- d |>
    rvest::html_elements("tr td") |>
    rvest::html_text(trim = TRUE)
  keys <- tds[seq(1, length(tds), by = 2)]
  vals <- tds[seq(2, length(tds), by = 2)]
  attrs <- stats::setNames(vals, keys)
  out <- data.frame("NavPoint_ID2" = attrs[["NavPoint_ID2"]],
                    "Zone" = attrs[["Zone"]],
                    "Yrs_Since_Harvest" = attrs[["Yrs_Since_Harvest"]])
  return(out)
}

#' @export pts_kmz_to_kml
pts_kmz_to_kml <- function(file){
  utils::unzip(file,exdir=dirname(file)) #unzip KMZ to reveal KML (ONLY change this!)
  foo <- sf::st_read(paste0(dirname(file),"//doc.kml")) # read in KML file (always same name)
  desc_df <- do.call(rbind,lapply(foo$Description,parse_html)) # parse pertinent information
  cbind(foo,desc_df) %>% # recombine with locaiton information
    dplyr::select(NavPoint_ID2,Zone,Yrs_Since_Harvest,geometry) %>%
    dplyr::mutate(Name = NavPoint_ID2, # format KML info for OnX
                  Desc = paste0(Zone,"; YSH: ",Yrs_Since_Harvest)) %>%
    dplyr::select(Name,Desc,geometry) %>%
    dplyr::select(Name = Name,
                  Description = Desc) %>%
    sf::st_write(.,paste0(dirname(file),"//",gsub(".kmz",".kml",basename(file))),driver="KML",append=F) # save correctly formatted KML

}

#' @export stands_kmz_to_kml
stands_kmz_to_kml <- function(file){
  unzip(file,exdir=dirname(file))
  foo <- sf::st_read(paste0(fp,"doc.kml"))
  pts_file <- gsub("StandsForSampling_","PtsForSampling_",file)
  pts_file <- gsub(".kmz",".kml",pts_file)

  foo2 <- sf::st_read(pts_file) %>%
    as.data.frame() %>%
    dplyr::mutate(Stand_ID = paste0(stringr::str_split_fixed(Name,"_",3)[,1],"_",stringr::str_split_fixed(Name,"_",3)[,2]),
                  PVZ = stringr::str_split_fixed(Description,";",2)[,1],
                  YSH = stringr::str_split_fixed(Description,";",2)[,2]) %>%
    dplyr::group_by(Stand_ID) %>%
    dplyr::summarise(Description = paste0(paste0(unique(PVZ),collapse = " & "),";",unique(YSH)))

  foo %>%
    dplyr::mutate(Description = NULL) %>%
    cbind(.,foo2) %>%
    dplyr::mutate(Name = Stand_ID) %>%
    dplyr::select(Name,Description,geometry) %>%
    sf::st_write(.,paste0(dirname(file),"//",gsub(".kmz",".kml",basename(file))),driver="KML",append=F) # save correctly formatted KML
}

