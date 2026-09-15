# Extraction record of a `datras_raw` object

Return the table describing where the data in a `datras_raw` /
`DATRASraw` object came from, when it was extracted from ICES DATRAS,
and which software produced it.

## Usage

``` r
extraction(x)
```

## Arguments

- x:

  A `datras_raw` object.

## Value

A data frame with one row per survey, year and quarter. A zero-row data
frame with the same columns is returned when no information is
available.

## Details

The record has one row per source unit, that is per survey, year and
quarter. This is the granularity at which ICES calculates and revises
the database, and the granularity at which survey-year files can be
downloaded on different dates.

The most important column is `date_of_calculation`, taken from the
DATRAS field `DateofCalculation`. It records when ICES last recalculated
that block of records and is therefore the only reliable indicator that
data have been revised upstream. Because it is supplied by ICES rather
than generated locally, it can be compared between two extractions made
at any time. The field is not populated for every survey-year-quarter,
most often for historical data; where it is missing, an upstream
revision can only be detected through the file checksum.

The remaining columns fall into three groups:

- identification: `survey`, `year`, `quarter`, `file`,

- extraction: `extracted` (when the data were retrieved), `source`
  (`"api"`, `"php"` or `"file"`) and `endpoint`,

- verification and software: `payload_hash`, `zip_hash`, `algo`, `read`,
  `datrasextra`, `datras`, `icesdatras` and `r_version`.

When an object was created before this information was recorded, or read
from an archive without a manifest, the identification columns and
`date_of_calculation` are still reconstructed from the data themselves
and the remaining columns are `NA`.

`survey` and `extracted` are the two fields required by the ICES
citation format, so the record can be formatted directly into a data
citation.

## See also

