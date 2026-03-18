
## require(DATRASextra)


## Helper to find one live survey-year combination that currently exists
live_datras_case <- function(preferred_surveys = c("NS-IBTS", "BITS")) {

  surveys_with_issues <- c(
    "NS-IDPS", "IS-IDPS", "Test-DATRAS", "NS-IBTS_UNIFtest"
  )

  available_surveys <- tryCatch(
    icesDatras::getSurveyList(),
    error = function(e) character()
  )

  survey_pool <- unique(c(
    intersect(preferred_surveys, available_surveys),
    setdiff(available_surveys, preferred_surveys)
  ))

  survey_pool <- setdiff(survey_pool, surveys_with_issues)

  for (survey in survey_pool) {
    years <- tryCatch(
      sort(icesDatras::getSurveyYearList(survey), decreasing = TRUE),
      error = function(e) integer()
    )

    for (year in years) {
      quarters <- tryCatch(
        icesDatras::getSurveyYearQuarterList(survey, year),
        error = function(e) integer()
      )

      if (length(quarters) > 0) {
        return(list(survey = survey, year = year))
      }
    }
  }

  return(NULL)
}


testthat::test_that("download_datras downloads one live survey-year zip", {
  testthat::skip_on_cran()
  testthat::skip_if_offline()
  testthat::skip_if_not_installed("DATRAS")
  testthat::skip_if_not_installed("icesDatras")

  target <- live_datras_case()
  testthat::skip_if(is.null(target), "No live DATRAS survey-year available for testing.")

  out_dir <- tempfile("datras_download_")
  dir.create(out_dir)
  old_wd <- getwd()

  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)
  on.exit(setwd(old_wd), add = TRUE)

  testthat::expect_invisible(
    download_datras(
      surveys = target$survey,
      years = target$year,
      dir = out_dir,
      verbose = FALSE
    )
  )

  zip_file <- file.path(
    out_dir,
    target$survey,
    paste0(target$survey, "_", target$year, ".zip")
  )

  testthat::expect_true(file.exists(zip_file))
  testthat::expect_gt(file.info(zip_file)$size, 0)

  zip_contents <- utils::unzip(zip_file, list = TRUE)
  testthat::expect_gt(nrow(zip_contents), 0)

  testthat::expect_identical(
    normalizePath(getwd(), winslash = "/", mustWork = FALSE),
    normalizePath(old_wd, winslash = "/", mustWork = FALSE)
  )
})


testthat::test_that("download_datras respects the requested year", {
  testthat::skip_on_cran()
  testthat::skip_if_offline()
  testthat::skip_if_not_installed("DATRAS")
  testthat::skip_if_not_installed("icesDatras")

  target <- live_datras_case()
  testthat::skip_if(is.null(target), "No live DATRAS survey-year available for testing.")

  out_dir <- tempfile("datras_year_filter_")
  dir.create(out_dir)
  old_wd <- getwd()

  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)
  on.exit(setwd(old_wd), add = TRUE)

  testthat::expect_invisible(
    download_datras(
      surveys = target$survey,
      years = target$year,
      dir = out_dir,
      verbose = FALSE
    )
  )

  survey_dir <- file.path(out_dir, target$survey)
  zip_files <- list.files(survey_dir, pattern = "\\.zip$", full.names = FALSE)

  testthat::expect_equal(
    zip_files,
    paste0(target$survey, "_", target$year, ".zip")
  )
})


testthat::test_that("download_missing_only = TRUE does not overwrite an existing zip", {
  testthat::skip_on_cran()
  testthat::skip_if_offline()
  testthat::skip_if_not_installed("DATRAS")
  testthat::skip_if_not_installed("icesDatras")

  target <- live_datras_case()
  testthat::skip_if(is.null(target), "No live DATRAS survey-year available for testing.")

  out_dir <- tempfile("datras_missing_only_")
  dir.create(out_dir)
  old_wd <- getwd()

  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)
  on.exit(setwd(old_wd), add = TRUE)

  ## First download
  testthat::expect_invisible(
    download_datras(
      surveys = target$survey,
      years = target$year,
      dir = out_dir,
      download_missing_only = TRUE,
      verbose = FALSE
    )
  )

  zip_file <- file.path(
    out_dir,
    target$survey,
    paste0(target$survey, "_", target$year, ".zip")
  )

  testthat::expect_true(file.exists(zip_file))

  first_mtime <- file.info(zip_file)$mtime

  ## Ensure timestamp differences are detectable on most file systems
  Sys.sleep(1.2)

  ## Second call should leave the existing file untouched
  testthat::expect_invisible(
    download_datras(
      surveys = target$survey,
      years = target$year,
      dir = out_dir,
      download_missing_only = TRUE,
      verbose = FALSE
    )
  )

  second_mtime <- file.info(zip_file)$mtime

  testthat::expect_equal(
    as.numeric(first_mtime),
    as.numeric(second_mtime)
  )
})


testthat::test_that("problematic surveys are skipped when force = FALSE", {
  out_dir <- tempfile("datras_skip_problematic_")
  dir.create(out_dir)
  old_wd <- getwd()

  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)
  on.exit(setwd(old_wd), add = TRUE)

  testthat::expect_invisible(
    download_datras(
      surveys = "Test-DATRAS",
      years = 2000,
      dir = out_dir,
      force = FALSE,
      verbose = FALSE
    )
  )

  testthat::expect_false(dir.exists(file.path(out_dir, "Test-DATRAS")))
})
