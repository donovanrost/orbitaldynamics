defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.SummaryFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs
  alias __MODULE__.IdFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_report_field_values: 2]

  def fields(summaries) do
    count_fields(summaries)
    |> Map.merge(IdFields.fields(summaries))
  end

  defp count_fields(summaries) do
    Map.new(FieldSpecs.count_fields(), fn {output_field, source_field} ->
      {output_field, summaries |> count_report_field_values(source_field) |> non_empty_map()}
    end)
  end

  defp non_empty_map(map) do
    case map do
      %{} when map_size(map) == 0 -> nil
      _map -> map
    end
  end
end
