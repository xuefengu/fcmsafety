
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fcmsafety

<!-- badges: start -->
<!-- badges: end -->

The goal of fcmsafety is to assign toxicity levels for compounds from
food contact materials. It takes into account the toxicity data from: 1.
Substances of Very High Concern (SVHC) from ECHA
(<https://echa.europa.eu/candidate-list-table>); 2. Carcinogenic,
Mutagenic, and Reprotoxic (CMR) from the Classification, Labelling, and
Packaging (CLP) regulation
(<https://echa.europa.eu/information-on-chemicals/annex-vi-to-clp>) ; 3.
Carcinogenic substances from IARC
(<https://monographs.iarc.who.int/list-of-classifications>); 4.
Endocrine Disrupting Chemicals (EDC) from The International Panel on
Chemical Pollution (IPCP) commissioned by UN Environment
(<https://www.unep.org/explore-topics/chemicals-waste/what-we-do/emerging-issues/scientific-knowledge-endocrine-disrupting>);
5. Specific Migration Limit (SML) from EU 10/2011 regulation
(<https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:02011R0010-20200923&qid=1636402301680&from=en>)
6. Specific Migration Limit (SML) from China GB 9685 regulation
(Provided by IQTC).

The toxicity level assignment follows the rules listed in the
inst/toxicity\_levels.png (don’t know why it is not rendered in this
readme file)

Please bear in mind that the toxicity level assignment here is on the
basis of individual compounds, whilst substances listed in the
aforementioned databases could be groups of compounds. These groups of
substances will not be considered as they not are specific in terms of
chemical structures and no “InChIKey” can be retrieved from Pubchem,
which is used for matching. For example, nonylphenols are a family of
closely related organic compounds composed of phenol bearing a 9
carbon-tail, and they could be overlooked unless any database has
numerated some specific structures in their lists.

In addition, this package provides simple wrappers of some functions
from the **webchem** and **classyfireR** package to ease CID, InChIKey,
SMILES, Formula, ExactMass, CAS, flavonet, and classifire information
retrieval.

## Release notes (2021.12.03 Version 0.1.4)

### Enhancement

1.  Add a function to assign meta data.

## Installation

You can install the development version of fcmsafety from
[GitHub](https://github.com/) with the code listed below. If you have
installed the package before the date listed in *Release Notes*, please
re-install it to ensure to have the latest version.

``` r
install.packages("devtools")
devtools::install_github("QizhiSu/fcmsafety")
```

If you fail to install it due to the classyfireR issue, please install
classyfireR first.

``` r
devtools::install_github('aberHRML/classyfireR')
```

## How to use?

Below walks you through the way to go step by step.

If you do not have the “rio” and “dplyr” package installed, please
install it first. If you do, just skip this step.

``` r
install.packages("rio")
install.packages("dplyr")
```

### Load required packages

``` r
library(fcmsafety)
library(dplyr)
```

### Update and Load databases

You have to first update all the databases and load them into the global
environment.

``` r
# You don't have to update all the databases as we have prepared them (updated 
# on 2021/11/11) and can be used directly. In case you want to have the latest 
# databases (if you find any update of these databases after 2021/11/11), please
# run update_databases(), it might take long time as retrieving meta data for 
# all these databases is time-consuming.
update_databases()

# If you have updated the databases yourself, please run:
load_databases(use_default = FALSE)
# Otherwise
load_databases()
```

### Process your data

1.  Read in your data

Please name your file in English but not Chinese (Chinese letters are
not well supported in some functions). There should be at least one
column in your data containing either chemical names in English, CAS
number, or InChIKey. The program will use any or all of these columns to
retrieve meta data from Pubchem. A good chemical name is always
favorable.

``` r
# Please enter the path of your data, e.g., "D:/my data/mydata.xlsx".
data <- rio::import("D:/my data/mydata.xlsx")
```

2.  Extract cid and meta data

Please specify which column contains CAS number by the “cas\_col”
argument, InChIKey by “inchikey\_col”, and chemical name by the
“name\_col” argument. You can also specify all these arguments. In this
case, it will first use InChIKey, and then CAS and Name. To get
flavornet information, cas = TRUE is required. Depends on the size of
your data, it might take long time.

``` r
# No CAS
data <- data %>% extract_cid(name_col = 1) %>% extract_meta()
# With CAS
data <- data %>% extract_cid(name_col = 1) %>% extract_meta(cas = TRUE)
# With flavornet
data <- data %>% extract_cid(name_col = 1) %>% extract_meta(cas = TRUE, flavonet = TRUE)
```

If you have some compounds that are not present in Pubchem, for example
many oligomers found in food contact materials. there will be no SMILES
retrieved for these compounds using `extract_meta`. In this case, you
can use `assign_meta` function. However, a *.txt file containing Name
and SMILES of these compounds is required. There are two options to
prepare this text file. One is to prepare it manually, the column names
must be Name and SMILES, respectively (case-insensitive). Another one is
to prepare *.MOL files (case-insensitive) of these molecules and extract
SMILES using `combine_mol2sdf()` and `extract_structure()` functions
from the `mspcompiler` package
[mspcompiler](https://github.com/QizhiSu/mspcompiler). Note that the
name in your *.txt file or *.MOL files have to be consistent with the
one you have in your data as Name is used for matching. Assuming you
have all your \*MOL files in the “D:/my data” folder, then you can
follow these steps:

``` r
# If you have not install the mspcompiler package, please install it following
# the instruction in its Github homepage https://github.com/QizhiSu/mspcompiler.
# Once you have it installed
library(mspcompiler)

# This function combines all *.MOL files in yhe providing folder into a single 
# *.sdf file from which will be used to extract SMILES. 
combine_mol2sdf(input = "D:/my data", 
                output = "D:/my data/mydata.sdf",
                use_filename = TRUE)
# The input here is the output from the last command and it will generate a *.txt 
# file containing Name and SMILES.  
extract_structure(input = "D:/my data/mydata.sdf",
                  output = "D:/my data/mydata.txt")
data <- data %>% assign_meta(meta_file = "D:/my data/mydata.txt")
```

3.  Extract classyfire information

After extracting meta data from Pubchem by extract\_meta(), which means
the data will has a column named InChIkey, then we can get the chemical
structure classification done by classyfire.

``` r
data <- data %>% extract_classyfire()
```

4.  Export file for Toxtree

For compounds that do not present in any of the databases we consider
here, we can use Toxtree (<http://toxtree.sourceforge.net/>) to predict
its Cramer rules level which will be used for assigning toxicity level
in the following step. We now can export a file that can be used by
Toxtree for batch processing.

``` r
# This code will generate a file name "for_toxtree.csv"
export4toxtree(data, cas_col = 1, name_col = 2)
# Of course, you can also specify the path and name of the output file
export4toxtree(data, cas_col = 1, name_col = 2, output = "D:/data/mydata_for_toxtree.csv")
```

5.  Toxtree batch processing

    <figure>
    <img src="inst/toxtree_batch_processing1.png" width="500" alt="batch processing 1" /><figcaption aria-hidden="true">batch processing 1</figcaption>
    </figure>

    <figure>
    <img src="inst/toxtree_batch_processing2.png" width="500" alt="batch processing 2" /><figcaption aria-hidden="true">batch processing 2</figcaption>
    </figure>

    <figure>
    <img src="inst/toxtree_batch_processing3.png" width="500" alt="batch processing 3" /><figcaption aria-hidden="true">batch processing 3</figcaption>
    </figure>

Normally, this step is quite fast, but we noticed that polyethylene
glycols might take quite long time.

6.  Assign toxicity

This step requires the results from Toxtree (assuming you have the
result in “D:/data/mydata\_toxtree\_results.csv”).

``` r
data_complete <- data %>% 
  assign_toxicity(toxtree_result = "D:/data/mydata_toxtree_results.csv")
```

7.  Export results

``` r
rio::export(data_complete, "D:/data/mydata_result.xlsx")
```
