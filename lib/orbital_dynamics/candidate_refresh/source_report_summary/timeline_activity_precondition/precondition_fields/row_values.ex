defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues do
  @moduledoc false

  alias __MODULE__.SummaryValues

  defdelegate row_count(summary), to: SummaryValues

  defdelegate precondition_count(summary, status), to: SummaryValues

  defdelegate precondition_status(summary), to: SummaryValues

  defdelegate precondition_types(summary, field), to: SummaryValues
end
