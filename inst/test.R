library(gargle)
library(httr)

creds <- jsonlite::fromJSON("credentials.json")

my_gdocs_app <- function() {
  httr::oauth_app(
    appname = "gdocs-api-test",
    key = creds$installed$client_id,
    secret = creds$installed$client_secret
  )
}

docs_token <- gargle2.0_token(email = "ross@ecohealthalliance.org",
                app = my_gdocs_app(), package = "googledocs",
                scope = "https://www.googleapis.com/auth/documents")
doc_id <- googledrive::as_id("https://docs.google.com/document/d/15mYX6JMxQPPEEgrqSXvvldAwzAq7SR5SAhQdLDMJBsE/edit")

req <- request_build(
  method = "GET",
  path = "v1/documents/{name}",
  token = docs_token,
  base_url = "https://docs.googleapis.com",
  params = list(
    name = doc_id
  )
)
gdoc <- request_make(req)
doc <- jsonlite::fromJSON(content(gdoc, as = "text"), simplifyVector = FALSE)

#View(doc)

newdoc <- list(title = "test-new-gdoc")
newdocreqbody <- jsonlite::toJSON(newdoc, auto_unbox = TRUE)
req <- request_build(
  method = "POST",
  path = "v1/documents/",
  token = docs_token,
  base_url = "https://docs.googleapis.com",
  body = newdocreqbody
)

newdocback <- request_make(req)
newgdoc <- jsonlite::fromJSON(content(gdoc, as = "text"), simplifyVector = FALSE)


update_body <- list()
update_body$requests <- list(
  insertText = list(
    location = list(
      segmentId = "",
      index = 5
    ),
    text = "some awesome text"
  ))
update_body$writeControl <- list(
  requiredRevisionId = doc$revisionId
)
update_body <- jsonlite::toJSON(update_body, auto_unbox = TRUE, pretty=TRUE)

req <- request_build(
  method = "POST",
  path = "v1/{name}:batchUpdate",
  token = docs_token,
  params = list(
    name = doc$name
  ),
  base_url = "https://docs.googleapis.com",
  body = update_body
)

edit_response <- request_make(req)
edit_response
