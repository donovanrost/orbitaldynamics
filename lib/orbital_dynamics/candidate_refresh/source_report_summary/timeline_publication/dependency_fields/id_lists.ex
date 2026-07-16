defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.DependencyFields.IdLists do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def fields(summaries) do
    Map.new(FieldSpecs.id_list_fields(), fn field ->
      {field, values(summaries, field)}
    end)
  end

  defp values(summaries, field) do
    summaries
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
  end
end
