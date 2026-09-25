# frozen_string_literal: true

# Default country for numbers that are not already in E.164.
# Business phones are normalized with a leading "+", so country is usually
# inferred from the number itself; this only applies to ambiguous local formats.
Phonelib.default_country = ENV.fetch("PHONELIB_DEFAULT_COUNTRY", "US")
