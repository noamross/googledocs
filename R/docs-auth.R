#' Authorize googledrive
#'
#' Authorize googledrive to view and manage your Drive files. By default, you
#' are directed to a web browser, asked to sign in to your Google account, and
#' to grant googledrive (the tidyverse, actually) permission to operate on your
#' behalf with Google Drive. By default, these user credentials are cached in a
#' file below your home directory, `~/.R/gargle/gargle-oauth`, from where they
#' can be automatically refreshed, as necessary. Storage at the user-level means
#' the same token can be used across multiple projects and they are less likely
#' to be synced to the cloud by accident.
#'
#' Most users, most of the time, do not need to call `drive_auth()` explicitly
#' -- it is triggered by the first action that requires authorization. Even when
#' called, the default arguments will often suffice. However, when necessary,
#' this function allows the user to explicitly
#'   * Declare which Google identity to use, via an email address. If there are
#'   multiple cached tokens, this can clarify which one to use. It can also
#'   force googledrive to switch from one identity to another. If there's no
#'   cached token for the email, this triggers a return to the browser to choose
#'   the identity and give consent.
#'   * Load a service account token.
#'   * Specify non-default behavior re: token caching and out-of-bound
#'   authentication.
#'
#' For even deeper control over auth, use [drive_auth_config()] to use your own
#' OAuth app or API key.
#'
#' @seealso More detail is available from
#' [Using OAuth 2.0 for Installed Applications](https://developers.google.com/identity/protocols/OAuth2InstalledApp)
#'
#' @param email Optional; email address associated with the desired Google user.
#' @param path Optional; path to the downloaded JSON file for a service token.
#' @param scopes Optional; scope(s) to use. See your choices at [OAuth 2.0
#'   Scopes for Google
#'   APIs](https://developers.google.com/identity/protocols/googlescopes#drivev3).
#' @inheritParams httr::oauth2.0_token
#'
#' @family auth functions
#' @export
#'
#' @examples
#' \dontrun{
#' ## load/refresh existing credentials, if available
#' ## otherwise, go to browser for authentication and authorization
#' drive_auth()
#'
#' ## see user associated with current token
#' drive_user()
#'
#' ## force use of a token associated with a specific email
#' drive_auth(email = "jenny@example.com")
#' drive_user()
#'
#' ## use a 'read only' scope, so it's impossible to edit or delete files
#' drive_auth(
#'   scopes = "https://www.googleapis.com/auth/drive.readonly"
#' )
#'
#' ## use a service account token
#' drive_auth(path = "foofy-83ee9e7c9c48.json")
#' }
drive_auth <- function(email = NULL,
                       path = NULL,
                       scopes = "https://www.googleapis.com/auth/drive",
                       cache = getOption("gargle.oauth_cache"),
                       use_oob = getOption("gargle.oob_default")) {
  cred <- gargle::token_fetch(
    scopes = scopes,
    app = drive_oauth_app(),
    email = email,
    path = path,
    package = "googledrive",
    cache = cache,
    use_oob = use_oob
  )
  stopifnot(is_legit_token(cred, verbose = TRUE))
  set_access_cred(cred)
  set_auth_active(TRUE)

  return(invisible())
}

#' Suspend authorization
#'
#' Put googledrive into a de-authorized state. Instead of sending a token,
#' googledrive will send an API key. This can be used to access public files for
#' which no Google sign-in is required. This is handy for using googledrive in a
#' non-interactive setting to make requests that do not require a token. It will
#' prevent the attempt to obtain a token interactively in the browser. A
#' built-in API key is used by default or the user can configure their own via
#' [drive_auth_config()].
#'
#' @template verbose
#'
#' @export
#' @family auth functions
#' @examples
#' \dontrun{
#' drive_deauth()
#' drive_user()
#' public_file <-
#'   drive_get(as_id("1Hj-k7NpPSyeOR3R7j4KuWnru6kZaqqOAE8_db5gowIM"))
#' drive_download(public_file)
#' }
drive_deauth <- function(verbose = TRUE) {
  set_auth_active(FALSE)
  set_access_cred(NULL)
}

