plotRaster <- function(spike_times, seg_length=30, burst_labels=NULL) {
  # create and assign segments 
  n_spikes = length(spike_times)
  total_s = spike_times[n_spikes]
  num_segs = ceiling(total_s/seg_s)
  seg_heights = seq(from=1, to=0, length.out=num_segs+1)
  assign_segs = matrix(0, nrow=n_spikes, ncol=1)
  for (i in 1:num_segs) {
    assign_segs[spike_times>=seg_s*(i-1) & spike_times<=(seg_s*i)] = i
    spike_times[assign_segs==i] = spike_times[assign_segs==i]-(seg_s*(i-1))
  }
  
  # format into data frame 
  tol=seg_heights[length(seg_heights)-1]/2 # create separation between segments
  spike_index=seq(from=1, to=n_spikes)
  plot_data <- data.frame(spike_index) |>
    dplyr::mutate(
      x0 = spike_times[,1],
      x1 = spike_times[,1],
      y0 = seg_heights[assign_segs]-tol,
      y1 = seg_heights[assign_segs+1])
  
  # plot
  raster = ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = plot_data,
      mapping = ggplot2::aes(
        x = x0,
        y = y0,
        xend = x1,
        yend = y1),
      color="black",
      alpha = 1) + 
    ggplot2::scale_x_continuous(
      name = "Time (s)") + 
    ggplot2::theme_bw() +
    ggplot2::theme(
      axis.title.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank())
  
  # plot bursts if needed
  if (!is.null(burst_labels)) {
    # generate lines to plot
    num_bursts = max(burst_labels)
    burst_plot_data = as.data.frame(matrix(nrow=num_bursts, ncol=5))
    colnames(burst_plot_data) <- c("burst_index", "x0", "x1", "y0", "y1")
    for (i in 1:num_bursts) {
      buffer = which(burst_labels==i)
      burst_plot_data[i, "burst_index"] = buffer[1]
      burst_plot_data[i, 2:3] = spike_times[buffer[1]:buffer[length(buffer)]]
      burst_plot_data[i, 4:5] = plot_data[buffer[1], "y0"] + 0.01
    }
    
    # add lines to raster
    raster = raster + ggplot2::geom_segment(
      data = burst_plot_data,
      mapping = ggplot2::aes(
        x = x0,
        y = y0,
        xend = x1,
        yend = y1),
      color="blue",
      alpha = 1,
      linewidth = 2)
  }
  
  return(list(raster, burst_plot_data))
}