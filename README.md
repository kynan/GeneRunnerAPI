# GeneRunnerAPI

Query Zooniverse's Gene Runner data.

* `/samples` returns an array of all sample ids
* `/samples/:id` returns the metadata for sample with id `:id`
* `/points/:id` returns all data points for sample with id `:id` as nested
  array sorted by the first column
* `/points/:id/:start/:end` returns the slice of data points from `:start` to
  `:end` for sample with id `:id` as nested array
