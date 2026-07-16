defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution do
  @moduledoc false

  alias __MODULE__.{CapacityFields, PreservedSummary, RecommendationFields, SourceFields}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def report_input_summary([]), do: nil

  def report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports)
    |> Map.merge(report_fields(reports))
    |> compact_map()
  end

  defdelegate report_from_summary(summary), to: PreservedSummary

  defp report_fields(reports) do
    RecommendationFields.fields(reports)
    |> Map.merge(CapacityFields.fields(reports))
  end
end
