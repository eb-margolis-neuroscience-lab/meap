
plot_firing_responsive <- function(data, x_axis_order, title, y_label, x_label){

  ggplot2::ggplot(data = data) +
    ggplot2::theme_bw() +
    ggplot2::geom_point(
      mapping=ggplot2::aes(x = factor(treatment, 
                                      levels = x_axis_order), 
                           y = norm_firing_rate)) +
    ggplot2::ggtitle(title) +
    ggplot2::ylab(y_label) + 
    ggplot2::scale_x_discrete(x_label) +
    ggplot2::geom_line(
      mapping=ggplot2::aes(x = factor(treatment, 
                                      levels = x_axis_order),
                           y = norm_firing_rate,
                           group = neuron_id,
                           color = responsive)) +
    ggplot2::facet_grid(responsive ~ Hz) +
    ggplot2::scale_y_log10()
  
}
