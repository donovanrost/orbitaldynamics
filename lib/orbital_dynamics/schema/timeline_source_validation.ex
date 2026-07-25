defmodule OrbitalDynamics.Schema.TimelineSourceValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate_optional_timeline_diff_summary_source(issues, path, summary),
    do:
      OrbitalDynamics.Schema.TimelinePublicationSummaryContracts.validate_optional_timeline_diff_summary_source(
        issues,
        path,
        summary
      )

  def validate_optional_timeline_dependency_impact_source_row(issues, _path, nil), do: issues

  def validate_optional_timeline_dependency_impact_source_row(issues, path, %{} = row),
    do:
      OrbitalDynamics.Schema.TimelineDependencyImpactSummaryContracts.validate_row(
        issues,
        path,
        row
      )

  def validate_optional_timeline_dependency_impact_source_row(issues, path, _row),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_activity_precondition_summary_source(issues, _path, nil),
    do: issues

  def validate_optional_timeline_activity_precondition_summary_source(
        issues,
        path,
        %{} = summary
      ) do
    OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryContracts.validate(
      issues,
      path,
      summary,
      timeline_report_model_limits()
    )
  end

  def validate_optional_timeline_activity_precondition_summary_source(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_activity_precondition_summaries(issues, _path, nil),
    do: issues

  def validate_optional_timeline_activity_precondition_summaries(issues, path, summaries)
      when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = summary, index}, acc ->
        OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryContracts.validate(
          acc,
          "#{path}[#{index}]",
          summary,
          timeline_report_model_limits()
        )

      {_summary, index}, acc ->
        [error("#{path}[#{index}]", "must be an object") | acc]
    end)
  end

  def validate_optional_timeline_activity_precondition_summaries(issues, path, _summaries),
    do: [error(path, "must be a list") | issues]

  def validate_optional_timeline_integrity_report(issues, _path, nil), do: issues

  def validate_optional_timeline_integrity_report(issues, path, %{} = report) do
    OrbitalDynamics.Schema.TimelineIntegrityReportContracts.validate(
      issues,
      path,
      report,
      timeline_report_model_limits()
    )
  end

  def validate_optional_timeline_integrity_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_preservation_report(issues, _path, nil), do: issues

  def validate_optional_timeline_preservation_report(issues, path, %{} = report) do
    OrbitalDynamics.Schema.TimelinePreservationContracts.validate_report(
      issues,
      path,
      report,
      timeline_report_model_limits()
    )
  end

  def validate_optional_timeline_preservation_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_preservation_source_row(issues, _path, nil), do: issues

  def validate_optional_timeline_preservation_source_row(issues, path, %{} = row) do
    OrbitalDynamics.Schema.TimelinePreservationContracts.validate_optional_source_row(
      issues,
      path,
      row
    )
  end

  def validate_optional_timeline_preservation_source_row(issues, path, row),
    do:
      OrbitalDynamics.Schema.TimelinePreservationContracts.validate_optional_source_row(
        issues,
        path,
        row
      )

  def validate_optional_timeline_lifecycle_state_source_row(issues, path, row) do
    OrbitalDynamics.Schema.TimelineLifecycleStateSourceContracts.validate_optional(
      issues,
      path,
      row
    )
  end

  def validate_optional_timeline_activity_state_source(issues, _path, nil), do: issues

  def validate_optional_timeline_activity_state_source(issues, path, %{} = state) do
    OrbitalDynamics.Schema.TimelineActivityStateContracts.validate(
      issues,
      path,
      state,
      timeline_feedback_report_model_limits()
    )
  end

  def validate_optional_timeline_activity_state_source(issues, path, _state),
    do: [error(path, "must be an object") | issues]

  defp timeline_feedback_report_model_limits do
    OrbitalDynamics.TimelineFeedback.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp timeline_report_model_limits do
    OrbitalDynamics.Timeline.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
