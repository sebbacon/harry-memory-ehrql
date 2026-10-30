# Memory use in the hospitalised Table 1 action

The reported failure is at the formula-based `aggregate()` in
`analysis/table1/table1_hospitalised.R`. Before this call, `pivot_longer()`
creates one row per patient per characteristic. With 500,000 patients and 33
characteristics that is 16.5 million rows. The formula/model-frame, response
matrix and grouping operations in `aggregate()` need temporary allocations in
addition to that table. Having one named dataframe does not mean that only one
dataframe's worth of memory is required. A slightly larger cohort can therefore
exceed the job's limit even when other cohorts succeed.

`fn-hospitalised_counts.R` summarises one characteristic at a time using the
existing dplyr dependency, then combines the small count tables. It converts
factors and binary values and labels missing categories within each column.
This avoids constructing the full patient-by-characteristic table. Replacing
only the final `aggregate()` could reduce some allocations but would retain
that large intermediate table. The two age summaries also now subset the age
vector directly, avoiding temporary subsets of the full cohort dataframe.

Counts preserve the original formula method's exclusion of patients with either
hospitalisation indicator missing. `NA`, empty strings and `"unknown"` category
values still become `"Missing"`. Unused factor levels produce no rows. Sorting,
median rows, rounding, percentages and CSV formatting follow the existing script.
Inputs with no complete indicator rows still raise an error.

## Measurements

These are local synthetic benchmarks on Linux aarch64, R 4.5.2, dplyr 1.2.0 and
tidyr 1.3.2. Each method ran in a fresh R process. The synthetic input contains
30 factor characteristics, a logical binary characteristic, a region and `All`
(33 characteristics in total), with a fixed seed and missing category values.
Both methods return 126 summary rows.

| Patients | Method | Aggregation elapsed (s) | Peak process RSS (KiB) |
| ---: | --- | ---: | ---: |
| 100,000 | Original reshape + aggregate | 2.558 | 871,024 |
| 100,000 | One characteristic at a time | 0.247 | 141,184 |
| 500,000 | Original reshape + aggregate | 13.826 | 3,886,208 |
| 500,000 | One characteristic at a time | 1.047 | 257,088 |

At 500,000 patients, peak RSS fell by about 93%, from 3.71 GiB to 251 MiB.
Elapsed time covers conversion, reshaping and counting, after input generation.
Peak RSS covers the whole process, including packages, input generation and
counting; it is a high-water mark, not cumulative allocations or `object.size()`.
These are single observations per configuration, not statistical timing estimates.

The benchmark isolates the changed counting stage. It does not measure loading
the full cleaned cohort, early filtering, median calculation or CSV writing.
The wide cohort still has to fit in memory. Real row counts, category cardinality,
package versions and job limits may differ; these measurements do not establish
that the failed production job will now fit. The linked job's logs and memory
limit were not available during this investigation because network access to
jobs.opensafely.org required approval. No real patient data were used.

## Reproduce

From the study directory, with R and the action's existing R packages installed:

```sh
Rscript tests/test_table1_hospitalised.R
Rscript tests/test_table1_hospitalised_output.R

# GNU time on Linux: run each command separately for independent peak RSS.
/usr/bin/time -f 'peak_rss_kib=%M wall_seconds=%e' Rscript tests/profile_table1_hospitalised.R legacy 100000 30
/usr/bin/time -f 'peak_rss_kib=%M wall_seconds=%e' Rscript tests/profile_table1_hospitalised.R incremental 100000 30
/usr/bin/time -f 'peak_rss_kib=%M wall_seconds=%e' Rscript tests/profile_table1_hospitalised.R legacy 500000 30
/usr/bin/time -f 'peak_rss_kib=%M wall_seconds=%e' Rscript tests/profile_table1_hospitalised.R incremental 500000 30
```

The count tests compare with the original reshape/aggregate implementation and
cover missing indicators, category label collisions, unused factor levels,
single groups and invalid empty responses. The output test runs the full script
with each counting method and checks both CSVs byte for byte for all three
cohorts and `All`/`TRUE`/`FALSE` pre-existing condition filters. The resulting
18 CSV pairs matched. A separate local check also compared those outputs against
the complete original script from commit `a60985c`, including the original age
subsetting expressions; those matched too. Warnings are treated as errors in the
checks. The complete OpenSAFELY pipeline was not run.

After applying the change, rerun the failed hospitalised Table 1 action in the
approved environment and check its resource usage and outputs. If it still
fails, use the new failing stage and peak memory to guide further changes.

## Suggested reply to the researcher

Thanks for the details. There is a way to reduce memory use in this script.
Before the failing line, `pivot_longer()` expands the data to one row per patient
per characteristic. `aggregate()` then needs extra temporary memory, so a single
dataframe can still require substantially more memory during that operation.

I've changed the script to count one characteristic at a time and combine the
small summaries. In a local synthetic example with 500,000 patients and 33
characteristics, peak memory for the counting benchmark fell from 3.71 GiB to
251 MiB. Both output CSVs matched the original script in synthetic checks across
all three cohorts and condition filters.

Please try rerunning the failed action with this change. The measurements are
from synthetic data, so we still need to check memory use on your actual cohort.
I haven't confirmed the memory limit for your job or whether it can be raised;
OpenSAFELY support would need to check that for the linked job if more memory
is still needed.
