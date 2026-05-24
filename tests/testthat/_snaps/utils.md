# parse_duration errors on bad input

    Code
      parse_duration("nope")
    Condition
      Error in `FUN()`:
      ! Unexpected input format nope

# label_n rejects unsupported input

    Code
      label_n("a")
    Condition
      Error in `label_n()`:
      ! 'x' must be a data.frame or a numeric vector of length 1

---

    Code
      label_n(1:3)
    Condition
      Error in `label_n()`:
      ! 'x' must be a data.frame or a numeric vector of length 1

