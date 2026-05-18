

#' Plot Density of Recording Amplitudes by Channel
#' 
#' 
#' @param recording `matrix` result of `meap::load_recording()`:
#'  a `matrix` with dimensions `[n_channels, n_samples]` with values as signed
#'  integers, typically in the range e.g. `[-100, 100]`.
#' @param extra_layers `list` extra ggplot2 layers to be added to the plot
#'   before saving it.
#' @param plot_width `numeric` width of the output plot
#' @param plot_height `numeric` height of the output plot
#' @param output_base `character` where to output plots
#' @param verbose `logical` print out verbose output
#'
#' @returns: [ggplot2::ggplot] of the plot and it saves the result to
#'   `product/plots/firing_qqplot_by_treatment_<experiment_tag>_<date_code>.(pdf|png)`
#'   It save both .pdf and .png because it's easier to email etc small pngs
#'   while for use in an a manuscript having the vector version means that it`
#'   can be tweaked with illustrator
#' @export
plot_recording_amplitude_density <- function(
  recording,
  extra_layers,
  width = 10,
  height = 10,
  output_base,
  verbose = FALSE) {
  
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
  }  
  
  n_channels <- nrow(recording)
  n_samples <- ncol(recording)
  min_val <- min(recording)
  max_val <- max(recording)
  K <- max_val - min_val + 1
  
  if (verbose) {
    cat(
      "Computing amplitude densities for ",
      "min_val: ", min_val, " max_val: ", max_val, "\n",
      sep = "")
  }
  
  # do this counting manually for speed
  counts <- matrix(0L, nrow = n_channels, ncol = K)
  for (i in seq_len(n_channels)) {
    if (verbose) {
      cat("Computing counts for channel ", i, "\n", sep = "")
    }
    counts[i,] <- tabulate(recording[i, ] - min_val + 1, nbins = K)
  }
  densities <- counts / n_samples
  colnames(densities) <- seq(min_val, max_val) |> as.character()
  colnames(counts) <- seq(min_val, max_val) |> as.character()
  
  plot_data <- log10(counts + 1) |>
    as.data.frame() |>
    dplyr::mutate(
      channel_index = seq_len(n_channels),
      channel_label = paste0("Channel: ", channel_index) |>
        forcats::fct_inorder(),
      .before = 1) |>
    tidyr::pivot_longer(
      cols = c(-channel_index, -channel_label),
      names_to = "amplitude",
      values_to = "log1p_counts") |>
    dplyr::mutate(
      amplitude = amplitude |> as.numeric())
  
  plot <- ggplot2::ggplot(data = plot_data) +
    ggplot2::theme_bw() +
    ggplot2::geom_col(
      mapping = ggplot2::aes(
        x = amplitude,
        y = log1p_counts)) +
    ggplot2::facet_wrap(facets = dplyr::vars(channel_label)) +
    ggplot2::labs(
      x = "Recording Amplitude",
      y = "Density") +
    ggplot2::ggtitle(
      "Distribution of Recording Amplitudes by Channel") +
    ggplot2::scale_x_continuous() +
    ggplot2::scale_y_continuous(
      breaks = log10(c(0, 100, 10000, 1000000) + 1),
      labels = c("0", "1e2", "1e4", "1e6"))
  
  if (!is.null(output_base)) {
    
    pdf_path <- paste0(
      output_base, "/lines_firing_rate_by_treatment_", experiment$tag,
      "_", date_code(), ".pdf")
    if (verbose) {
      cat(
        "Saving lines_firing_rate_by_treatment plot for experiment ",
        "'", experiment$tag, "' to '", pdf_path, "'\n", sep = "")
    }
    ggplot2::ggsave(
      pdf_path,
      width = plot_width,
      height = plot_height)
    
    png_path <- paste0(
      output_base, "/lines_firing_rate_by_treatment_", experiment$tag,
      "_", date_code(), ".png")
    if (verbose) {
      cat(
        "Saving lines_firing_rate_by_treatment plot for experiment ",
        "'", experiment$tag, "' to '", png_path, "'\n", sep = "")
    }
    ggplot2::ggsave(
      png_path,
      width = plot_width,
      height = plot_height)
  }
  
  invisible(plot)
}