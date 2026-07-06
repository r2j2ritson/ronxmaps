#' @title Extract OnX Web Maps Access Token
#' @description
#' Login to OnX Web Maps, extract access token, and save token to environment session for use in API functions.
#'
#' @param onx_email A string containing a valid OnX account email address. Best to store in environment for privacy (`Sys.setenv("ONX_EMAIL" = "example@email.com"`).
#' @param onx_password A string containing a valid password to an active OnX account. Best to store in environment for privacy (`Sys.setenv("ONX_PASSWORD" = "MyOnXpassWord123"`).
#' @param url A string containing a valid URL to the OnX Web Maps login page. Defaults to internal function `onx_login_base()`.
#' @param verbose A boolean indicating whether to return message stating how long the access token is valid (minutes). New tokens are typically valid for ~20 minutes. If token becomes stale, then this function will have to be re-run to get a fresh token.
#'
#' @returns Access token is saved to environment session for future use in API function via `Sys.getenv("ONX_TOKEN")`. The system time of when the current token expires is stored in `Sys.getenv("ONX_TOKEN_EXP")`.
#'
#' @note
#' A fresh token will only be generated if the previous token is stale. If unsure, re-running this function `getToken(verbose=T)` will return how many minutes the current token will remain valid.
#'
#' @author Robert Ritson <r2j2ritson@gmail.com>
#'
#' @examples
#' ## Not Run:
#' Sys.setenv(ONX_EMAIL = onx_email)
#' Sys.setenv(ONX_PASSWORD = onx_password)
#' getToken(verbose = T)
#' Sys.getenv("ONX_TOKEN")
#' Sys.getenv("ONX_TOKEN_EXP")
#' ## End Not Run
#'
#' @import chromote
#' @import jsonlite
#'
#' @export getToken
getToken <- function(onx_email = Sys.getenv("ONX_EMAIL"),
                     onx_password = Sys.getenv("ONX_PASSWORD"),
                     url = onx_login_base(),
                     verbose = T){
  if(Sys.getenv("ONX_TOKEN") == ""|(as.numeric(Sys.getenv("ONX_TOKEN_EXP"))- 60) < as.numeric(Sys.time())){
    b <- chromote::ChromoteSession$new()

    on.exit({
      try(b$close(), silent = TRUE)
      try(unlink(temp_dir, recursive = TRUE), silent = TRUE)
    }, add = TRUE)

    b$Page$navigate(url, wait_ = F)

    email_js <- jsonlite::toJSON(onx_email, auto_unbox = TRUE)
    pass_js  <- jsonlite::toJSON(onx_password, auto_unbox = TRUE)
    shadow_js2 <- paste0("
(function() {

  function findElementDeep(selector, root = document) {
    let el = root.querySelector(selector);
    if (el) return el;

    for (const node of root.querySelectorAll('*')) {
      if (node.shadowRoot) {
        el = findElementDeep(selector, node.shadowRoot);
        if (el) return el;
      }
    }
    return null;
  }

  function setReactValue(element, value) {
    const setter = Object.getOwnPropertyDescriptor(
      HTMLInputElement.prototype,
      'value'
    ).set;

    setter.call(element, value);

    element.dispatchEvent(new Event('input', { bubbles: true }));
    element.dispatchEvent(new Event('change', { bubbles: true }));
  }

  const emailField = findElementDeep('input[name=\"identifier\"]');
  const passwordField = findElementDeep('input[name=\"password\"]');
  const submitBtn = findElementDeep('button[name=\"method\"][value=\"password\"]');

  if (!emailField || !passwordField || !submitBtn) {
    return { email: !!emailField, password: !!passwordField, button: !!submitBtn };
  }

  setReactValue(emailField, ", email_js, ");
  setReactValue(passwordField, ", pass_js, ");

  setTimeout(() => submitBtn.click(), 250);

  return { ok: true };

})();
")

    #Sys.sleep(5)
    message("Logging in to OnX Web Maps...")
    pb <- utils::txtProgressBar(min = 0, max=5,style = 3,char=">")
    for(i in 1:5){
      Sys.sleep(1)
      utils::setTxtProgressBar(pb, i)
    }
    close(pb)
    b$Runtime$evaluate(shadow_js2, returnByValue = T)

    #Sys.sleep(10)
    message("Finding Access Token...")
    pb2 <- utils::txtProgressBar(min = 0, max=5,style = 3,char=">")
    for(i in 1:10){
      Sys.sleep(1)
      utils::setTxtProgressBar(pb2, i)
    }
    close(pb2)
    res <- b$Runtime$evaluate(
      expression = "JSON.stringify(window.localStorage)",
      returnByValue = T
    )

    storage <- jsonlite::fromJSON(res$result$value)
    if(length(storage) == 0){
      stop("Failed to acquire access token.")
    }
    oidc_user <- names(storage)[grepl("oidc.user",names(storage))]
    obj <- jsonlite::fromJSON(storage[[oidc_user]])

    tkn_arg <- list(obj$access_token)
    names(tkn_arg) <- "ONX_TOKEN"
    do.call(Sys.setenv,tkn_arg)

    exp_arg <- list(obj$expires_at)
    names(exp_arg) <- "ONX_TOKEN_EXP"
    do.call(Sys.setenv,exp_arg)

    if(verbose){
      message(paste("New Access Token",paste0(strtrim(Sys.getenv("ONX_TOKEN"),15),"...")," Expires in ",round((as.numeric(Sys.getenv("ONX_TOKEN_EXP")) - as.numeric(Sys.time()))/60), "minutes."))
      #print(Sys.getenv("ONX_TOKEN"))
    }

  }else{
    if(verbose){
      message(paste("Old Access Token Expires in ",round((as.numeric(Sys.getenv("ONX_TOKEN_EXP")) - as.numeric(Sys.time()))/60), "minutes."))
      #print(Sys.getenv("ONX_TOKEN"))
    }
  }

}

