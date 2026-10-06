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
  (`"download_api"` for the DATRAS Download API, `"api"` for the DATRAS
  web service, `"php"` or `"file"`) and `endpoint`,

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
#> 1     BITS 2015       1          2020-04-08 2026-09-15 12:38:52    api
#> 2     BITS 2015       4          2026-03-17 2026-09-15 12:38:52    api
#> 3     BITS 2016       1          2024-08-09 2026-09-15 12:39:08    api
#> 4     BITS 2016       4          2024-08-14 2026-09-15 12:39:08    api
#> 5     BITS 2017       1          2024-08-14 2026-09-15 12:39:27    api
#> 6     BITS 2017       4          2024-08-15 2026-09-15 12:39:27    api
#> 7     BITS 2018       1          2021-04-28 2026-09-15 12:39:46    api
#> 8     BITS 2018       4          2026-03-17 2026-09-15 12:39:46    api
#> 9     BITS 2019       1          2024-08-15 2026-09-15 12:40:04    api
#> 10    BITS 2019       4          2022-04-27 2026-09-15 12:40:04    api
#> 11    BITS 2020       1          2022-04-07 2026-09-15 12:40:20    api
#> 12    BITS 2020       4          2024-07-12 2026-09-15 12:40:20    api
#> 13     BTS 2015       1          2020-05-25 2026-09-15 12:35:56    api
#> 14     BTS 2015       3          2022-04-11 2026-09-15 12:35:56    api
#> 15     BTS 2016       1          2020-05-25 2026-09-15 12:36:17    api
#> 16     BTS 2016       3          2022-04-11 2026-09-15 12:36:17    api
#> 17     BTS 2017       1          2020-05-25 2026-09-15 12:36:40    api
#> 18     BTS 2017       3          2022-04-11 2026-09-15 12:36:40    api
#> 19     BTS 2018       1          2020-05-25 2026-09-15 12:37:01    api
#> 20     BTS 2018       3          2021-12-09 2026-09-15 12:37:01    api
#> 21     BTS 2019       1          2020-05-25 2026-09-15 12:37:23    api
#> 22     BTS 2019       3          2021-12-09 2026-09-15 12:37:23    api
#> 23     BTS 2020       1          2021-03-04 2026-09-15 12:37:48    api
#> 24     BTS 2020       3          2021-12-09 2026-09-15 12:37:48    api
#> 25   EVHOE 2015       4          2016-04-16 2026-09-15 12:38:08    api
#> 26   EVHOE 2016       4          2018-05-07 2026-09-15 12:38:16    api
#> 27   EVHOE 2017       4          2018-04-23 2026-09-15 12:38:24    api
#> 28   EVHOE 2018       4          2019-03-05 2026-09-15 12:38:28    api
#> 29   EVHOE 2019       4          2020-02-19 2026-09-15 12:38:37    api
#> 30   EVHOE 2020       4          2021-02-22 2026-09-15 12:38:44    api
#> 31 NS-IBTS 2015       1          2026-06-25 2026-09-15 12:31:57    api
#> 32 NS-IBTS 2015       2          2019-03-07 2026-09-15 12:31:57    api
#> 33 NS-IBTS 2015       3          2017-03-16 2026-09-15 12:31:57    api
#> 34 NS-IBTS 2016       1          2026-06-25 2026-09-15 12:32:33    api
#> 35 NS-IBTS 2016       3          2023-03-22 2026-09-15 12:32:33    api
#> 36 NS-IBTS 2017       1          2026-06-25 2026-09-15 12:33:13    api
#> 37 NS-IBTS 2017       3          2021-10-29 2026-09-15 12:33:13    api
#> 38 NS-IBTS 2018       1          2026-06-25 2026-09-15 12:33:50    api
#> 39 NS-IBTS 2018       3          2022-01-25 2026-09-15 12:33:50    api
#> 40 NS-IBTS 2019       1          2026-06-25 2026-09-15 12:34:31    api
#> 41 NS-IBTS 2019       3          2022-01-25 2026-09-15 12:34:31    api
#> 42 NS-IBTS 2020       1          2026-06-25 2026-09-15 12:35:10    api
#> 43 NS-IBTS 2020       3          2022-04-08 2026-09-15 12:35:10    api
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
#> 15 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 16 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 17 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 18 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 19 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 20 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 21 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 22 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 23 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 24 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 25 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 26 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 27 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 28 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 29 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 30 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 31 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 32 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 33 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 34 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 35 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 36 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 37 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 38 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 39 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 40 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 41 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 42 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#> 43 https://datras.ices.dk/WebServices/DATRASWebService.asmx/
#>                        file
#> 1        BITS/BITS_2015.zip
#> 2        BITS/BITS_2015.zip
#> 3        BITS/BITS_2016.zip
#> 4        BITS/BITS_2016.zip
#> 5        BITS/BITS_2017.zip
#> 6        BITS/BITS_2017.zip
#> 7        BITS/BITS_2018.zip
#> 8        BITS/BITS_2018.zip
#> 9        BITS/BITS_2019.zip
#> 10       BITS/BITS_2019.zip
#> 11       BITS/BITS_2020.zip
#> 12       BITS/BITS_2020.zip
#> 13         BTS/BTS_2015.zip
#> 14         BTS/BTS_2015.zip
#> 15         BTS/BTS_2016.zip
#> 16         BTS/BTS_2016.zip
#> 17         BTS/BTS_2017.zip
#> 18         BTS/BTS_2017.zip
#> 19         BTS/BTS_2018.zip
#> 20         BTS/BTS_2018.zip
#> 21         BTS/BTS_2019.zip
#> 22         BTS/BTS_2019.zip
#> 23         BTS/BTS_2020.zip
#> 24         BTS/BTS_2020.zip
#> 25     EVHOE/EVHOE_2015.zip
#> 26     EVHOE/EVHOE_2016.zip
#> 27     EVHOE/EVHOE_2017.zip
#> 28     EVHOE/EVHOE_2018.zip
#> 29     EVHOE/EVHOE_2019.zip
#> 30     EVHOE/EVHOE_2020.zip
#> 31 NS-IBTS/NS-IBTS_2015.zip
#> 32 NS-IBTS/NS-IBTS_2015.zip
#> 33 NS-IBTS/NS-IBTS_2015.zip
#> 34 NS-IBTS/NS-IBTS_2016.zip
#> 35 NS-IBTS/NS-IBTS_2016.zip
#> 36 NS-IBTS/NS-IBTS_2017.zip
#> 37 NS-IBTS/NS-IBTS_2017.zip
#> 38 NS-IBTS/NS-IBTS_2018.zip
#> 39 NS-IBTS/NS-IBTS_2018.zip
#> 40 NS-IBTS/NS-IBTS_2019.zip
#> 41 NS-IBTS/NS-IBTS_2019.zip
#> 42 NS-IBTS/NS-IBTS_2020.zip
#> 43 NS-IBTS/NS-IBTS_2020.zip
#>                                                        payload_hash
#> 1  5b2d9f312bfcfe9ff78e06015b794f43f15a0972d29b2401ca9f705168261adb
#> 2  5b2d9f312bfcfe9ff78e06015b794f43f15a0972d29b2401ca9f705168261adb
#> 3  9f7a2732d342d0d28eca9d0247da5851c0a27a3bb9fb980792ce2da838807455
#> 4  9f7a2732d342d0d28eca9d0247da5851c0a27a3bb9fb980792ce2da838807455
#> 5  0ab6dd0063d629b7e41ff25b7e7332a1d74fbcfa0330f66fc917717585cd049e
#> 6  0ab6dd0063d629b7e41ff25b7e7332a1d74fbcfa0330f66fc917717585cd049e
#> 7  75bc8f5cde8f38b83d30bcaaf12cf18f279b548bfcf8186d998260842a314ec5
#> 8  75bc8f5cde8f38b83d30bcaaf12cf18f279b548bfcf8186d998260842a314ec5
#> 9  2010ecec2e43d98d403d48c4ed994acaee09c770050696032c38d29f570b96a9
#> 10 2010ecec2e43d98d403d48c4ed994acaee09c770050696032c38d29f570b96a9
#> 11 fde19598c498f90d43f6073b35c6342e07b03f08640564700d58f57185df0ef3
#> 12 fde19598c498f90d43f6073b35c6342e07b03f08640564700d58f57185df0ef3
#> 13 b47815092e8365d7bf03d1e795a4e0a254f1882434654c2ea2316dd7965c9a63
#> 14 b47815092e8365d7bf03d1e795a4e0a254f1882434654c2ea2316dd7965c9a63
#> 15 b09b195c376b95129caae56dec84866bc604e982b43b2935235570d75869c071
#> 16 b09b195c376b95129caae56dec84866bc604e982b43b2935235570d75869c071
#> 17 f5c4aa0441bcf8a78df5f0885614d05ca947075f14955d8bebfd6db8cbcf9295
#> 18 f5c4aa0441bcf8a78df5f0885614d05ca947075f14955d8bebfd6db8cbcf9295
#> 19 31ec6272ee821bc23e91ef57c6723880947b516d48a6a7af3e9f523035d68da2
#> 20 31ec6272ee821bc23e91ef57c6723880947b516d48a6a7af3e9f523035d68da2
#> 21 a11aa4466e2580f5c73c16ba9fc912502b9b343b497c8a3d76acd07d8a2504ca
#> 22 a11aa4466e2580f5c73c16ba9fc912502b9b343b497c8a3d76acd07d8a2504ca
#> 23 d3e01a50f8d1fc6c95203e8f5c40df26c77544bc58bad929063dc81ecd099fe3
#> 24 d3e01a50f8d1fc6c95203e8f5c40df26c77544bc58bad929063dc81ecd099fe3
#> 25 ec28f07b1892fad91f78e5d1613f10c2b7eff4d690cb28f3cc8b11023c09645a
#> 26 69fa765fc936fd6045fc702cc857e8c1ccd2b11f49fe640c68c0a53d5afc7641
#> 27 b3786e0dcc78f16b3ddd73f8cc7fd3f23443627727dce86abc0692a0c0286272
#> 28 90893b25b934ab9615c6c718ebd10fc858d01721fb64b034d195e2d21217b8f0
#> 29 aa5762202e83310c3f4337fe6f7e5ecf579481f38afede525e7ffc25bf16a9ae
#> 30 825a2fa07859acbed0d19e1397ecd77bedb59917b3175af74fff3cdeab05523d
#> 31 0e9c271181336b07412e953101a294f648c465330835a56827ddb9ad42083291
#> 32 0e9c271181336b07412e953101a294f648c465330835a56827ddb9ad42083291
#> 33 0e9c271181336b07412e953101a294f648c465330835a56827ddb9ad42083291
#> 34 35b06b5cfb9fc0ebd9877a2d7bdb65cc346e6a38e4d85a8fb690b0ed6c30c9a2
#> 35 35b06b5cfb9fc0ebd9877a2d7bdb65cc346e6a38e4d85a8fb690b0ed6c30c9a2
#> 36 5227a537756b5bc5ea5b05e00025218826231f02c7f43418a312abdb4f762679
#> 37 5227a537756b5bc5ea5b05e00025218826231f02c7f43418a312abdb4f762679
#> 38 2f4562a067f908bc5e50ef17926e74b9bc465c71fe0232acb0d2ac5e4a5bb61b
#> 39 2f4562a067f908bc5e50ef17926e74b9bc465c71fe0232acb0d2ac5e4a5bb61b
#> 40 f9106bdbe04c744a03c2d158e46bd01a1043eb808320cfdae76bb5a7eb638fa1
#> 41 f9106bdbe04c744a03c2d158e46bd01a1043eb808320cfdae76bb5a7eb638fa1
#> 42 f448f5f4d9793a66c13b43f318c19639a2f26bff0a8ac4cc900e067a9336f286
#> 43 f448f5f4d9793a66c13b43f318c19639a2f26bff0a8ac4cc900e067a9336f286
#>                                                            zip_hash   algo
#> 1  8a29ba5fec5e56911950e8c19a5f0c62476f2052c97dcf4e8b09bd447ce0e760 sha256
#> 2  8a29ba5fec5e56911950e8c19a5f0c62476f2052c97dcf4e8b09bd447ce0e760 sha256
#> 3  8375f58d67e80b07ab20d44c2332d30a35c45a1a46bb4fa981fbc1d4aeb2f539 sha256
#> 4  8375f58d67e80b07ab20d44c2332d30a35c45a1a46bb4fa981fbc1d4aeb2f539 sha256
#> 5  f4e514854d5a4388ba1b41618985af403d89c6b557a1d88bedb81e7489a36c68 sha256
#> 6  f4e514854d5a4388ba1b41618985af403d89c6b557a1d88bedb81e7489a36c68 sha256
#> 7  f3f88f24179945a508eeda75a77c865f5b930ccdfa3cd61dbcb5dd4a0ec49f3c sha256
#> 8  f3f88f24179945a508eeda75a77c865f5b930ccdfa3cd61dbcb5dd4a0ec49f3c sha256
#> 9  ebee98b5c1e408ca861ee8a498a924d1f6f43fef58924256d84d3855a024c6e0 sha256
#> 10 ebee98b5c1e408ca861ee8a498a924d1f6f43fef58924256d84d3855a024c6e0 sha256
#> 11 82a5bfae154142a3d4a53865740e8305bd2b6c04f097ee25a318153d79c2e78a sha256
#> 12 82a5bfae154142a3d4a53865740e8305bd2b6c04f097ee25a318153d79c2e78a sha256
#> 13 a36bf14dce3f889dda1d69efd4bb934bbd6e736180bdd503159eb7793a67d403 sha256
#> 14 a36bf14dce3f889dda1d69efd4bb934bbd6e736180bdd503159eb7793a67d403 sha256
#> 15 d3b55f66997bdf39164751b7bbabfe42b27ff50cd2f48d375517ba8720cd43aa sha256
#> 16 d3b55f66997bdf39164751b7bbabfe42b27ff50cd2f48d375517ba8720cd43aa sha256
#> 17 121efcf8dfc710d7a43c339b98bd0c8b608836772f06459f526781b78e6753fd sha256
#> 18 121efcf8dfc710d7a43c339b98bd0c8b608836772f06459f526781b78e6753fd sha256
#> 19 e25f0e0ff61a03409ff603dbcbe4f08745c506c74b91cf5c57d3787ad1602a6c sha256
#> 20 e25f0e0ff61a03409ff603dbcbe4f08745c506c74b91cf5c57d3787ad1602a6c sha256
#> 21 05375855ca059e90ba066df6fb307bd11ddf87b5fdebb58da03e4dc95409c91d sha256
#> 22 05375855ca059e90ba066df6fb307bd11ddf87b5fdebb58da03e4dc95409c91d sha256
#> 23 17d797ea80d2f283fae919dd12e7b8be16ff04916c07ac2ad709083cdf35231d sha256
#> 24 17d797ea80d2f283fae919dd12e7b8be16ff04916c07ac2ad709083cdf35231d sha256
#> 25 78a457bbe15f654a367d031ca113a9ef09a28a89680763b16a1a0690bea493d6 sha256
#> 26 7cb7aa706bd1aa3d2d871be6fa8e696c3dad2f3dbf6cf8baca36c8823b26d4ea sha256
#> 27 94403dde6b3f32d19e5189762d7fe28ead7d1c3fae6bc1278ee766d963e0b8be sha256
#> 28 2bb4a3e6480f59a891934cf7ef2604b021af261c0ca6b6dbdb2f3b680144f247 sha256
#> 29 fe0f7356c8afb4fead7e7d615399244a2dd09f8bc570c6eaad6c1b0d8a332930 sha256
#> 30 0f88eab42ac063e15d428e56b79196d92074568b796872a67cec35beea202246 sha256
#> 31 040d7ac37a42748f02a76a1b14eacc466c7aa11d619712d0e424a35215c76d52 sha256
#> 32 040d7ac37a42748f02a76a1b14eacc466c7aa11d619712d0e424a35215c76d52 sha256
#> 33 040d7ac37a42748f02a76a1b14eacc466c7aa11d619712d0e424a35215c76d52 sha256
#> 34 0c0be3343d2d046f0b059fecca357a5153bf1c5d738aec48d5b83b371b74523a sha256
#> 35 0c0be3343d2d046f0b059fecca357a5153bf1c5d738aec48d5b83b371b74523a sha256
#> 36 dba7b67b41f2cb5bcaed4db710d4c628fdba6b6bb1c5187d589e73628f199618 sha256
#> 37 dba7b67b41f2cb5bcaed4db710d4c628fdba6b6bb1c5187d589e73628f199618 sha256
#> 38 32b67ea0542f68b75777808758884a2fe2d2f55478b3e6aaaaf37fdc37557bfc sha256
#> 39 32b67ea0542f68b75777808758884a2fe2d2f55478b3e6aaaaf37fdc37557bfc sha256
#> 40 f1c35327a8d31e6c5b1a16974c8c8aa9c7c48d6b92adcf78d7bd48746895c8b2 sha256
#> 41 f1c35327a8d31e6c5b1a16974c8c8aa9c7c48d6b92adcf78d7bd48746895c8b2 sha256
#> 42 2edd36f011fe06288e1eb1cb397d9b3b7f1516be69758eb416462fdc7306db80 sha256
#> 43 2edd36f011fe06288e1eb1cb397d9b3b7f1516be69758eb416462fdc7306db80 sha256
#>                   read datrasextra datras icesdatras r_version
#> 1  2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 2  2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 3  2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 4  2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 5  2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 6  2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 7  2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 8  2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 9  2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 10 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 11 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 12 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 13 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 14 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 15 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 16 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 17 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 18 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 19 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 20 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 21 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 22 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 23 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 24 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 25 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 26 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 27 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 28 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 29 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 30 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 31 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 32 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 33 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 34 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 35 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 36 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 37 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 38 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 39 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 40 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 41 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 42 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1
#> 43 2026-09-15 12:42:34       0.4.2  1.1.2      1.5.3     4.6.1

if (FALSE) { # \dontrun{
## Format an ICES data citation
e <- extraction(x)
sprintf("ICES Database of Trawl Surveys (DATRAS), Extraction %s of %s. ICES, Copenhagen",
        format(max(e$extracted), "%d %B %Y"),
        paste(unique(e$survey), collapse = ", "))
} # }
```
