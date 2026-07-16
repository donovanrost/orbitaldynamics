defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.FeedbackCounts do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.RowCounts

  def fields(reports), do: CountFields.fields(reports, __MODULE__)

  defdelegate contact_count(report), to: RowCounts

  defdelegate command_count(report), to: RowCounts

  defdelegate maneuver_count(report), to: RowCounts

  defdelegate observation_count(report), to: RowCounts

  defdelegate station_throughput_count(report), to: RowCounts
end
