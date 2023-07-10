#' meapr: Multi-Electrode Array Pharmacology in R
#'
#' @docType package
#' @name meapr-package
#' @aliases meapr
#'
#' @description
#' The [meapr] R package is part of the **meap**, a multi-language framework for
#' the pharmacology analysis of *Multi-Electrode Array Experiments*. A
#' multi-electrode array experiment consists of placing a sample such as a brain
#' slice on an array of electrodes which can detect individual firing events
#' (spikes) based on the change in electrical potential at one or more
#' electrodes (e.g. for the MED64 platform there are 8x8 electrodes arranged in
#' a grid). Electrical traces can be recorded for up to several hours with
#' millisecond timing precision. The sample can be manipulated by, for example,
#' applying drugs or other treatments directly. In a typical experiment, after
#' recordings from a sample has begun, it is equilibrated to form a baseline
#' for e.g. 5-10 minutes, then a series of treatments are applied and the
#' transient and stationary effects of the treatment are observed over
#' e.g. 5-10 minutes each.
#'
#'   To process these data, the electrode traces are sorted into discrete firing
#' events and then clustered across electrodes into units which represent
#' individual neurons. The central pharmacology question is to understand how
#' the treatments cause the observed patterns in firing event time series.
#'
#' Here are some considerations
#'   * Each firing event has the associated **waveform** with e.g. an amplitude
#'     and duration.
#'   * The firing patterns for neuron in each treatment can be transient or
#'     stationary. For *stationary* behavior, *firing rate* and *dispersion*
#'     capture the overall activity of each neuron, while the
#'     *temporal auto-correlation* gives the fine structure firing patterns over
#'     different timescales. For example, at short timescales, common pattern to
#'     see are (1) a refactory period after each firing event, (2) regular tonic
#'     firing a preferred frequency, and (3) burst firing with intervals of high
#'     and low firing rates.
#'   * **Transient** firing patterns after a treatment has been applied include
#'     rapid changes in firing patterns that decay into stationary behavior.
#'   * Neuronal response to treatments can be **non-exchangeable** if the
#'     responses depend on the order in which they are applied. For example, if
#'     a treatment has acute toxicity, or desensitization, later treatments may
#'     fail to evoke typical responses. To observe and characterize these
#'     diverse treatment effects
#'   * Within a sample there may be **neuronal heterogeneity**, where different
#'     neurons and may have different firing patterns and responses to
#'     treatments.
#'   * Samples may have **batch effects** that can that depend on source animal,
#'     the treatment batch, the recording session, and the experimental
#'     apparatus, and experimenter.
#'
#'
#' The core capabilities of [meapr] are to
#'    * **Load sorted spikes** from from programs such as SpyKING Circus that
#'      take raw electrical traces and produce sparse firing event data
#'    * **Quality control** for multi-electrode array experimental data
#'      including checking the quality of neurons and stability baselines.
#'    * **Estimate firing patterns** of neurons across treatments and
#'      experiments.
NULL
