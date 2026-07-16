defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.IdLists.NormalizedValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def ids(values) do
    values
    |> sorted_string_values()
    |> non_empty()
  end

  defp non_empty([]), do: nil
  defp non_empty(values), do: values
end
