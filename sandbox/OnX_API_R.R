#-----------------#
## Onx Login API ##
#-----------------#
## Store URLS & objects
onxlogin_url <- "https://webmap.onxmaps.com/hunt/login"
onx_webmaps_url <- "https://webmap.onxmaps.com/hunt/map/"

## Credentials
Sys.setenv(ONX_EMAIL = onx_email)
Sys.setenv(ONX_PASSWORD = onx_password)

## Test Files
fp <- "C:/Users/rritson/OneDrive - State of Idaho/Documents/Projects/ronx_wrapper/"
test_line <- paste0(fp,"test_files/BORAH_TEST_LINE_OnX.kml")

## Packages
#install.packages("chromote")
library(chromote)
library(httr2)
library(jsonlite)
require(dplyr)
require(purrr)
require(tidyr)

## Functions
### Retrieve & save browser cookies during manual login
getCookies <- function(file_path = getwd(),url = onxlogin_url){
  b <- ChromoteSession$new()
  b$view()
  b$go_to(url)
  print("Enter credentials in window and submit. When complete, press Enter key to proceed.")
  finished <- readline()
  if(finished == ""){
    #Sys.setenv("OnX_Cookies" = b$Network$getCookies())
    cookies <- b$Network$getCookies()
    saveRDS(cookies, paste0(file_path,"OnX_cookies.rds"))
    b$close()
    system("taskkill /F /IM chrome.exe")
  }
}
getCookies(file_path = fp,url = onx_webmaps_url)

### Apply saved cookies to new browser session (login w/o email & password)
login_with_cookies <- function(cookie_path = NULL,url = onx_webmaps_url){
  b <- ChromoteSession$new()
  b$go_to(url,wait_ = T)
  if(is.null(cookie_path)){
    cookies <- readRDS("OnX_cookies.rds")
  }else{
    cookies <- readRDS(cookie_path)
  }
  b$Network$setCookies(cookies = cookies$cookies)
  b$go_to(url,wait_ = T)
  #Sys.sleep(10)
  return(b)
}
b <- login_with_cookies()
b$view()

getToken_fromCookies <- function(cookie_path = NULL,url = onx_webmaps_url,timeout=60){
  b <- login_with_cookies(cookie_path = cookie_path, url = url)
  b$screenshot("page.png")
  
  deadline <- Sys.time() + timeout
  print("Waiting for page to respond...")
  while (Sys.time() < deadline) {
    url_eval <- b$Runtime$evaluate("location.href")
    current_url <- url_eval$result$value
    if (isTRUE(grepl("/auth/callback|/hunt/map", current_url, perl = TRUE))) {
      break
    }
    Sys.sleep(1)
  }
 
  token_result <- b$Runtime$evaluate(token_script, returnByValue = T)
  token_info <- token_result$result$value
  
  if (!isTRUE(token_info$ok)) {
    stop(token_info$error)
  }
  
  if (is.null(token_info$access_token) || !nzchar(token_info$access_token)) {
    stop("Access token was not found in the browser storage.")
  }
  print("Token found.")
  return(token_info)
}
# Sys.setenv(ONX_TOKEN = getToken_fromCookies()$access_token)
# rm(my_token)

