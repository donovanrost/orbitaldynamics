defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview do
  @moduledoc false

  alias __MODULE__.CommandWindowFields
  alias __MODULE__.ManeuverReviewFields
  alias __MODULE__.SourceReports

  def command_window_report_input_summary([]), do: nil

  def command_window_report_input_summary(sources) do
    CommandWindowFields.fields(sources)
  end

  def maneuver_review_report_input_summary([]), do: nil

  def maneuver_review_report_input_summary(sources) do
    ManeuverReviewFields.fields(sources)
  end

  defdelegate command_window_report_source(report), to: SourceReports

  defdelegate command_window_report_source_required_operator_action_counts(report),
    to: SourceReports

  defdelegate maneuver_review_report_source(report), to: SourceReports

  defdelegate maneuver_review_report_source_required_operator_action_counts(report),
    to: SourceReports
end