#' View or set auth config
#'
#' @description This function gives advanced users more control over auth.
#' Whereas [drive_auth()] gives control over tokens, `drive_auth_config()`
#' gives control of:
#'   * The OAuth app. If you want to use your own app, setup a new project in
#'   [Google Developers Console](https://console.developers.google.com). Follow
#'   the instructions in
#'   [OAuth 2.0 for Mobile & Desktop Apps](https://developers.google.com/identity/protocols/OAuth2InstalledApp)
#'   to obtain your own client ID and secret. Either make an app from your
#'   client ID and secret via [httr::oauth_app()] or provide a path
#'   to the JSON file containing same, which you can download from
#'   [Google Developers Console](https://console.developers.google.com).
#'   * The API key. If googledrive auth is deactivated via [drive_deauth()], all
#'   requests will be sent with an API key in lieu of a token. If you want to
#'   provide your own API key, setup a project as described above and follow the
#'   instructions in [Setting up API
#'   keys](https://support.google.com/googleapi/answer/6158862).
#'
#' @param app OAuth app. Defaults to a tidyverse app that ships with
#'   googledrive.
#' @param api_key API key. Defaults to a tidyverse key that ships with
#'   googledrive. Necessary in order to make unauthorized "token-free" requests
#'   for public resources.
#' @inheritParams gargle::oauth_app_from_json
#'
#' @family auth functions
#' @return A list of class `auth_config`, with the current auth configuration.
#' @export
#' @examples
#' ## this will print current config
#' drive_auth_config()
#'
#' if (require(httr)) {
#'   ## bring your own app via client id (aka key) and secret
#'   google_app <- httr::oauth_app(
#'     "my-awesome-google-api-wrapping-package",
#'     key = "123456789.apps.googleusercontent.com",
#'     secret = "abcdefghijklmnopqrstuvwxyz"
#'   )
#'   drive_auth_config(app = google_app)
#' }
#'
#' \dontrun{
#' ## bring your own app via JSON downloaded from Google Developers Console
#' drive_auth_config(
#'   path = "/path/to/the/JSON/you/downloaded/from/google/dev/console.json"
#' )
#' }
drive_auth_config <- function(app = NULL,
                              path = NULL,
                              api_key = NULL) {
  stopifnot(is.null(app) || inherits(app, "oauth_app"))
  stopifnot(is.null(path) || is_string(path))
  stopifnot(is.null(api_key) || is_string(api_key))

  if (!is.null(app) && !is.null(path)) {
    stop_glue("Don't provide both 'app' and 'path'. Pick one.")
  }

  if (is.null(app) && !is.null(path)) {
    app <- gargle::oauth_app_from_json(path)
  }
  set_oauth_app(app %||% drive_oauth_app())
  set_api_key(api_key %||%  drive_api_key())

  structure(
    list(
      active = auth_active(),
      oauth_app_name = drive_oauth_app()[["appname"]],
      api_key = drive_api_key()
    ),
    class = c("auth_config", "list")
  )
}

#' @export
print.auth_config <- function(x, ...) {
  cat(glue(
    "googledrive auth state: ",
    "{if (x[['active']]) 'active' else 'inactive'}\n",
    "oauth app: ",
    "{x[['oauth_app_name']]}\n",
    "API key: ",
    "{if (is.null(x[['api_key']])) 'unset' else 'set'}\n",
    "token: ",
    "{if (is.null(access_cred())) 'not loaded' else 'loaded'}"
  ),
  sep = ""
  )
  invisible(x)
}

#' Produce Google token
#'
#' For internal use or for those programming around the Drive API. Produces a
#' token prepared for use with [request_generate()]. Most users do not need to
#' handle tokens "by hand" or, even if they need some control, [drive_auth()] is
#' what they need. If there is no current token, [drive_auth()] is called to
#' either load from cache or initiate OAuth2.0 flow. If auth has been
#' deactivated via [drive_auth_config()], `drive_token()` returns `NULL`.
#'
#' @return a `request` object (an S3 class provided by [httr][httr::httr])
#' @export
#' @family low-level API functions
#' @examples
#' \dontrun{
#' req <- request_generate(
#'   "drive.files.get",
#'   list(fileId = "abc"),
#'   token = drive_token()
#' )
#' req
#' }
drive_token <- function() {
  if (!auth_active()) {
    return(NULL)
  }
  if (is.null(access_cred())) {
    drive_auth()
  }
  httr::config(token = access_cred())
}

## Reveals the actual access token, suitable for use with curl.
access_token <- function() {
  if (is.null(access_cred())) return(NULL)
  .state$cred$credentials$access_token
}

set_auth_active <- function(value) {
  .state$active <- value
}

auth_active <- function() {
  .state$active
}

set_access_cred <- function(value) {
  .state$cred <- value
}

access_cred <- function() {
  .state$cred
}

#' Retrieve OAuth app or API key
#'
#' Retrieves the configured OAuth app and API key. Learn more in Google's
#' document [Credentials, access, security, and
#' identity](https://support.google.com/googleapi/answer/6158857?hl=en&ref_topic=7013279).
#' By default, the app and API key are initialized to settings that ship with
#' googledrive. But the user can store their own app or key via
#' [drive_auth_config()], i.e. overwrite the defaults.
#' @name auth-config
#' @return An [httr::oauth_app()] or Google API key.
#' @family auth functions
#' @examples
#' drive_api_key()
#' drive_oauth_app()
#'
#' \dontrun{
#' drive_auth_config(api_key = "123")
#' drive_api_key()
#' }
NULL

#' @rdname auth-config
#' @export
drive_api_key <- function() {
  .state[["api_key"]]
}

#' @rdname auth-config
#' @export
drive_oauth_app <- function() {
  .state[["oauth_app"]]
}

set_api_key <- function(value) {
  .state[["api_key"]] <- value
}

set_oauth_app <- function(value) {
  .state[["oauth_app"]] <- value
}

#' Check that token appears to be legitimate
#'
#' @keywords internal
is_legit_token <- function(x, verbose = FALSE) {
  if (!inherits(x, "Token2.0")) {
    if (verbose) message("Not a Token2.0 object.")
    return(FALSE)
  }

  if ("invalid_client" %in% unlist(x$credentials)) {
    # shouldn't happen if id and secret are good
    if (verbose) {
      message("Authorization error. Please check client_id and client_secret.")
    }
    return(FALSE)
  }

  if ("invalid_request" %in% unlist(x$credentials)) {
    # in past, this could happen if user clicks "Cancel" or "Deny" instead of
    # "Accept" when OAuth2 flow kicks to browser ... but httr now catches this
    if (verbose) message("Authorization error. No access token obtained.")
    return(FALSE)
  }

  TRUE
}
