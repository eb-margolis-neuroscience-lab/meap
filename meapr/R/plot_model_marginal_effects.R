#' Plot Model Conditional Effects
#'
#' @param model_fit [brms::brmsfit] model object
#' @param plot_width `numeric` width of the output plot
#' @param plot_height `numeric` height of the output plot
#' @param verbose `logical` print out verbose output
#'
#' @returns: [ggplot2::ggplot] of the plot and it saves the result to
#'   `product/plots/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.(pdf|png)`
#'   It save both .pdf and .png because it's easier to email etc small pngs
#'   while for use in an a manuscript having the vector version means that it`
#'   can be tweaked with illustrator
#'
#'@export
plot_model_marginal_effects <- function(
  model_fit,
  model_tag,
  plot_width = 6,
  plot_height = 6,
  output_base = "product/plots",
  verbose = FALSE,
  ...) {

  marginal_effects <- brms::marginal_effects(model_fit, ...)

  p <- plot(
    marginal_effects,
    point_args = list(width = 0.2),
    ask = FALSE)$treatment +
    ggplot2::theme_bw() +
    ggplot2::ggtitle("Model Fit Marginal Effects", subtitle = model_tag)

  if (!is.null(output_base)) {
    if (!dir.exists(output_base)) {
      if (verbose) {
        cat("creating output directory '", output_base, "'\n", sep = "")
      }
      dir.create(
        output_base,
        showWarnings = FALSE,
        recursive = TRUE)
    }

    pdf_path <- paste0(
      output_base, "/marginal_effects_", model_tag, "_", date_code(), ".pdf")
    if (verbose) {
      cat(
        "Saving marginal effects plot for model fit '", model_tag, "' to ",
        "'", pdf_path, "'\n", sep = "")
    }
    ggplot2::ggsave(pdf_path, width = plot_width, height = plot_height)

    png_path <- paste0(
      output_base, "/firing_rate_by_neuron_", model_tag,
      "_", date_code(), ".png")
    if (verbose) {
      cat("Saving marginal effects plot for model fit '", model_tag, "' to ",
        "'", png_path, "'\n", sep = "")
    }
    ggplot2::ggsave(
      png_path,
      width = plot_width,
      height = plot_height)
  }

  invisible(p)
}