[`write_manifest()`](https://tokami.github.io/DATRASextra/reference/write_manifest.md),
[`read_manifest()`](https://tokami.github.io/DATRASextra/reference/read_manifest.md),
[`verify_extraction()`](https://tokami.github.io/DATRASextra/reference/verify_extraction.md),
[`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md),
[`download_datras()`](https://tokami.github.io/DATRASextra/reference/download_datras.md).
For the age of the lookup tables bundled with the package rather than of
the survey data, see
[`reference_tables()`](https://tokami.github.io/DATRASextra/reference/reference_tables.md).

## Examples

``` r
## Reconstructed from the data even for objects created before this
## information was recorded
extraction(mini)
#>     survey year quarter date_of_calculation           extracted source
#> 1     BITS 2022       1          2024-08-14 2026-09-15 10:47:57    api
#> 2     BITS 2022       4          2024-08-06 2026-09-15 10:47:57    api
#> 3     BITS 2023       1          2025-01-18 2026-09-15 10:48:23    api
#> 4     BITS 2023       4          2024-03-26 2026-09-15 10:48:23    api
#> 5      BTS 2022       1          2023-12-07 2026-09-15 10:47:06    api
#> 6      BTS 2022       3          2023-03-22 2026-09-15 10:47:06    api
#> 7      BTS 2023       1          2024-03-01 2026-09-15 10:47:21    api
#> 8      BTS 2023       3          2025-02-12 2026-09-15 10:47:21    api
#> 9    EVHOE 2022       4          2023-04-25 2026-09-15 10:47:42    api
#> 10   EVHOE 2023       4          2024-05-07 2026-09-15 10:47:48    api
#> 11 NS-IBTS 2022       1          2026-06-25 2026-09-15 10:45:54    api
#> 12 NS-IBTS 2022       3          2025-04-04 2026-09-15 10:45:54    api
#> 13 NS-IBTS 2023       1          2026-06-25 2026-09-15 10:46:33    api
#> 14 NS-IBTS 2023       3          2024-04-09 2026-09-15 10:46:33    api
#>                                                     endpoint
#> 1  https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 2  https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 3  https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 4  https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 5  https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 6  https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 7  https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 8  https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 9  https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 10 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 11 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 12 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 13 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 14 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#>                        file
#> 1        BITS/BITS_2022.zip
#> 2        BITS/BITS_2022.zip
#> 3        BITS/BITS_2023.zip
#> 4        BITS/BITS_2023.zip
#> 5          BTS/BTS_2022.zip
#> 6          BTS/BTS_2022.zip
#> 7          BTS/BTS_2023.zip
#> 8          BTS/BTS_2023.zip
#> 9      EVHOE/EVHOE_2022.zip
#> 10     EVHOE/EVHOE_2023.zip
#> 11 NS-IBTS/NS-IBTS_2022.zip
#> 12 NS-IBTS/NS-IBTS_2022.zip
#> 13 NS-IBTS/NS-IBTS_2023.zip
#> 14 NS-IBTS/NS-IBTS_2023.zip
#>                                                        payload_hash
#> 1  4efd4357def9266b75ec5d959fba0ac984bd2a9a8e0fb96ff1936ce5f302b08a
#> 2  4efd4357def9266b75ec5d959fba0ac984bd2a9a8e0fb96ff1936ce5f302b08a
#> 3  78a7660504dea81e8ea30e5dfbf01d589fffc1350fd2ce5c645f940dd2721300
#> 4  78a7660504dea81e8ea30e5dfbf01d589fffc1350fd2ce5c645f940dd2721300
#> 5  a30f0b604b5a9669d78e5816c3d5414b0e3dd89082fe028a758f44bdf0c309f5
#> 6  a30f0b604b5a9669d78e5816c3d5414b0e3dd89082fe028a758f44bdf0c309f5
#> 7  9d151017cd9266cb127173365140e30f6f05e4e143bbfefd7cb6658fc4f5f79a
#> 8  9d151017cd9266cb127173365140e30f6f05e4e143bbfefd7cb6658fc4f5f79a
#> 9  403b12a4be6969ceae0457073761d0d1d26d16c96c3e8fe0990dcb98efb9a5b4
#> 10 70b34db2ee9f6867fc60b8efda7b88b545c9c63237ca056a5d03f8d77136adab
#> 11 a6f2e557da478d7dbee22eda53bcb3145aad0bc6a0e2b65458311a48007b99c3
#> 12 a6f2e557da478d7dbee22eda53bcb3145aad0bc6a0e2b65458311a48007b99c3
#> 13 37fcc5d68912565fc7423d0a6d9dbf8352a80585990f1ea27f9f990696ccff99
#> 14 37fcc5d68912565fc7423d0a6d9dbf8352a80585990f1ea27f9f990696ccff99
#>                                                            zip_hash   algo
#> 1  3b2c59ccc4feb883b6fd3c272c491bc73fe64df15bb7b44f65d883ad5f9e19b8 sha256
#> 2  3b2c59ccc4feb883b6fd3c272c491bc73fe64df15bb7b44f65d883ad5f9e19b8 sha256
#> 3  0b1d6c960362970434d15b85ebc06a202d2cf83d1ff168b2a015387860d62971 sha256
#> 4  0b1d6c960362970434d15b85ebc06a202d2cf83d1ff168b2a015387860d62971 sha256
#> 5  dcd25fd620d24d2b279c089395d6321a07fd1e1ea8e0fc1d5df86bc9c62b212a sha256
#> 6  dcd25fd620d24d2b279c089395d6321a07fd1e1ea8e0fc1d5df86bc9c62b212a sha256
#> 7  6727067bda13f0c8638de54efa01675d2a061c4662d8fd40e069586676ddd802 sha256
#> 8  6727067bda13f0c8638de54efa01675d2a061c4662d8fd40e069586676ddd802 sha256
#> 9  9d8255156889b30aad40bf7e502ce778b9fdd4bfc1f4c00e9692202e2b0fed6b sha256
#> 10 523e5c80680c31fcd72cc52b27022150c2e30a7248d0ea56a6b641637a25eebc sha256
#> 11 92295d06b54c09edba2ad0e74424dc8afd555d1decbe573876bc6f3ea0f5a5dc sha256
#> 12 92295d06b54c09edba2ad0e74424dc8afd555d1decbe573876bc6f3ea0f5a5dc sha256
#> 13 495622ffe675686040c6ed6ded6a5e55e54c4612c340130122017e97fd070b80 sha256
#> 14 495622ffe675686040c6ed6ded6a5e55e54c4612c340130122017e97fd070b80 sha256
#>                   read datrasextra datras icesdatras r_version
#> 1  2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 2  2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 3  2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 4  2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 5  2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 6  2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 7  2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 8  2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 9  2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 10 2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 11 2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 12 2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 13 2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1
#> 14 2026-09-15 10:49:22       0.4.2  1.1.2      1.5.3     4.6.1

if (FALSE) { # \dontrun{
## Format an ICES data citation
e <- extraction(x)
sprintf("ICES Database of Trawl Surveys (DATRAS), Extraction %s of %s. ICES, Copenhagen",
        format(max(e$extracted), "%d %B %Y"),
        paste(unique(e$survey), collapse = ", "))
} # }
```
