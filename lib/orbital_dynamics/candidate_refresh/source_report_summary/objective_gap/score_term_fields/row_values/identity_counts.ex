defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ScoreTermFields.RowValues.IdentityCounts do
  @moduledoc false

  alias __MODULE__.IdentityValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.IdentityCountValues

  def term_key_counts(rows) do
    IdentityCountValues.count(rows, &IdentityValues.term_keys/1)
  end

  def ground_station_counts(rows) do
    IdentityCountValues.count(rows, &IdentityValues.ground_station_ids/1)
  end

  def target_counts(rows) do
    IdentityCountValues.count(rows, &IdentityValues.target_ids/1)
  end

  def collection_counts(rows) do
    IdentityCountValues.count(rows, &IdentityValues.collection_ids/1)
  end

  def source_activity_id_counts(rows) do
    IdentityCountValues.count(rows, &IdentityValues.source_activity_ids/1)
  end
end
