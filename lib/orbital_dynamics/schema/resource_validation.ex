defmodule OrbitalDynamics.Schema.ResourceValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, expect_optional_one_of: 5, require_fields: 4]

  def validate_artifact(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_registered_artifact(path, artifact, contract_name)
  end

  def validate_optional_resource_projection_report(issues, path, report),
    do:
      validate_optional_resource_projection_report(
        issues,
        path,
        report,
        default_callbacks()
      )

  def validate_optional_resource_projection_report(issues, _path, nil, _callbacks), do: issues

  def validate_optional_resource_projection_report(issues, path, %{} = report, callbacks),
    do: validate_resource_projection_report(issues, path, report, callbacks)

  def validate_optional_resource_projection_report(issues, path, _report, _callbacks),
    do: [error(path, "must be an object") | issues]

  def validate_optional_resource_projection_flow_summary(issues, path, summary),
    do:
      validate_optional_resource_projection_flow_summary(
        issues,
        path,
        summary,
        default_callbacks()
      )

  def validate_optional_resource_projection_flow_summary(issues, _path, nil, _callbacks),
    do: issues

  def validate_optional_resource_projection_flow_summary(
        issues,
        path,
        %{} = summary,
        callbacks
      ),
      do: validate_resource_projection_flow_summary(issues, path, summary, callbacks)

  def validate_optional_resource_projection_flow_summary(issues, path, _summary, _callbacks),
    do: [error(path, "must be an object") | issues]

  def validate_optional_resource_filter_summary(issues, _path, nil), do: issues

  def validate_optional_resource_filter_summary(issues, path, %{} = summary),
    do: validate_artifact(issues, path, summary, "resource_filter_summary.v1")

  def validate_optional_resource_filter_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_resource_projection_report(issues, path, report),
    do: validate_resource_projection_report(issues, path, report, default_callbacks())

  def validate_resource_projection_report(issues, path, report, callbacks) do
    OrbitalDynamics.Schema.ResourceProjectionReportContracts.validate(
      issues,
      path,
      report,
      resource_projection_report_models(),
      resource_projection_report_model_limits(),
      &OrbitalDynamics.Schema.ResourceProjectionAssumptionsContracts.validate_subsystem_model_assumptions/3,
      &validate_invalid_resource_summary_input/3,
      &validate_invalid_activity_input/3,
      fn child_issues, child_path, row ->
        validate_resource_projection_row(child_issues, child_path, row, callbacks)
      end,
      &OrbitalDynamics.Schema.ResourceProjectionReportCountContracts.validate/3
    )
  end

  def validate_resource_projection_flow_summary(issues, path, summary),
    do: validate_resource_projection_flow_summary(issues, path, summary, default_callbacks())

  def validate_resource_projection_flow_summary(issues, path, summary, callbacks) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryContracts.validate(
      issues,
      path,
      summary,
      resource_projection_report_model_limits(),
      &OrbitalDynamics.Schema.ResourceProjectionAssumptionsContracts.validate_subsystem_model_assumptions/3,
      &OrbitalDynamics.Schema.ResourceProjectionFlowProjectedResourceContracts.validate/3,
      fn child_issues, child_path, row ->
        validate_resource_projection_flow_row(child_issues, child_path, row, callbacks)
      end,
      &OrbitalDynamics.Schema.ResourceProjectionFlowSummaryCountContracts.validate/3
    )
  end

  def validate_resource_projection_row(issues, path, row, callbacks) do
    OrbitalDynamics.Schema.ResourceProjectionRowContracts.validate(
      issues,
      path,
      row,
      Keyword.fetch!(callbacks, :validate_approval_requirement),
      Keyword.fetch!(callbacks, :validate_policy_rule_match),
      &OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_source_window/4,
      Keyword.fetch!(callbacks, :validate_nested_id_match),
      fn child_issues, child_path, flow_row ->
        validate_resource_projection_flow_row(child_issues, child_path, flow_row, callbacks)
      end
    )
  end

  def validate_resource_projection_flow_row(issues, path, row, callbacks) do
    OrbitalDynamics.Schema.ResourceProjectionFlowRowContracts.validate(
      issues,
      path,
      row,
      &OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_source_window/4,
      Keyword.fetch!(callbacks, :validate_nested_id_match)
    )
  end

  def validate_optional_resource_filter_report(issues, _path, nil), do: issues

  def validate_optional_resource_filter_report(issues, path, %{} = report),
    do: validate_resource_filter_report(issues, path, report)

  def validate_optional_resource_filter_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_resource_filter_report(issues, path, report) do
    OrbitalDynamics.Schema.ResourceFilterReportContracts.validate(
      issues,
      path,
      report,
      &validate_invalid_resource_summary_input/3,
      &validate_suppressed_candidate/3
    )
  end

  def validate_suppressed_candidate(issues, path, candidate) do
    OrbitalDynamics.Schema.SuppressedCandidateContracts.validate(issues, path, candidate)
  end

  def validate_invalid_resource_summary_input(issues, path, row),
    do: validate_invalid_input(issues, path, row)

  def validate_invalid_activity_input(issues, path, row),
    do: validate_invalid_input(issues, path, row)

  def resource_projection_report_model_limits do
    OrbitalDynamics.ResourceProjection.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def resource_projection_report_models do
    [
      "thin_battery_handoff_resource_projection_fixture",
      "thin_campaign_selected_activity_resource_projection",
      "thin_repaired_activity_resource_projection",
      "thin_selected_activity_resource_projection",
      "thin_stale_derived_margin_resource_projection_fixture",
      "thin_strategy_branch_activity_resource_projection"
    ]
  end

  defp validate_registered_artifact(issues, path, artifact, "resource_projection_report.v1"),
    do: validate_resource_projection_report(issues, path, artifact)

  defp validate_registered_artifact(
         issues,
         path,
         artifact,
         "resource_projection_flow_summary.v1"
       ),
       do: validate_resource_projection_flow_summary(issues, path, artifact)

  defp validate_registered_artifact(issues, path, artifact, "resource_filter_report.v1"),
    do: validate_resource_filter_report(issues, path, artifact)

  defp validate_registered_artifact(issues, path, artifact, "resource_summary.v1"),
    do: OrbitalDynamics.Schema.ResourceSummaryContracts.validate(issues, path, artifact)

  defp validate_registered_artifact(issues, path, artifact, "resource_filter_summary.v1") do
    OrbitalDynamics.Schema.ResourceFilterSummaryContracts.validate(
      issues,
      path,
      artifact,
      OrbitalDynamics.Schema.ResourceFilterCapabilityContext.resource_filter_report_model_limits(),
      &validate_suppressed_candidate/3,
      &validate_invalid_resource_summary_input/3
    )
  end

  defp required_fields(contract_name) do
    [
      OrbitalDynamics.Schema.ResourceProjectionRegistryContracts,
      OrbitalDynamics.Schema.ResourceFilterRegistryContracts,
      OrbitalDynamics.Schema.ResourceSummaryRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end

  defp default_callbacks do
    [
      validate_approval_requirement:
        &OrbitalDynamics.Schema.PolicyValidation.validate_approval_requirement/3,
      validate_policy_rule_match: &OrbitalDynamics.Schema.PolicyValidation.validate_rule_match/3,
      validate_nested_id_match:
        &OrbitalDynamics.Schema.StableIdValidation.validate_nested_id_match/7
    ]
  end

  defp validate_invalid_input(issues, path, row) do
    expect_optional_one_of(issues, path, row, "review_status", [
      "operator_review_required",
      "review_required",
      "pending_operator_review",
      "ready_for_review"
    ])
  end
end
