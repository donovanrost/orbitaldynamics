defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields do
  @moduledoc false

  alias __MODULE__.BaseFields
  alias __MODULE__.CountMaps
  alias __MODULE__.FeedbackCounts
  alias __MODULE__.RowValues
  alias __MODULE__.SourceContext

  def fields(reports) do
    BaseFields.fields(reports)
    |> Map.merge(CountMaps.fields(reports))
    |> Map.merge(FeedbackCounts.fields(reports))
  end

  def row_count(report), do: RowValues.row_count(report)

  def contact_count(report), do: FeedbackCounts.contact_count(report)

  def command_count(report), do: FeedbackCounts.command_count(report)

  def maneuver_count(report), do: FeedbackCounts.maneuver_count(report)

  def observation_count(report), do: FeedbackCounts.observation_count(report)

  def station_throughput_count(report), do: FeedbackCounts.station_throughput_count(report)

  def input_keys(reports) do
    SourceContext.input_keys(reports)
  end

  def source_required_operator_action_counts(report),
    do: CountMaps.source_required_operator_action_counts(report)

  def trust_boundaries(report_or_reports) do
    SourceContext.trust_boundaries(report_or_reports)
  end
end
