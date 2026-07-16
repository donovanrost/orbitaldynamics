defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.Summary
  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

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
    |> Map.merge(Pressure.source_report_fields(summary))
    |> compact_map()
  end

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
