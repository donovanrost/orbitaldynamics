defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.SourceFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1
    ]

  def fields(sources, summaries) do
    %{
      "paths" => Enum.map(sources, fn {path, _summary} -> path end),
      "contract" => "timeline_lifecycle_state_summary.v1",
      "count" => length(sources),
      "source_summary_model_counts" =>
        summaries
        |> count_report_field_values("model")
        |> non_empty_map(),
      "source_summary_schema_contract_counts" =>
        summaries
        |> count_report_field_values("schema_contract")
        |> non_empty_map(),
      "trust_boundary_status" => source_report_trust_boundary_status(summaries),
      "trust_boundaries" => source_report_trust_boundaries(summaries)
    }
  end

  defp non_empty_map(map) do
    case map do
      %{} when map_size(map) == 0 -> nil
      _map -> map
    end
  end
end
