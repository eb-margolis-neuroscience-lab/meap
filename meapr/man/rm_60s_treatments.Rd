% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clean_normalize_label_data.R
\name{rm_60s_treatments}
\alias{rm_60s_treatments}
\title{Trim 60 Seconds off of the Beginning of all Treatments Except the Baseline}
\usage{
rm_60s_treatments(exp, baseline_treatment_name = "Baseline")
}
\arguments{
\item{exp}{\link{meapr-experiment}, a \link{meapr} experiment object}

\item{baseline_treatment_name}{\code{character} name of the baseline treatment}
}
\value{
The \link{meapr-experiment} that was passed in as \code{exp}, but with the
each trimmed by 60 seconds
}
\description{
Trim 60 Seconds off of the Beginning of all Treatments Except the Baseline
}
