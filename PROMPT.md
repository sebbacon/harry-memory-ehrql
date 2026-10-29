› Here's a report from an opensafely user. I'd like you to consider their request and think about a solution and
  how best to communicate it with them, perhaps through a commit with documentation and a good comment, but you
  might have better ideas.

  When considering possible solutions be sure to think about profiling your ideas

  I've checked out the repo locally for you

  ---

  Hi there. I had a job fail due to lack of memory (that had enough memory for two similar if slightly smaller
  datasets).
  https://jobs.opensafely.org/investigating-events-following-covid-19/post-covid-neurodegenerative-v3/27246/epj7cen
  pucv6nfnm/

  I'm not sure there's anything I can do to reduce the memory of the job (it is an action on one dataframe, and no
  other dataframes or large varibles should be in memory at that point). It failed on line 152 of this script:
  https://github.com/opensafely/post-covid-neurodegenerative/blob/main/analysis/table1/table1_hospitalised.R

  Would I be able to increase memory for this job (as said, it's run on a slightly smaller dataset so hopefully
  wouldn't require too much more). Otherwise, is there an alternate function to aggregate in R that is known to be
  less memory intensive?
