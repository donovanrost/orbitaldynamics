defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollectionArtifactEncoding

  def contact_count(rows) do
    Enum.count(rows, &OperationalFeedback.operational_timeline_contact_feedback_row?/1)
  end

  def command_count(rows) do
    Enum.count(rows, &OperationalFeedback.operational_timeline_command_feedback_row?/1)
  end

  def maneuver_count(rows) do
    Enum.count(rows, &OperationalFeedback.operational_timeline_maneuver_feedback_row?/1)
  end

  def observation_count(rows) do
    Enum.count(rows, &OperationalFeedback.operational_timeline_observation_feedback_row?/1)
  end

  def count_rows(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  def result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp stringify_keys(value),
    do: OperationalTimelineCollectionArtifactEncoding.stringify_keys(value)
end
