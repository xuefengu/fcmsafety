#' Extract compound identification number (CID) from Pubchem
#'
#' \code{extract_cid()} is a simple wrapper of the \code{get_cid()} function from
#' the \emph{webchem} package. It extracts \strong{cid} based on \strong{InChIKey},
#' \strong{CAS} and then on chemical names when no \strong{cid} is available
#' from the previous step. When multiple matches returns, only the first one will
#' be kept. Importantly, it appends these information to your original data.frame,
#' which is more friendly for new R users.
#'
#' @param data A data.frame or tibble contains at least CAS and Chemical name columns.
#' @param cas_col The index of column that contains CAS information. CAS number
#' is not mandatory for each compound, if no CAS is available, then chemical name
#' will be used for retreival. However, a column index is still required.
#' @param name_col The index of column that contains chemical name.
#' @param inchikey_col The index of column that contains InChIKey. It is optional
#' and the default value is \code{FALSE} assuming no InChIKey column is provided.
#'
#' @return A data.frame or tibble with a CID column added.
#'
#' @export
#'
#' @importFrom webchem get_cid
#' @import dplyr
#'
#' @examples
#' # without InChIKey
#' x <- data.frame(CAS = "128-37-0", Name = "BHT")
#' x_cid <- extract_cid(x, cas_col = 1, name_col = 2)
#'
#' # with InChIKey
#' x <- data.frame(CAS = "128-37-0", Name = "BHT", InChIKey = "NLZUEZXRPGMBCV-UHFFFAOYSA-N")
#' x_cid <- extract_cid(x, cas_col = 1, name_col = 2, inchikey_col = 3)
extract_cid <- function(data, cas_col, name_col, inchikey_col = FALSE){
  if(inchikey_col == TRUE) {
    data <- data %>%
      mutate(CID = get_cid(.[, inchikey_col], match = "first")$cid)
  } else {
    data <- data
  }

  data <- data %>%
    mutate(CID = get_cid(.[, cas_col], match = "first")$cid,
           CID = case_when(is.na(CID) ~
                             get_cid(.[, name_col], from = "name", match = "first")$cid,
                           TRUE ~ CID),
           CID = as.integer(CID))

  return(data)
}


#' Extract meta data from Pubchem
#'
#' \code{extract_meta()} is a wrapper of the the \code{pc_prop()} function from
#' the \emph{webchem}. It extracts only \strong{"IsomericSMILES", "InChIKey",
#' "ExactMass", "MolecularFormula"} properties and appends them into the input
#' data.frame or tibble. It can be used together with the \code{extract_cid()}
#' function. The CID column must has "CID" column name.
#'
#' @param data A data.frame or tibble containing at least CID column.
#'
#' @return A data.frame or tibble with IsomericSMILES, InChIKey, ExactMass,
#' and MolecularFormula extracted.
#'
#' @export
#'
#' @importFrom webchem pc_prop
#' @import dplyr
#'
#' @examples
#' # Together with \code{extract_cie()}
#' library(dplyr)
#' x <- data.frame(CAS = "128-37-0", Name = "BHT")
#' x_cid <- extract_cid(x, cas_col = 1, name_col = 2) %>% extract_meta()
extract_meta <- function(data) {
  data <- data %>%
    filter(!is.na(CID)) %>%
    distinct(CID) %>%
    pc_prop(properties =
              c("IsomericSMILES", "InChIKey", "ExactMass", "MolecularFormula")) %>%
    left_join(data, ., by = "CID")

  return(data)
}

