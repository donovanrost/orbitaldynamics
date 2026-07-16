defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineReportRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineReportValues,
    as: Values

  def from_rows(path, source, rows, artifact) do
    report =
      %{
        "schema_contract" => "operational_timeline_report.v1",
        "model" => "preserved_operational_timeline_rows",
        "source" => source,
        "rows" => rows,
        "row_count" => length(rows),
        "contact_count" => Values.contact_count(rows),
        "command_count" => Values.command_count(rows),
        "maneuver_count" => Values.maneuver_count(rows),
        "observation_count" => Values.observation_count(rows),
        "required_operator_action_counts" => Values.count_rows(rows, "required_operator_action")
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", Values.result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
