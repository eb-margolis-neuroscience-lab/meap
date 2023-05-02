#' Unit Response Correlation by Treatment
#'
#'  Grid of treatment vs. treatment plots, in each cell
#'      scatter plot for each neuronal unit
#'        the x-axis is average firing rate for treatment of column
#'        the y-axis is average firing rate for treatment of row
#'
#' @param experiment [meapr-experiment] data set loaded with
#'   [load_experiment_matlab] or [load_experiment_spyking_circus]
#'
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
plot_unit_response_by_treatment <- function(
  experiment,
  plot_width = 10,
  plot_height = 10,
  output_base = "product/plots",
  verbose = FALSE) {

  exposure_counts <- experiment$firing |>
    dplyr::group_by(neuron_index, treatment) |>
    dplyr::summarize(
      log_firing_rate = log(dplyr::n() / (end[1] - begin[1]))) |>
    dplyr::ungroup() |>
    tidyr::spread(key = "treatment", value = "log_firing_rate", fill = 0) |>
    dplyr::select(-neuron_index)

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

    p <- GGally::ggpairs(
      data = exposure_counts,
      title = paste0(
        "Correlation of unit response by treatment: ", experiment$tag),
      xlab = "Log(Firing Rate)",
      ylab = "Log(Firing Rate)")

    pdf_path <- paste0(
      output_base, "/plot_unit_response_by_treatment_", experiment$tag,
      "_", date_code(), ".pdf")
    if (verbose) {
      cat(
        "Saving plot_unit_response plot for experiment ",
        "'", experiment$tag, "' to '", pdf_path, "'\n", sep = "")
    }
    grDevices::pdf(
      pdf_path,
      height = plot_height,
      width = plot_width)
    print(p)
    grDevices::dev.off()

    png_path <- paste0(
      output_base, "/plot_unit_response_by_treatment_", experiment$tag,
      "_", date_code(), ".png")
    if (verbose) {
      cat(
        "Saving plot_unit_response_by_treatment plot for experiment ",
        "'", experiment$tag, "' to '", png_path, "'\n", sep = "")
    }
    grDevices::png(
      png_path,
      units = "in",
      res = 72,
      height = plot_height,
      width = plot_width)
    print(p)
    grDevices::dev.off()
  }
}
