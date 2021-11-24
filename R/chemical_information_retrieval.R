#' Extract compound identification number (CID) from Pubchem
#'
#' \code{extract_cid()} is a simple wrapper of the \code{get_cid()} function from
#' the \emph{webchem} package. It extracts \strong{cid} based on the keys, i.e.,
#' \strong{InChIKey}, \strong{CAS} and \strong{chemical names}. You can use
#' any or all of these keys. In the latter case, it will first use InChIKey,
#' followed by CAS and chemical name if no CID is available from the previous step.
#' When multiple matches returns, only the first one will be kept. Importantly,
#' it appends these information to your original data.frame, which is more friendly
#' for new R users. Only English chemical name is accepted.
#'
#' @param data A data.frame or tibble contains at least CAS, Chemical name, or
#' InChIKey column.
#' @param cas_col The index of column that contains CAS information. CAS number
#' is not mandatory for each compound, if no CAS is available, then chemical name
#' will be used for retrieval.
#' @param name_col The index of column that contains chemical name.
#' @param inchikey_col The index of column that contains InChIKey. It is optional.
#'
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
extract_cid <- function(data,
                        name_col = FALSE,
                        cas_col = FALSE,
                        inchikey_col = FALSE) {
  # if there is no CID in the data, create one
  if (!"CID" %in% colnames(data))
    # must be character
    data$CID <- NA_character_

  if (inchikey_col != FALSE) {
    data <- data %>%
      mutate(CID = case_when(
        is.na(CID) ~
          get_cid(.[, inchikey_col],
                  match = "first", from = "inchikey")$cid %>%
          as.character(), # turn it to character is vital
        TRUE ~ CID
      ))
  }

  if (cas_col != FALSE) {
    data <- data %>%
      mutate(CID =
               case_when(is.na(CID) ~ get_cid(.[, cas_col], match = "first")$cid %>%
                           as.character(),
                         TRUE ~ CID))
  }

  if (name_col != FALSE) {
    data <- data %>%
      mutate(CID =
               case_when(
                 is.na(CID) ~ get_cid(.[, name_col],
                                      from = "name", match = "first")$cid %>%
                   as.character(),
                 TRUE ~ CID
               ))
  }

  data$CID <- as.integer(data$CID)

  return(data)
}

#' Extract meta data from Pubchem
#'
#' \code{extract_meta()} is a wrapper of the the \code{pc_prop()} function from
#' the \emph{webchem}. It extracts only \strong{"IsomericSMILES", "InChIKey",
#' "ExactMass", "MolecularFormula"} properties and appends them into the input
#' data.frame or tibble. It also support extracting CAS number with the cas
#' argument and flavor information from Flavornet with the flavornet argument.
#' It can be used together with the \code{extract_cid()}
#' function. If you previously have columns named "SMILES", "InChIKey", "ExactMass",
#' or "Formula", they will be modified to "_old" suffix.
#'
#' @param data A data.frame or tibble containing at least CID column.
#' @param cas A logical value to determine if you want to retrieve CAS. It will
#' generate a new column named "CAS_retrieved". It is necessary for extracting
#' flavornet information.
#' @param flavornet A logical value for flavornet information retrieval.
#' cas = TRUE is required for this purpose.
#'
#' @return A data.frame or tibble with IsomericSMILES, InChIKey, ExactMass,
#' and MolecularFormula extracted.
#'
#' @export
#'
#' @import webchem
#' @import dplyr
#'
#' @examples
#' # Together with \code{extract_cid()}
#' library(dplyr)
#' x <- data.frame(CAS = "128-37-0", Name = "BHT")
#' x_cid <- extract_cid(x, cas_col = 1, name_col = 2) %>% extract_meta()
extract_meta <- function(data, cas = FALSE, flavornet = FALSE) {
  # to avoid duplicate InChIKey when merging the extracted data
  if("InChIKey" %in% colnames(data))
    data <- data %>% rename(InChIKey_old = InChIKey)
  if("SMILES" %in% colnames(data))
    data <- data %>% rename(SMILES_old = SMILES)
  if("Formula" %in% colnames(data))
    data <- data %>% rename(Formula_old = Formula)
  if("ExactMass" %in% colnames(data))
    data <- data %>% rename(ExactMass_old = ExactMass)

  data <- data %>%
    filter(!is.na(CID)) %>%
    distinct(CID) %>%
    pc_prop(properties =
              c("IsomericSMILES", "InChIKey", "ExactMass", "MolecularFormula")) %>%
    left_join(data, ., by = "CID") %>%
    rename(SMILES = IsomericSMILES,
           Formula = MolecularFormula)

  # retrieve CAS
  if(cas == TRUE) {
    for(i in 1:nrow(data)){
      # keep only the first one.
      tmp <- webchem::pc_sect(data$CID[i], "cas")$Result[1] %>%
        suppressWarnings()
      if(length(tmp) != 0){data$CAS_retrieved[i] <- tmp}
    }
  }

  # retrieve flavonet
  if(flavornet == TRUE) {
    data$Flavornet = webchem::fn_percept(data$CAS_retrieved)
  }

  return(data)
}


#' Extract classyfire information
#'
#' @param data Data includes at least InChIKey which is used for retrieval
#'
#' @return A data.frame
#' @export
#'
#' @import classyfireR
#' @import purrr
extract_classyfire <- function(data) {
    # extract classification from classyfireR
    classyfire <- data$InChIKey %>%
      unique() %>% # remove duplicates
      purrr::map(classyfireR::get_classification) %>%
      purrr::discard(is.null)
    # extract meta data for classification
    classyfire_meta <- classyfire %>%
      purrr::map(classyfireR::meta)%>%
      sapply("[[", 1) %>%
      str_remove("InChIKey=") %>%
      as.data.frame() %>%
      rename(InChIKey = value)

    data <-
      classyfire %>%
      purrr::map(classyfireR::classification) %>%
      lapply(extract_cla) %>%
      do.call("bind_rows", .) %>% # collapse the list into a data.frame
      cbind(classyfire_meta, .) %>% # join with InChIKey
      left_join(data, ., by = "InChIKey") # join with the raw table

    return(data)
}

