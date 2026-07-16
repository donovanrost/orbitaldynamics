defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.CompactCounts.ResolvedCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.CompactCounts.FallbackCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.CompactCounts.ModelIdMaps

  def summary_count(summary, field) do
    case ModelIdMaps.count(summary) do
      {:ok, count} -> count
      :error -> FallbackCounts.integer(summary, field)
    end
  end

  def status_count(summary, status) do
    case ModelIdMaps.group_count(summary, "model_ids_by_status", status) do
      {:ok, count} -> count
      :error -> FallbackCounts.integer(summary, "#{status}_count")
    end
  end

  def validation_level_count(summary, validation_level) do
    case ModelIdMaps.group_count(summary, "model_ids_by_validation_level", validation_level) do
      {:ok, count} -> count
      :error -> FallbackCounts.integer(summary, "unknown_model_count")
    end
  end

  def validation_level_counts(summary) do
    case ModelIdMaps.count_map(summary, "model_ids_by_validation_level") do
      {:ok, counts} -> counts
      :error -> FallbackCounts.validation_level_counts(summary)
    end
  end
end
