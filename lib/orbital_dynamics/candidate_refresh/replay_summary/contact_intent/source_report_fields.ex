defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.Summary
  alias __MODULE__.Flattened

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("contact_intent", %{})
      |> Summary.summary(
        "candidate_refresh.source_report_provenance.contact_intent",
        "contact_intent_source_report_provenance_only"
      )

    source_reports
    |> Flattened.source_report_fields()
    |> Map.merge(%{
      "source_report_contact_intent_branch_local_contact_intent_pressure" =>
        Map.get(summary, "branch_local_contact_intent_pressure"),
      "source_report_contact_intent_branch_local_station_feedback_pressure" =>
        Map.get(summary, "branch_local_station_feedback_pressure"),
      "source_report_contact_intent_branch_local_capacity_pack_pressure" =>
        Map.get(summary, "branch_local_capacity_pack_pressure")
    })
    |> compact_map()
  end

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
