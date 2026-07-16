defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue do
  @moduledoc false

  alias __MODULE__.StringKeys
  alias __MODULE__.Value

  defdelegate value(value), to: Value
  defdelegate value_with_keyword_maps(value), to: Value
  defdelegate stringify_keys(value), to: StringKeys
  defdelegate stringify_keys_preserving_values(value), to: StringKeys
  defdelegate stringify_keys_with_keyword_maps(value), to: StringKeys
end
