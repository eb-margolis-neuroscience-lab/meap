scale_y_log_firing_rate <- function() {
  list(
    ggplot2::scale_y_log10(
      name = "Firing Rate (Hz)",
      breaks = scales::trans_breaks("log10", function(x) 10 ^ x),
      labels = scales::trans_format("log10", scales::math_format(10 ^ .x))),
    ggplot2::annotation_logticks(sides = "lr"),
    ggplot2::theme(panel.grid.minor.y = ggplot2::element_blank()))
}

scale_x_log_firing_rate <- function() {
  list(
    ggplot2::scale_x_log10(
      name = "Firing Rate (Hz)",
      breaks = scales::trans_breaks("log10", function(x) 10 ^ x),
      labels = scales::trans_format("log10", scales::math_format(10 ^ .x))),
    ggplot2::annotation_logticks(sides = "tb"),
    ggplot2::theme(panel.grid.minor.x = ggplot2::element_blank()))
}

scale_xy_log_firing_rate <- function() {
  list(
    ggplot2::scale_y_log10(
      name = "Firing Rate (Hz)",
      breaks = scales::trans_breaks(
        trans = "log10",
        inv = function(x) 10 ^ x),
      labels = scales::trans_format(
        trans = "log10",
        format = scales::math_format(10 ^ .x))),
    
    ggplot2::scale_x_log10(
      name = "Firing Rate (Hz)",
      breaks = scales::trans_breaks(
        trans = "log10",
        inv = function(x) 10 ^ x),
      labels = scales::trans_format(
        trans = "log10",
        format = scales::math_format(10 ^ .x))),
    
    ggplot2::annotation_logticks(sides = "lrtb"),
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank()))
}
