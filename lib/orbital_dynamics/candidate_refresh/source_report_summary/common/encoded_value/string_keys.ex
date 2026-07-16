defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue.StringKeys do
  @moduledoc false

  alias __MODULE__.Traversal
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue.Value

  def stringify_keys(value), do: Traversal.map(value, &Value.value/1, &Value.value/1)

  def stringify_keys_preserving_values(value) do
    Traversal.map(value, &to_string/1, fn value -> value end)
  end

  def stringify_keys_with_keyword_maps(value) do
    Traversal.map(value, &Value.value_with_keyword_maps/1, &Value.value_with_keyword_maps/1)
  end
end
