library(plyr)
library(dplyr)
library(tidyr)
library(purrr)
library(ggplot2)
library(seriation)
library(viridis)
library(gplots)
load("intermediate_data/demo_waveform.Rdata")


#~~~~~~~~~~~~~~~~~~~~~~~~
# Simple lattice plot of the waveforms
ggplot2::ggplot(data = waveform) +
  ggplot2::theme_bw() +
  ggplot2::geom_line(
    mapping = ggplot2::aes(
      x = time_step,
      y = voltage)) +
  ggplot2::facet_wrap(~ neuron_index) +
  ggplot2::ggtitle("Neuron waveform cluster mean") +
  ggplot2::scale_x_continuous("microsecond") +
  ggplot2::scale_y_continuous("Voltage")

ggplot2::ggsave("product/demo_waveforms_190513.pdf", width = 10, height = 10)
ggplot2::ggsave("product/demo_waveforms_190513.png", width = 10, height = 10)

#~~~~~~~~~~~~~~~~~~~~~~~~
correlations <- waveform |>
  reshape2::acast(time_step ~ neuron_index, value.var = "voltage") |>
  stats::cor()

d <- stats::dist(correlations)
o_row <- seriate(d, method = "OLO", control = NULL)[[1]]
args <- list(
  trace = "none",
  density.info = "none",
  col = viridis::viridis(100),
  cexRow = 1,
  cexCol = 1,
  dendrogram = "none",
  key = FALSE,
  keysize = 0.03,
  x = correlations,
  Colv = stats::as.dendrogram(o_row),
  Rowv = stats::as.dendrogram(o_row))
grDevices::pdf(
  file = "product/demo_waveform_correlation_matrix_190513.pdf",
  heigh = 6,
  width = 6)
  do.call(gplots::heatmap.2, args = args)
grDevices::dev.off()
grDevices::png(
  "product/demo_waveform_correlation_matrix_190513.png",
  heigh = 600,
  width = 600)
  do.call(gplots::heatmap.2, args = args)
grDevices::dev.off()
