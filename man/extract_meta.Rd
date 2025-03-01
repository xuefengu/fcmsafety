% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/chemical_information_retrieval.R
\name{extract_meta}
\alias{extract_meta}
\title{Extract meta data from Pubchem}
\usage{
extract_meta(data, cas = FALSE, flavornet = FALSE)
}
\arguments{
\item{data}{A data.frame or tibble containing at least CID column.}

\item{cas}{A logical value to determine if you want to retrieve CAS. It will
generate a new column named "CAS_retrieved". It is necessary for extracting
flavornet information.}

\item{flavornet}{A logical value for flavornet information retrieval.
cas = TRUE is required for this purpose.}
}
\value{
A data.frame or tibble with IsomericSMILES, InChIKey, ExactMass,
and MolecularFormula extracted.
}
\description{
\code{extract_meta()} is a wrapper of the the \code{pc_prop()} function from
the \emph{webchem}. It extracts only \strong{"IsomericSMILES", "InChIKey",
"ExactMass", "MolecularFormula"} properties and appends them into the input
data.frame or tibble. It also support extracting CAS number with the cas
argument and flavor information from Flavornet with the flavornet argument.
It can be used together with the \code{extract_cid()}
function. If you previously have columns named "SMILES", "InChIKey", "ExactMass",
or "Formula", they will be modified to "_old" suffix.
}
\examples{
# Together with \code{extract_cid()}
library(dplyr)
x <- data.frame(CAS = "128-37-0", Name = "BHT")
x_cid <- extract_cid(x, cas_col = 1, name_col = 2) \%>\% extract_meta()
}
