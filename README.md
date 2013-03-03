# GeneRunnerAPI

Query Zooniverse's Gene Runner data.

* **GET** `/samples` returns an array of all sample ids
* **GET** `/samples/all` returns the metadata for all samples
* **GET** `/samples/:id` returns the metadata for sample with id `:id`
* **GET** `/points/:id` returns all data points for sample with id `:id` as nested
  array sorted by the first column
* **GET** `/points/:id/:start/:end` returns the slice of data points from `:start`
  to `:end` for sample with id `:id` as nested array
* **POST** `/interactions/:id` expects an array of player interactions for sample
  with id `:id` in the format
  ```
  [
    { "c": {"x": integer, "y": float},
      "e": {"x": integer, "y": float} }
    , ...
  ]
  ```
