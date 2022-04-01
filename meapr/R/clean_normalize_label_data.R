
rm_time_off_baseline <- function(exp, seconds){

  exp$firing$begin <- ifelse(exp$firing$treatment == "Baseline",
                             exp$firing$begin + seconds,
                             exp$firing$begin)

  exp$firing <- exp$firing %>% dplyr::filter(time_step >= begin, time_step <= end)

  return(exp)
}


rm_60s_treatments <- function(exp){

  exp$begin <- ifelse(exp$treatment != "Baseline",
                      exp$begin + 60,
                      exp$begin)

  exp <- exp %>% dplyr::filter(time_step >= begin, time_step <= end)

  return(exp)
}




exposure_counts <- function(exp){
  exp %>%
    dplyr::group_by(neuron_index, treatment) %>%
    dplyr::summarize(
      begin = begin[1],
      end = end[1],
      count = dplyr::n(),
      exposure = end[1] - begin[1],
      firing_rate = count/exposure
    ) %>%
    tidyr::complete(treatment,
                    fill = list(count = 0, exposure = 0, firing_rate = 0))
  #dplyr::ungroup() %>% tidyr::drop_na(begin)
}


filter_data_baseline <- function(exp, lower, upper) {

  exp <- exp %>%
    dplyr::group_by(neuron_index) %>%
    dplyr::filter(firing_rate[treatment == "Baseline"] >= lower,
                  firing_rate[treatment == "Baseline"]<= upper)
  return(exp)
}



norm_firing <- function(exp){

  exp <- exp %>%
    dplyr::group_by(neuron_index) %>%
    mutate(norm_firing_rate = 100 * firing_rate / firing_rate[treatment == "Baseline"]) %>%
    dplyr::ungroup()

  return(exp)
}


add_neuron_id <- function(exp, exp_name){

  exp <- add_column(exp, exp_id = exp_name, .before = "neuron_index")
  exp <- add_column(exp, neuron_id = stringr::str_c(exp$exp_id,
                                                    '_',
                                                    exp$neuron_index),
                    .before = "treatment")
  return(exp)
}


label_condition <- function(exp, treatment_label){

  exp <- exp %>%
    dplyr::mutate(
      condition = ifelse(
        treatment %>% stringr::str_detect({{treatment_label}}), "treatment", "control"))
  return(exp)
}


label_responsiveness <- function(exp, min_threshold, max_threshold){
  exp <- exp %>%
    dplyr::left_join(
      exp %>%
        dplyr::group_by(neuron_id) %>%
        dplyr::mutate(
          responsive = case_when(
            min(norm_firing_rate[condition == "treatment"],
                na.rm = TRUE) <= min_threshold ~ "decreasing",
            max(norm_firing_rate[condition == "treatment"],
                na.rm = TRUE) >= max_threshold ~ "increasing",
            min(norm_firing_rate[condition == "treatment"],
                na.rm = TRUE) >= min_threshold |
              max(norm_firing_rate[condition == "treatment"],
                  na.rm = TRUE) <= max_threshold ~ "low_response"
          )) %>% dplyr::ungroup())

  return(exp)
}


label_Hz <- function(exp){
  exp <- exp %>%
    dplyr::group_by(neuron_id) %>% dplyr::mutate(
      Hz = case_when(
        firing_rate[treatment == "Baseline"] < 0.5 ~ "< 0.5 Hz",
        firing_rate[treatment == "Baseline"] >= 0.5 ~ ">= 0.5 Hz"))
  return(exp)
}


all_functions <- function(exp, seconds, exp_name, treatment_label,
                          min_threshold, max_threshold){
  exp <- rm_time_off_baseline(exp, seconds)
  exp <- rm_60s_treatments(exp = exp$firing)
  exp <- exposure_counts(exp = exp)
  exp <- norm_firing(exp = exp)
  exp <- add_neuron_id(exp = exp, exp_name)
  exp <- label_condition(exp = exp, treatment_label)
  exp <- label_responsiveness(exp = exp, min_threshold, max_threshold)
  exp <- label_Hz(exp = exp)
  return(exp)
}
