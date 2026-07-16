defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportRowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportRowCounts
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportValueEncoding

  def invalid_input_row?(row) do
    row = stringify_keys(row)

    row["invalid_contact_input"] == true or
      row["suppressed_reason"] == "invalid_contact_input" or
      row["required_operator_action"] == "review_invalid_contact_filter_input" or
      row["action"] == "review_invalid_contact_filter_input"
  end

  def count_rows(rows, field) do
    ContactFilterReportRowCounts.count_rows(rows, field)
  end

  def result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  def maybe_put(map, _key, nil), do: map
  def maybe_put(map, key, value), do: Map.put(map, key, value)

  def stringify_keys(value), do: ContactFilterReportValueEncoding.stringify_keys(value)
end