#####################################
### Retrieve Access Token (proper?)
getToken <- function(onx_email = Sys.getenv("ONX_EMAIL"),onx_password = Sys.getenv("ONX_PASSWORD"),
                     url = onxlogin_url, chrome_args = chrome_args){
  b <- ChromoteSession$new(
    Chromote$new(
      browser = Chrome$new(args = chrome_args)
    )
  )
  
  on.exit({
    try(b$close(), silent = TRUE)
    try(unlink(temp_dir, recursive = TRUE), silent = TRUE)
  }, add = TRUE)
  
  load_promise <- b$Page$loadEventFired(wait_ = FALSE)
  b$Page$navigate(onxlogin_url, wait_ = F)
  b$wait_for(load_promise)
  
  shadow_js <- sprintf("
    (function() {
      function findElementDeep(selector, root = document) {
        let el = root.querySelector(selector);
        if (el) return el;
        
        const allElements = root.querySelectorAll('*');
        for (const element of allElements) {
          if (element.shadowRoot) {
            el = findElementDeep(selector, element.shadowRoot);
            if (el) return el;
          }
        }
        return null;
      }

      const emailField = findElementDeep('input[name=\"identifier\"]');
      const passwordField = findElementDeep('input[name=\"password\"]');
      const submitBtn = findElementDeep('button[name=\"method\"][value=\"password\"]');

      if (!emailField || !passwordField || !submitBtn) {
        return 'Missing elements: email=' + !!emailField + ', pass=' + !!passwordField + ', btn=' + !!submitBtn;
      }

      emailField.value = %s;
      passwordField.value = %s;
      submitBtn.click();
      return {ok: true};
    })();
  ", jsonlite::toJSON(onx_email),jsonlite::toJSON(onx_password))

  
  result <- b$Runtime$evaluate(shadow_js, returnByValue = T)
 
  b$screenshot("page.png")
  
  Sys.sleep(5)
  
  result <- b$Runtime$evaluate(shadow_js, returnByValue = T)
  
  b$Page$loadEventFired(wait_ = TRUE)
  
  if (!isTRUE(result$result$value$ok)) {
    stop(result$result$value$error)
  }
  
  Sys.sleep(5)
  
  ## PROBLEMS START HERE: is it actually possible to retrieve token this way???
  # Wait for redirect/callback to complete
  deadline <- Sys.time() + timeout
  while (Sys.time() < deadline) {
    url_eval <- b$Runtime$evaluate("location.href")
    current_url <- url_eval$result$value
    
    if (isTRUE(grepl("/auth/callback|/hunt/map", current_url, perl = TRUE))) {
      break
    }
    
    Sys.sleep(1)
  }
  
  # Extract auth object from browser storage
  token_script <- "
  (function() {
    const key = Object.keys(localStorage).find(k => k.startsWith('oidc.user:'));
    if (!key) {
      return { ok: false, error: 'oidc.user entry not found' };
    }

    const raw = localStorage.getItem(key);
    if (!raw) {
      return { ok: false, error: 'oidc.user value is empty' };
    }

    const obj = JSON.parse(raw);

    return {
      ok: true,
      storage_key: key,
      access_token: obj.access_token || null,
      token_type: obj.token_type || null,
      expires_at: obj.expires_at || null,
      scope: obj.scope || null,
      email: obj.profile && obj.profile.email ? obj.profile.email : null,
      raw: obj
    };
  })();
  "
  
  token_result <- b$Runtime$evaluate(token_script, returnByValue = T)
  token_info <- token_result$result$value
  
  if (!isTRUE(token_info$ok)) {
    stop(token_info$error)
  }
  
  if (is.null(token_info$access_token) || !nzchar(token_info$access_token)) {
    stop("Access token was not found in the browser storage.")
  }
  
  token_info
}
######################################
## Experimental
onx_api_base <- function() {
  "https://api.production.onxmaps.com"
}

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

onx_api_request <- function(path,
                            token = Sys.getenv("ONX_TOKEN", unset = ""),
                            method = "GET",
                            query = NULL,
                            body = NULL,
                            application_id = "hunt") {
  if (identical(token, "")) {
    stop("Set ONX_TOKEN or pass token=... before calling the OnX API.")
  }
  
  req <- httr2::request(onx_api_base()) |>
    httr2::req_url_path_append(path) |>
    httr2::req_headers(!!!onx_auth_headers(token, application_id = application_id)) |>
    httr2::req_user_agent("onxmapsr/0.1.0")
  
  if (!is.null(query)) {
    req <- httr2::req_url_query(req, !!!query)
  }
  
  if (!is.null(body)) {
    req <- httr2::req_body_json(req, body)
  }
  
  if (method != "GET") {
    req <- httr2::req_method(req, method)
  }
  
  resp <- httr2::req_perform(req)
  
  if (httr2::resp_status(resp) >= 400) {
    stop("OnX API request failed with status ", httr2::resp_status(resp), ": ", httr2::resp_body_string(resp))
  }
  
  ct <- httr2::resp_content_type(resp)
  if (grepl("application/json", ct, ignore.case = TRUE)) {
    httr2::resp_body_json(resp)
  } else {
    httr2::resp_body_string(resp)
  }
}

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
onx_subscriptions() #works!! (token may get stale and need to be re-run; incorporate or automate?)
####################################################
## Upload Wrapper (not funcitoning yet...)
onx_import_kml <- function(file,
                          token = Sys.getenv("ONX_TOKEN", unset = ""),
                          folder_id = NULL,
                          import_new_folder = TRUE) {
  if (!file.exists(file)) {
    stop("KML file not found: ", file)
  }
  
  # Placeholder endpoint: replace with the real upload endpoint if OnX exposes it
  # in the authenticated app after the import dialog is exercised.
  upload_path <- "v1/markups/import"
  
  body <- list(
    file = httr2::upload_file(file),
    folderId = folder_id,
    importNewFolder = import_new_folder
  )
  
  # The request shape is intentionally minimal and keeps the file upload path
  # separate from the verified GET endpoints discovered in the browser trace.
  req <- httr2::request(onx_api_base()) |>
    httr2::req_url_path_append(upload_path) |>
    httr2::req_headers(!!!onx_auth_headers(token)) |>
    httr2::req_user_agent("onxmapsr/0.1.0") |>
    httr2::req_body_multipart(body)
  
  resp <- httr2::req_perform(req)
  
  if (httr2::resp_status(resp) >= 400) {
    stop("KML import request failed with status ", httr2::resp_status(resp), ": ", httr2::resp_body_string(resp))
  }
  
  httr2::resp_body_json(resp)
}
onx_import_kml(file = test_line)




resp <- request("https://api.production.onxmaps.com/v1/markups/import") |>
  req_headers(
    Authorization = paste("Bearer", Sys.getenv("ONX_TOKEN", unset = ""))
  ) |>
  req_body_multipart(
    file = test_line
  ) |>
  req_perform()


## Examine HAR
har <- fromJSON(paste0(fp,"/har_files/webmap.onxmaps.har"), simplifyVector = F)
entries <- har$log$entries
reqs <- map_dfr(entries,function(x){
  tibble(started = x$startedDateTime,
         method = x$request$method,
         url = x$request$url,
         status = x$response$status,
         mime = x$response$content$mimeType %||% NA_character_
  )
})

# Find API calls
#greps <- "api|graphq1|upload|import|kml|geojson|feature"
greps <- "graphq1|import|kml"

reqs %>%
  filter(grepl(greps,url,ignore.case=T))
unique(sub("^(https?://[^/]+).*","\\1",reqs$url))

ext_hdrs <- function(entry){
  tibble(name = map_chr(entry$request$headers,"name"),
         value = map_chr(entry$request$headers,"value"))
}
upload_idx <- grep("upload|import|kml",reqs$url,ignore.case = T)
ext_hdrs(entries[[upload_idx[1]]])