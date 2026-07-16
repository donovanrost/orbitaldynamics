defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.SourceReport.Metadata do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  def status_from_boundaries([]), do: "missing"
  def status_from_boundaries(_trust_boundaries), do: "declared"

  def trust_boundaries(reports) do
    OperationalFeedback.source_timeline_feedback_trust_boundaries(reports)
  end

  def existing_rows_source(sources) do
    sources
    |> Enum.find(&(&1["source"] == "timeline_feedback_report.rows"))
    |> case do
      %{} = source -> source
      _source -> %{}
    end
  end

  def maybe_put(map, _key, nil), do: map
  def maybe_put(map, key, value), do: Map.put(map, key, value)
end
