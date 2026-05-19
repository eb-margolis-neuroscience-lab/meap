#' Plot Model Conditional Effects
#'
#' @param model_fit [brms::brmsfit] model object
#' @param model_tag `character` tag for the model
#' @param extra_layers `list` extra ggplot2 layers to be added to the plot
#'   before saving it.
#' @param plot_width `numeric` width of the output plot.
#' @param plot_height `numeric` height of the output plot.
#' @param output_base `character` where to output plots.
#' @param verbose `logical` print out verbose output.
#'
#' @returns: [ggplot2::ggplot] of the plot and it saves the result to
#'   `<output_base>/marginal_effects_<model_tag>_<date_code>.(pdf|png)`
#'   It save both .pdf and .png because it's easier to email etc small png files
#'   while for use in an a manuscript having the vector version means that it`
#'   can be tweaked with illustrator
#'
#'@export
plot_model_conditional_effects <- function(
  model_fit,
  model_tag,
  extra_layers = list(),
  plot_width = 6,
  plot_height = 6,
  output_base = "product/plots",
  verbose = FALSE,
  ...) {

  if (!dir.exists(output_base)) {
    if (verbose) {
      cat("creating output directory '", output_base, "'\n", sep = "")
    }
    dir.create(
      output_base,
      showWarnings = FALSE,
      recursive = TRUE)
  }
  
  
  marginal_effects <- brms::conditional_effects(model_fit, ...)

  p <- plot(
    marginal_effects,
    point_args = list(width = 0.2),
    ask = FALSE)$treatment +
    ggplot2::theme_bw() +
    ggplot2::ggtitle(
      "Model Fit Marginal Effects",
      subtitle = model_tag) +
    extra_layers

  if (!is.null(output_base)) {
    pdf_path <- paste0(
      output_base, "/marginal_effects_", model_tag, "_", date_code(), ".pdf")
    if (verbose) {
      cat(
        "Saving marginal effects plot for model fit '", model_tag, "' to ",
        "'", pdf_path, "'\n", sep = "")
    }
    ggplot2::ggsave(
      filename = pdf_path,,
      plot = p,
      width = plot_width,
      height = plot_height)

    png_path <- paste0(
      output_base, "/marginal_effects_", model_tag, "_", date_code(), ".png")
    if (verbose) {
      cat("Saving marginal effects plot for model fit '", model_tag, "' to ",
        "'", png_path, "'\n", sep = "")
    }
    ggplot2::ggsave(
      filename = png_path,
      plot = p,
      width = plot_width,
      height = plot_height)
  }

  invisible(p)
}
