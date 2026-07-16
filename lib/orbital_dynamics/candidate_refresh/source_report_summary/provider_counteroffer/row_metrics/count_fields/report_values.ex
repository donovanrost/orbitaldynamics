defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.CountFields.ReportValues do
  @moduledoc false

  alias __MODULE__.LockDeadlineStatus
  alias __MODULE__.RowCountValues

  def row_count(report), do: RowCountValues.row_count(report)

  def reviewable_count(report), do: RowCountValues.reviewable_count(report)

  def status_counts(report), do: RowCountValues.status_counts(report)

  def required_action_counts(report), do: RowCountValues.required_action_counts(report)

  def lock_deadline_status_counts(report) do
    LockDeadlineStatus.counts(report)
  end

  def ids_by_lock_deadline_status(report) do
    LockDeadlineStatus.ids(report)
  end
end
