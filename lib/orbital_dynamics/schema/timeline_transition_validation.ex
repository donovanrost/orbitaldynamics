defmodule OrbitalDynamics.Schema.TimelineTransitionValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate_timeline_transition_application_report(issues, path, report),
    do:
      validate_timeline_transition_application_report(
        issues,
        path,
        report,
        default_callbacks()
      )

  def validate_timeline_transition_application_report(issues, path, report, callbacks) do
    OrbitalDynamics.Schema.TimelineTransitionApplicationReportContracts.validate(
      issues,
      path,
      report,
      timeline_report_model_limits(),
      &OrbitalDynamics.Schema.TimelineTransitionApplicationReportCountContracts.validate/3,
      fn child_issues, child_path, activity ->
        validate_timeline_transition_selected_activity(
          child_issues,
          child_path,
          activity,
          callbacks
        )
      end,
      fn child_issues, child_path, row ->
        validate_timeline_transition_application_row(child_issues, child_path, row, callbacks)
      end
    )
  end

  def validate_timeline_transition_application_summary(issues, path, summary),
    do:
      validate_timeline_transition_application_summary(
        issues,
        path,
        summary,
        default_callbacks()
      )

  def validate_timeline_transition_application_summary(issues, path, summary, callbacks) do
    OrbitalDynamics.Schema.TimelineTransitionApplicationSummaryContracts.validate(
      issues,
      path,
      summary,
      timeline_report_model_limits(),
      fn child_issues, child_path, row ->
        validate_timeline_transition_application_row(child_issues, child_path, row, callbacks)
      end
    )
  end

  def validate_optional_timeline_transition_application_report(issues, path, report),
    do:
      validate_optional_timeline_transition_application_report(
        issues,
        path,
        report,
        default_callbacks()
      )

  def validate_optional_timeline_transition_application_report(issues, _path, nil, _callbacks),
    do: issues

  def validate_optional_timeline_transition_application_report(
        issues,
        path,
        %{} = report,
        callbacks
      ),
      do: validate_timeline_transition_application_report(issues, path, report, callbacks)

  def validate_optional_timeline_transition_application_report(
        issues,
        path,
        _report,
        _callbacks
      ),
      do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_transition_application_summary_source(issues, path, summary),
    do:
      validate_optional_timeline_transition_application_summary_source(
        issues,
        path,
        summary,
        default_callbacks()
      )

  def validate_optional_timeline_transition_application_summary_source(
        issues,
        _path,
        nil,
        _callbacks
      ),
      do: issues

  def validate_optional_timeline_transition_application_summary_source(
        issues,
        path,
        %{} = summary,
        callbacks
      ),
      do: validate_timeline_transition_application_summary(issues, path, summary, callbacks)

  def validate_optional_timeline_transition_application_summary_source(
        issues,
        path,
        _summary,
        _callbacks
      ),
      do: [error(path, "must be an object") | issues]

  def validate_timeline_transition_selected_activity(issues, path, activity, callbacks) do
    OrbitalDynamics.Schema.TimelineTransitionSelectedActivityContracts.validate(
      issues,
      path,
      activity,
      Keyword.fetch!(callbacks, :validate_optional_activity_context),
      &OrbitalDynamics.Schema.TimelineIntegrityEvidenceContracts.validate/3
    )
  end

  def validate_timeline_transition_application_row(issues, path, row, callbacks) do
    OrbitalDynamics.Schema.TimelineTransitionApplicationRowContracts.validate(
      issues,
      path,
      row,
      Keyword.fetch!(callbacks, :validate_optional_lifecycle_transition),
      Keyword.fetch!(callbacks, :validate_optional_protection_decision),
      &OrbitalDynamics.Schema.TimelineIdentityCollisionContracts.validate_fields/3,
      &validate_selected_timeline_integrity_fields/3,
      &OrbitalDynamics.Schema.TimelineDiffRowContracts.validate/3
    )
    |> OrbitalDynamics.Schema.TimelineRevisionContracts.validate_optional(
      path <> ".timeline_revision",
      Map.get(row, "timeline_revision")
    )
  end

  def validate_selected_timeline_integrity_fields(issues, path, row) do
    OrbitalDynamics.Schema.TimelineSelectedIntegrityContracts.validate(
      issues,
      path,
      row
    )
  end

  def validate_optional_timeline_transition_application_row(issues, path, row),
    do:
      validate_optional_timeline_transition_application_row(
        issues,
        path,
        row,
        default_callbacks()
      )

  def validate_optional_timeline_transition_application_row(issues, _path, nil, _callbacks),
    do: issues

  def validate_optional_timeline_transition_application_row(issues, path, %{} = row, callbacks),
    do: validate_timeline_transition_application_row(issues, path, row, callbacks)

  def validate_optional_timeline_transition_application_row(issues, path, _row, _callbacks),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_integrity_source_row(issues, _path, nil), do: issues

  def validate_optional_timeline_integrity_source_row(issues, path, %{} = row),
    do:
      OrbitalDynamics.Schema.TimelineIntegrityReportContracts.validate_row(
        issues,
        path,
        row
      )

  def validate_optional_timeline_integrity_source_row(issues, path, _row),
    do: [error(path, "must be an object") | issues]

  defp timeline_report_model_limits do
    OrbitalDynamics.Timeline.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp default_callbacks do
    [
      validate_optional_activity_context:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_activity_context/4,
      validate_optional_lifecycle_transition:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_lifecycle_transition/4,
      validate_optional_protection_decision:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_protection_decision/4
    ]
  end
end
