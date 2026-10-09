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
#>     survey year quarter date_of_calculation           extracted       source
#> 1     BITS 2015       1          2020-04-08 2026-10-09 13:12:59 download_api
#> 2     BITS 2015       4          2022-04-22 2026-10-09 13:12:59 download_api
#> 3     BITS 2016       1          2024-08-09 2026-10-09 13:12:59 download_api
#> 4     BITS 2016       4          2024-08-14 2026-10-09 13:12:59 download_api
#> 5     BITS 2017       1          2024-08-14 2026-10-09 13:12:59 download_api
#> 6     BITS 2017       4          2024-08-15 2026-10-09 13:12:59 download_api
#> 7     BITS 2018       1          2021-04-28 2026-10-09 13:12:59 download_api
#> 8     BITS 2018       4          2024-08-15 2026-10-09 13:12:59 download_api
#> 9     BITS 2019       1          2024-08-15 2026-10-09 13:12:59 download_api
#> 10    BITS 2019       4          2022-04-27 2026-10-09 13:12:59 download_api
#> 11    BITS 2020       1          2022-04-07 2026-10-09 13:12:59 download_api
#> 12    BITS 2020       4          2024-07-12 2026-10-09 13:12:59 download_api
#> 13     BTS 2015       1          2020-05-25 2026-10-09 13:12:37 download_api
#> 14     BTS 2015       3          2022-04-11 2026-10-09 13:12:37 download_api
#> 15     BTS 2016       1          2020-05-25 2026-10-09 13:12:37 download_api
#> 16     BTS 2016       3          2022-04-11 2026-10-09 13:12:37 download_api
#> 17     BTS 2017       1          2020-05-25 2026-10-09 13:12:37 download_api
#> 18     BTS 2017       3          2022-04-11 2026-10-09 13:12:37 download_api
#> 19     BTS 2018       1          2020-05-25 2026-10-09 13:12:37 download_api
#> 20     BTS 2018       3          2021-12-09 2026-10-09 13:12:37 download_api
#> 21     BTS 2019       1          2020-05-25 2026-10-09 13:12:37 download_api
#> 22     BTS 2019       3          2021-12-09 2026-10-09 13:12:37 download_api
#> 23     BTS 2020       1          2021-03-04 2026-10-09 13:12:37 download_api
#> 24     BTS 2020       3          2021-12-09 2026-10-09 13:12:37 download_api
#> 25   EVHOE 2015       4          2016-04-16 2026-10-09 13:12:53 download_api
#> 26   EVHOE 2016       4          2018-05-07 2026-10-09 13:12:53 download_api
#> 27   EVHOE 2017       4          2018-04-23 2026-10-09 13:12:53 download_api
#> 28   EVHOE 2018       4          2019-03-05 2026-10-09 13:12:53 download_api
#> 29   EVHOE 2019       4          2020-02-19 2026-10-09 13:12:53 download_api
#> 30   EVHOE 2020       4          2021-02-22 2026-10-09 13:12:53 download_api
#> 31 NS-IBTS 2015       1          2021-06-07 2026-10-09 13:12:06 download_api
#> 32 NS-IBTS 2015       2          2019-03-07 2026-10-09 13:12:06 download_api
#> 33 NS-IBTS 2015       3          2017-03-16 2026-10-09 13:12:06 download_api
#> 34 NS-IBTS 2016       1          2017-09-14 2026-10-09 13:12:06 download_api
#> 35 NS-IBTS 2016       3          2023-03-22 2026-10-09 13:12:06 download_api
#> 36 NS-IBTS 2017       1          2023-03-22 2026-10-09 13:12:06 download_api
#> 37 NS-IBTS 2017       3          2021-10-29 2026-10-09 13:12:06 download_api
#> 38 NS-IBTS 2018       1          2022-07-12 2026-10-09 13:12:06 download_api
#> 39 NS-IBTS 2018       3          2022-01-25 2026-10-09 13:12:06 download_api
#> 40 NS-IBTS 2019       1          2021-10-04 2026-10-09 13:12:06 download_api
#> 41 NS-IBTS 2019       3          2022-01-25 2026-10-09 13:12:06 download_api
#> 42 NS-IBTS 2020       1          2022-01-25 2026-10-09 13:12:06 download_api
#> 43 NS-IBTS 2020       3          2022-04-08 2026-10-09 13:12:06 download_api
#>                                                                endpoint
#> 1  https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 2  https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 3  https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 4  https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 5  https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 6  https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 7  https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 8  https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 9  https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 10 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 11 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 12 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 13 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 14 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 15 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 16 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 17 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 18 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 19 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 20 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 21 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 22 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 23 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 24 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 25 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 26 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 27 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 28 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 29 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 30 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 31 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 32 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 33 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 34 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 35 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 36 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 37 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 38 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 39 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 40 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 41 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 42 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
#> 43 https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx
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
#> 1  fb94a07bdc97434083d427472c6ac66a47b20c2bff452ee099cb546e49b8a3b2
#> 2  fb94a07bdc97434083d427472c6ac66a47b20c2bff452ee099cb546e49b8a3b2
#> 3  5ca226b9ab3d5003887f55552a57522ad7abe6af7372b39341976d88f8defa89
#> 4  5ca226b9ab3d5003887f55552a57522ad7abe6af7372b39341976d88f8defa89
#> 5  c86dfebf1e90af79451ac3002681e0e029e1c766df8881ae3e15ac722eb6a944
#> 6  c86dfebf1e90af79451ac3002681e0e029e1c766df8881ae3e15ac722eb6a944
#> 7  e66766d33529bca94bbcf5ea45551c8378d7bc2cbf383a8055f2933b799b0ade
#> 8  e66766d33529bca94bbcf5ea45551c8378d7bc2cbf383a8055f2933b799b0ade
#> 9  0cdb8a99d593570cf37b44b6fdead9e2173b842fd1194ee5be2e0f2b114f028f
#> 10 0cdb8a99d593570cf37b44b6fdead9e2173b842fd1194ee5be2e0f2b114f028f
#> 11 865649d39042e801fa1a72003410a71e3f493823d6fb4137e0c5b1ffefd498aa
#> 12 865649d39042e801fa1a72003410a71e3f493823d6fb4137e0c5b1ffefd498aa
#> 13 7547fa8592b47a78e3cb83bef299d3b701169012c1cecb0e2d255a23ca768d80
#> 14 7547fa8592b47a78e3cb83bef299d3b701169012c1cecb0e2d255a23ca768d80
#> 15 566daec17d6d56d13a147d8c2b7d0c60c74dd86005b63aadfffe8636f5619460
#> 16 566daec17d6d56d13a147d8c2b7d0c60c74dd86005b63aadfffe8636f5619460
#> 17 704d8b596394be58c4ad281bb4ce0148c087ae8f747ad433e83bc1859dca7635
#> 18 704d8b596394be58c4ad281bb4ce0148c087ae8f747ad433e83bc1859dca7635
#> 19 c7f24011e00a25091cb68d2fcc4c6fdbe12eb6ba5a65bdef725455ca3562d0ba
#> 20 c7f24011e00a25091cb68d2fcc4c6fdbe12eb6ba5a65bdef725455ca3562d0ba
#> 21 ae2a8e39e6089edbab45f8f31eaabee57380b8af2aa3a16396f594556bbff450
#> 22 ae2a8e39e6089edbab45f8f31eaabee57380b8af2aa3a16396f594556bbff450
#> 23 f5329bf79915013edf319e933f0637f03e04ddef7de8c5848cb50634502b7a68
#> 24 f5329bf79915013edf319e933f0637f03e04ddef7de8c5848cb50634502b7a68
#> 25 fc2cd22f4522d27775003d204cf77650f6b1023f13c784c617d267bdd2a45d8e
#> 26 361a71d70ee68b334d2284e24a79289a789ce866e96dce8012dccb9960a32492
#> 27 9c1845f672c064b7a1067eb349380015d7e9f99399eee7eac0a8d279359cb32a
#> 28 e194e149f745fa63ef3cf947d665991bf5749bafd136296ea54dbdfa500d284b
#> 29 b6fda204a74f3151aaa68ca58ca9d65f66bf96585a550e4d54787b3c9d017997
#> 30 c8584f86e482a5163efbf32ea10857d1e4c0267715c86f050943a04345588592
#> 31 adeb358516fd21f4b2a73bcd2c72c9e449c9b3113796ca77421bf518dac6c9c4
#> 32 adeb358516fd21f4b2a73bcd2c72c9e449c9b3113796ca77421bf518dac6c9c4
#> 33 adeb358516fd21f4b2a73bcd2c72c9e449c9b3113796ca77421bf518dac6c9c4
#> 34 36a16e44438d155a8fe8ae147df76722bd3eb7b288e1f7d0d213e8b6078e4f18
#> 35 36a16e44438d155a8fe8ae147df76722bd3eb7b288e1f7d0d213e8b6078e4f18
#> 36 748f1385c91ee668b6f84b34148279843582d4fd18a4bf26497449aa4393b6bc
#> 37 748f1385c91ee668b6f84b34148279843582d4fd18a4bf26497449aa4393b6bc
#> 38 02066b19aaafe69e3ce00d1e9c34d6d9f67fd567f10543b96e6d88c4afb3bbc7
#> 39 02066b19aaafe69e3ce00d1e9c34d6d9f67fd567f10543b96e6d88c4afb3bbc7
#> 40 f016a76dd4d3b2055c6f5e7e4a11da7090df3b74c32976c6a6ee6021d520b4a1
#> 41 f016a76dd4d3b2055c6f5e7e4a11da7090df3b74c32976c6a6ee6021d520b4a1
#> 42 977f16918f1cceff4fcc8f9087433ee7308377fb3478dece0ae554e2ae806e35
#> 43 977f16918f1cceff4fcc8f9087433ee7308377fb3478dece0ae554e2ae806e35
#>                                                            zip_hash   algo
#> 1  a7d7a940cc7b30604dc7c75164507c2aaaeec5aede6c76ccb2de23f80b44340e sha256
#> 2  a7d7a940cc7b30604dc7c75164507c2aaaeec5aede6c76ccb2de23f80b44340e sha256
#> 3  1147725b72f4609fa6e5094441648ba029e6a4c5c433b284e234aa103eb9f81c sha256
#> 4  1147725b72f4609fa6e5094441648ba029e6a4c5c433b284e234aa103eb9f81c sha256
#> 5  b108d575b67c71bc7d2fb3f49843702c32b57fae7dd1ac8dfaf4e4a06108b1ec sha256
#> 6  b108d575b67c71bc7d2fb3f49843702c32b57fae7dd1ac8dfaf4e4a06108b1ec sha256
#> 7  44b379cb38f21079cde67c786a874b96d7ff8f05fd8857e72d5c78bcc0def691 sha256
#> 8  44b379cb38f21079cde67c786a874b96d7ff8f05fd8857e72d5c78bcc0def691 sha256
#> 9  d218536fbb06275a3537b607ceb56d6994f451e9bff717aed3c7280123e17e6b sha256
#> 10 d218536fbb06275a3537b607ceb56d6994f451e9bff717aed3c7280123e17e6b sha256
#> 11 4ebd53009fe1f19764d2da71e5667adb22a93c137223af1d14f7deb6ffc9ff4e sha256
#> 12 4ebd53009fe1f19764d2da71e5667adb22a93c137223af1d14f7deb6ffc9ff4e sha256
#> 13 2f75ee61ef4572844745a498e9427665f2a4b2baf061d1857fcf0172875b16b2 sha256
#> 14 2f75ee61ef4572844745a498e9427665f2a4b2baf061d1857fcf0172875b16b2 sha256
#> 15 4022cf0eecb39ff17fa26b75b0331e07c7b50c488966a20bcde4ed8c81c47f3a sha256
#> 16 4022cf0eecb39ff17fa26b75b0331e07c7b50c488966a20bcde4ed8c81c47f3a sha256
#> 17 780e987aeb4ea6239e2f3e08aa2ab3759dd4f212a10439bb1cef0117be02ee3f sha256
#> 18 780e987aeb4ea6239e2f3e08aa2ab3759dd4f212a10439bb1cef0117be02ee3f sha256
#> 19 fdbcf8de4d46a9cbc038a42da347f4bc875c2b9c41c5c231c89aac698debe337 sha256
#> 20 fdbcf8de4d46a9cbc038a42da347f4bc875c2b9c41c5c231c89aac698debe337 sha256
#> 21 4931804715cff0f1097f78d698c66224ad35b8997b44d068acf7654f9406851b sha256
#> 22 4931804715cff0f1097f78d698c66224ad35b8997b44d068acf7654f9406851b sha256
#> 23 de6671e21f2f7c35cbd634f2ba6e5ec3c7911cba5b39f3929712628e83940132 sha256
#> 24 de6671e21f2f7c35cbd634f2ba6e5ec3c7911cba5b39f3929712628e83940132 sha256
#> 25 70394cc363d907b01426a299d6ae15e728c51dd95de0ce58ae112eee6646bcb3 sha256
#> 26 ae460376db453aa4d3dc68adf64d539afe33b4e81b0dae23d014aa3280eda2d2 sha256
#> 27 a104a57f092110e317fe865a9a3819da9198fb8d055af7664a58bba558bb267d sha256
#> 28 3904b7a429b0ad1f5c16812ad994bcb4308d0d2d766746804c92c3b925c76460 sha256
#> 29 72f40fb7713ce913efa784051488eced663778194cfb30cb93f2fdedb6580ab3 sha256
#> 30 d93a39be63c0aac88fa7e2544f13e85e24b88914d903b943b07fcc0845250cf3 sha256
#> 31 7f60b0d3ab3be4f94c7bd21c6328db8f7ded65e735cd895ff521296994172d41 sha256
#> 32 7f60b0d3ab3be4f94c7bd21c6328db8f7ded65e735cd895ff521296994172d41 sha256
#> 33 7f60b0d3ab3be4f94c7bd21c6328db8f7ded65e735cd895ff521296994172d41 sha256
#> 34 4d7764e7def16b4c6b461ad4226f5981e2183c6266f72ae223ea7daadbb2ef84 sha256
#> 35 4d7764e7def16b4c6b461ad4226f5981e2183c6266f72ae223ea7daadbb2ef84 sha256
#> 36 ec4d6b4d88083a64b30d8d825906c1fa4c5b2dba060c2f388dfeb408a8546f5b sha256
#> 37 ec4d6b4d88083a64b30d8d825906c1fa4c5b2dba060c2f388dfeb408a8546f5b sha256
#> 38 3474e82e2d54c27f5c12f0cf960c204a1b1977390abbdcfa6c58d67cbc36b969 sha256
#> 39 3474e82e2d54c27f5c12f0cf960c204a1b1977390abbdcfa6c58d67cbc36b969 sha256
#> 40 53b6d92445749501ac37e8376a8ed13c9376b4a7e60ae6de7c0ed788c0670ad2 sha256
#> 41 53b6d92445749501ac37e8376a8ed13c9376b4a7e60ae6de7c0ed788c0670ad2 sha256
#> 42 a21a784b63df9a407ed36770ff49f4557e455aa83f2a867d59ac38e861ff0066 sha256
#> 43 a21a784b63df9a407ed36770ff49f4557e455aa83f2a867d59ac38e861ff0066 sha256
#>                   read datrasextra datras icesdatras r_version
#> 1  2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 2  2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 3  2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 4  2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 5  2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 6  2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 7  2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 8  2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 9  2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 10 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 11 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 12 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 13 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 14 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 15 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 16 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 17 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 18 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 19 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 20 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 21 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 22 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 23 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 24 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 25 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 26 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 27 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 28 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 29 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 30 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 31 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 32 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 33 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 34 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 35 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 36 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 37 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 38 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 39 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 40 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 41 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 42 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1
#> 43 2026-10-09 13:16:01       0.6.0  1.1.2      1.5.3     4.6.1

if (FALSE) { # \dontrun{
## Format an ICES data citation
e <- extraction(x)
sprintf("ICES Database of Trawl Surveys (DATRAS), Extraction %s of %s. ICES, Copenhagen",
        format(max(e$extracted), "%d %B %Y"),
        paste(unique(e$survey), collapse = ", "))
} # }
```
