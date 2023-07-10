library(plyr)
library(dplyr)
library(ggplot2)

load("intermediate_data/demo_firing_conditions_trimmed.Rdata")


##~~~~~~~~~~~~~~~~~~

# note I don't have a good estimate of when the final wash3 terminated
exposure_counts <- firing_trimmed |>
  dplyr::group_by(neuron_index, condition) |>
  dplyr::summarize(
    count = n(),
    exposure = end[1] - begin[1]) |>
  dplyr::ungroup()

ggplot2::ggplot(data = exposure_counts) +
  ggplot2::theme_bw() +
  ggplot2::geom_boxplot(
    mapping = ggplot2::aes(
      x = condition,
      y = count / exposure)) +
  ggplot2::geom_jitter(
    mapping = ggplot2::aes(
      x = condition,
      y = count / exposure),
    width = 0.15,
    height = 0) +
  ggplot2::ggtitle("Neuron Firing Rate by Condition") +
  ggplot2::scale_x_discrete("Condition") +
  ggplot2::scale_y_continuous(
    "Firings / second",
    breaks = c(.01, .03, .1, .3, 1.0, 3)) +
  ggplot2::coord_trans(y = "log10")

ggplot2::ggsave(
  "product/demo_exposure_counts_by_condition_190514.pdf",
  width = 6,
  height = 6)
ggplot2::ggsave(
  "product/demo_exposure_counts_by_condition_190514.png",
  width = 6,
  height = 6)


#~~~~~~~~~~~~~~~~~~~~~
# simple qqplot to qualitatively look at stationarity
data <- firing_trimmed |>
  dplyr::group_by(neuron_index, condition) |>
    dplyr::arrange(time_step) |>
    dplyr::mutate(cum_dist = row_number() / dplyr::n()) |>
  dplyr::ungroup() |>
  dplyr::filter(condition != "wash3")

ggplot2::ggplot(data = data) +
  ggplot2::theme_bw() +
  ggplot2::geom_abline(
    mapping = ggplot2::aes(
      slope = 1,
      intercept = 0),
    color = "blue",
    size = 2) +
  ggplot2::geom_line(
    mapping = aes(
      x = (time_step - begin) / (end - begin),
      y = cum_dist,
      group = neuron_index),
    alpha = 0.8) +
  ggplot2::facet_wrap(~ condition, ncol = 4) +
  ggplot2::ggtitle("QQ-plot of firing events over exposure") +
  ggplot2::scale_x_continuous("Percent exposure", labels = scales::percent) +
  ggplot2::scale_y_continuous(
    "Percent counts observed",
    labels = scales::percent)

ggplot2::ggsave("product/demo_qqplot_190514.pdf", width = 7, height = 4)
ggplot2::ggsave("product/demo_qqplot_190514.png", width = 7, height = 4)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Do different neuros have different average firing rates?
data <- firing_trimmed |>
  dplyr::filter(condition != "wash3") |>
  dplyr::group_by(neuron_index) |>
  dplyr::summarize(mean_firing_rate = n() / 3841)

ggplot2::ggplot(data = data) +
  ggplot2::theme_bw() +
  ggplot2::geom_histogram(
    aes(x = log(mean_firing_rate)),
    bins = 30) +
  ggplot2::ggtitle("Per-neuron firing rate") +
  ggplot2::scale_x_continuous("Log(Firing / second)")


ggplot2::ggsave(
  "product/demo_per-neuron_firing_rate_190514.pdf",
  width = 7,
  height = 4)
ggplot2::ggsave(
  "product/demo_per-neuron_firing_rate_190514.png",
  width = 7,
  height = 4)
