# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  # Need to increase it because of <.label_value_list /> that does a <pre> tag, which will look broken with extra whitespace.
  heex_line_length: 300
]
