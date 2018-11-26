google_document <- function(toc = FALSE, toc_depth = 3, fig_width = 5,
                            fig_height = 4, fig_caption = TRUE, df_print = "default",
                            smart = TRUE, highlight = "default", reference_docx = "default",
                            keep_md = FALSE, md_extensions = NULL, pandoc_args = NULL) {

  rmarkdown::output_format(
   knitr = rmarkdown::knitr_options(),
   pandoc = rmarkdown::pandoc_options()
  )
}

rmd_pkg <- function() {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("Thee 'rmarkdown' package is required to use this function")
  }
}
