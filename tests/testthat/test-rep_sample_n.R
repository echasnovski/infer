context("rep_sample_n")

n_population <- 5
population <- tibble::tibble(
  ball_id = 1:n_population,
  color = factor(c(rep("red", 3), rep("white", n_population - 3)))
)


# rep_sample_n ------------------------------------------------------------
test_that("`rep_sample_n` works", {
  out <- rep_sample_n(population, size = 2, reps = 5)
  expect_equal(nrow(out), 2 * 5)
  expect_equal(colnames(out), c("replicate", colnames(population)))
  expect_true(dplyr::is_grouped_df(out))
})

test_that("`rep_sample_n` checks input", {
  # `tbl`
  expect_error(rep_sample_n("a", size = 1), "`tbl`.*'data.frame'")

  # `size`
  expect_error(rep_sample_n(population, size = "a"), "`size`.*number")
  expect_error(rep_sample_n(population, size = 1:2), "`size`.*single")
  expect_error(rep_sample_n(population, size = -1), "`size`.*non-negative")

  # `replace`
  expect_error(
    rep_sample_n(population, size = 1, replace = "a"),
    "`replace`.*'TRUE or FALSE'"
  )

  # `reps`
  expect_error(
    rep_sample_n(population, size = 1, reps = "a"),
    "`reps`.*number"
  )
  expect_error(
    rep_sample_n(population, size = 1, reps = 1:2),
    "`reps`.*single"
  )
  expect_error(
    rep_sample_n(population, size = 1, reps = 0.5),
    "`reps`.*not less than 1"
  )

  # `prob`
  expect_error(
    rep_sample_n(population, size = 1, prob = "a"),
    "`prob`.*numeric"
  )
  expect_error(
    rep_sample_n(population, size = 1, prob = c(0.1, 0.9)),
    glue::glue("`prob`.*length.*{nrow(population)}")
  )
})

test_that("`rep_sample_n` gives error on big sample size if `replace=FALSE`", {
  expect_error(
    rep_sample_n(population, size = n_population * 2),
    "Use `replace = TRUE`"
  )
})

test_that("`rep_sample_n` uses `size`", {
  set.seed(1)
  out <- rep_sample_n(population, size = 2)
  expect_equal(nrow(out), 2)

  # `size = 0` is allowed following `dplyr::sample_n()`
  out <- rep_sample_n(population, size = 0)
  expect_true(nrow(out) == 0)
})

test_that("`rep_sample_n` uses `replace`", {
  set.seed(1)
  res_repl <- rep_sample_n(population, size = 5, reps = 100, replace = TRUE)

  set.seed(1)
  res_norepl <- rep_sample_n(population, size = 5, reps = 100, replace = FALSE)

  expect_true(all(res_repl[["replicate"]] == res_norepl[["replicate"]]))
  expect_false(all(res_repl[["ball_id"]] == res_norepl[["ball_id"]]))
  expect_false(all(res_repl[["color"]] == res_norepl[["color"]]))

  # Check if there are actually no duplicates in case `replace = FALSE`
  no_duplicates <- all(
    tapply(res_norepl$ball_id, res_norepl$replicate, anyDuplicated) == 0
  )
  expect_true(no_duplicates)
})

test_that("`rep_sample_n` uses `reps`", {
  set.seed(1)
  out <- rep_sample_n(population, size = 2, reps = 5)
  expect_equal(nrow(out), 2 * 5)

  # `size = 0` is allowed even with `reps > 1`
  out <- rep_sample_n(population, size = 0, reps = 10)
  expect_true(nrow(out) == 0)
})

test_that("`rep_sample_n` uses `prob`", {
  set.seed(1)
  res1 <- rep_sample_n(
    population,
    size = 5,
    reps = 100,
    replace = TRUE,
    prob = c(1, rep(0, n_population - 1))
  )

  expect_true(all(res1$ball_id == 1))
  expect_true(all(res1$color == "red"))

  # `prob` should be automatically normalized
  set.seed(1)
  res1 <- rep_sample_n(
    population,
    size = n_population,
    prob = rep(1, n_population)
  )
  set.seed(1)
  res2 <- rep_sample_n(
    population,
    size = n_population,
    prob = rep(1, n_population) / n_population
  )

  expect_equal(res1[["ball_id"]], res2[["ball_id"]])
})


# rep_slice_sample --------------------------------------------------------
test_that("`rep_slice_sample` works", {
  # By default only one row should be sampled
  out <- rep_slice_sample(population)
  expect_equal(nrow(out), 1)
  expect_equal(colnames(out), c("replicate", colnames(population)))
  expect_true(dplyr::is_grouped_df(out))

  # Using `n` argument
  out <- rep_slice_sample(population, n = 2, reps = 5)
  expect_equal(nrow(out), 2 * 5)

  # Using `prop` argument
  prop <- 2 / n_population
  out <- rep_slice_sample(population, prop = prop, reps = 5)
  expect_equal(nrow(out), 2 * 5)
})

