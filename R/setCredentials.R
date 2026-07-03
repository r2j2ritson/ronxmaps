#' @title Set Credentials for OnX Web Maps
#' @description
#' Store login credentials for OnX Web Maps to system environment, optimal for privacy.
#'
#' @param onx_email A string containing a valid OnX account email address.
#' @param onx_password A string containing a valid password to an active OnX account.
#'
#' @author Robert Ritson <r2j2ritson@gmail.com>
#'
#' @export setCredentials
setCredentials <- function(onx_email,onx_password){
  email_arg <- list(onx_email)
  names(email_arg) <- "ONX_EMAIL"
  do.call(Sys.setenv,email_arg)

  pwd_arg <- list(onx_password)
  names(pwd_arg) <- "ONX_PASSWORD"
  do.call(Sys.setenv,pwd_arg)
  message("OnX Credentials set in system environment.")
}