test_that("`rep_slice_sample` checks input", {
  # `.data`
  expect_error(rep_slice_sample("a", n = 1), "`.data`.*'data.frame'")

  # `n`
  expect_error(rep_slice_sample(population, n = "a"), "`n`.*number")
  expect_error(rep_slice_sample(population, n = 1:2), "`n`.*single")
  expect_error(rep_slice_sample(population, n = -1), "`n`.*non-negative")

  # `prop`
  expect_error(rep_slice_sample(population, prop = "a"), "`prop`.*number")
  expect_error(rep_slice_sample(population, prop = 1:2), "`prop`.*single")
  expect_error(rep_slice_sample(population, prop = -1), "`prop`.*non-negative")

  # Only one `n` or `prop` should be supplied
  expect_error(
    rep_slice_sample(population, n = 1, prop = 0.5),
    "exactly one.*`n` or `prop`"
  )

  # `replace`
  expect_error(
    rep_slice_sample(population, n = 1, replace = "a"),
    "`replace`.*'TRUE or FALSE'"
  )

  # `weight_by`
  expect_error(
    rep_slice_sample(population, n = 1, weight_by = "a"),
    "`weight_by`.*numeric"
  )
  expect_error(
    rep_slice_sample(population, n = 1, weight_by = c(0.1, 0.9)),
    glue::glue("`weight_by`.*length.*{nrow(population)}")
  )

  # `reps`
  expect_error(
    rep_slice_sample(population, n = 1, reps = "a"),
    "`reps`.*number"
  )
  expect_error(
    rep_slice_sample(population, n = 1, reps = 1:2),
    "`reps`.*single"
  )
  expect_error(
    rep_slice_sample(population, n = 1, reps = 0.5),
    "`reps`.*not less than 1"
  )
})

test_that("`rep_slice_sample` warns on big sample size if `replace = FALSE`", {
  # Using big `n`
  expect_warning(
    out <- rep_slice_sample(population, n = n_population * 2, reps = 1),
    "sample size.*bigger.*number of rows"
  )
  expect_true(nrow(out) == n_population)

  # Using big `prop`
  expect_warning(
    out <- rep_slice_sample(population, prop = 2, reps = 1),
    "sample size.*bigger.*number of rows"
  )
  expect_true(nrow(out) == n_population)
})

test_that("`rep_slice_sample` uses `n` and `prop`", {
  set.seed(1)
  res1 <- rep_slice_sample(population, n = 1)

  set.seed(1)
  res2 <- rep_slice_sample(population, prop = 1 / n_population)

  expect_equal(res1, res2)

  # Output sample size is rounded down when using `prop`
  set.seed(1)
  res3 <- rep_slice_sample(population, prop = 1.5 / n_population)

  expect_equal(res2, res3)

  # `n = 0` is allowed
  out <- rep_slice_sample(population, n = 0)
  expect_equal(nrow(out), 0)

  # `prop = 0` is allowed
  out <- rep_slice_sample(population, prop = 0)
  expect_equal(nrow(out), 0)
})

test_that("`rep_slice_sample` uses `replace`", {
  set.seed(1)
  res_repl <- rep_slice_sample(population, n = 5, reps = 100, replace = TRUE)

  set.seed(1)
  res_norepl <- rep_slice_sample(population, n = 5, reps = 100, replace = FALSE)

  expect_true(all(res_repl[["replicate"]] == res_norepl[["replicate"]]))
  expect_false(all(res_repl[["ball_id"]] == res_norepl[["ball_id"]]))
  expect_false(all(res_repl[["color"]] == res_norepl[["color"]]))

  # Check if there are actually no duplicates in case `replace = FALSE`
  no_duplicates <- all(
    tapply(res_norepl$ball_id, res_norepl$replicate, anyDuplicated) == 0
  )
  expect_true(no_duplicates)
})

test_that("`rep_slice_sample` uses `weight_by`", {
  set.seed(1)
  res1 <- rep_slice_sample(
    population,
    n = 5,
    reps = 100,
    replace = TRUE,
    weight_by = c(1, rep(0, n_population - 1))
  )

  expect_true(all(res1$ball_id == 1))
  expect_true(all(res1$color == "red"))

  # `weight_by` should be automatically normalized
  set.seed(1)
  res1 <- rep_slice_sample(
    population,
    n = n_population,
    weight_by = rep(1, n_population)
  )
  set.seed(1)
  res2 <- rep_slice_sample(
    population,
    n = n_population,
    weight_by = rep(1, n_population) / n_population
  )

  expect_equal(res1[["ball_id"]], res2[["ball_id"]])
})

test_that("`rep_slice_sample` uses `reps`", {
  set.seed(1)
  out <- rep_slice_sample(population, n = 2, reps = 5)
  expect_equal(nrow(out), 2 * 5)

  # `n = 0` is allowed even with `reps > 1`
  out <- rep_slice_sample(population, n = 0, reps = 10)
  expect_true(nrow(out) == 0)

  # `prop = 0` is allowed even with `reps > 1`
  out <- rep_slice_sample(population, prop = 0, reps = 10)
  expect_true(nrow(out) == 0)
})
