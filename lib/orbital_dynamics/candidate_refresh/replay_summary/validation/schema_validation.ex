defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SchemaValidation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.Common
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields

  def from_refresh(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_validation_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "schema_validation_report")

    validation_summary =
      branch_validation_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "schema_validation_report"]) ||
        %{}

    {summary_source, replay_scope} = replay_context(branch_validation_summary)

    summary(validation_summary, summary_source, replay_scope)
  end

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_validation_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "schema_validation_report")

    validation_summary =
      branch_validation_summary || Map.get(source_reports, "schema_validation_report", %{})

    {summary_source, replay_scope} = replay_context(branch_validation_summary)

    summary = summary(validation_summary, summary_source, replay_scope)

    %{
      "source_report_schema_validation_branch_local_validation_pressure" =>
        Map.get(summary, "branch_local_validation_pressure"),
      "source_report_schema_validation_branch_local_schema_error_pressure" =>
        Map.get(summary, "branch_local_schema_error_pressure"),
      "source_report_schema_validation_branch_local_schema_warning_pressure" =>
        Map.get(summary, "branch_local_schema_warning_pressure"),
      "source_report_schema_validation_branch_local_remediation_pressure" =>
        Map.get(summary, "branch_local_remediation_pressure")
    }
    |> Map.merge(SourceReportFields.schema_validation_fields(source_reports))
  end

  def summary(validation_summary, summary_source, replay_scope) do
    status_counts = Map.get(validation_summary, "status_counts", %{})
    validated_contract_counts = Map.get(validation_summary, "validated_contract_counts", %{})
    validation_mode_counts = Map.get(validation_summary, "validation_mode_counts", %{})
    remediation_action_counts = Map.get(validation_summary, "remediation_action_counts", %{})
    remediation_category_counts = Map.get(validation_summary, "remediation_category_counts", %{})
    remediation_path_counts = Map.get(validation_summary, "remediation_path_counts", %{})
    error_count = Common.summary_integer(validation_summary, "error_count")
    warning_count = Common.summary_integer(validation_summary, "warning_count")
    remediation_count = Common.summary_integer(validation_summary, "remediation_count")
    failed_status_count = Common.summary_integer(status_counts, "fail")
    error_status_count = Common.summary_integer(status_counts, "error")
    warning_status_count = Common.summary_integer(status_counts, "warning")

    remediation_map_pressure =
      map_size(remediation_action_counts) > 0 or map_size(remediation_category_counts) > 0 or
        map_size(remediation_path_counts) > 0

    schema_error_pressure = failed_status_count + error_status_count + error_count > 0
    schema_warning_pressure = warning_status_count + warning_count > 0
    remediation_pressure = remediation_count > 0 or remediation_map_pressure

    validation_map_pressure =
      map_size(status_counts) > 0 or map_size(validated_contract_counts) > 0 or
        map_size(validation_mode_counts) > 0

    validation_pressure =
      schema_error_pressure or schema_warning_pressure or remediation_pressure or
        validation_map_pressure

    %{
      "model" => "artifact_only_candidate_refresh_schema_validation_replay_summary",
      "source" => summary_source,
      "contract" =>
        Common.source_report_summary_contract(validation_summary, "schema_validation_report.v1"),
      "source_report_count" => Common.summary_integer(validation_summary, "count"),
      "source_report_row_count" => Common.summary_integer(validation_summary, "row_count"),
      "source_report_paths" => Map.get(validation_summary, "paths", []),
      "status_counts" => status_counts,
      "validated_contract_counts" => validated_contract_counts,
      "validation_mode_counts" => validation_mode_counts,
      "error_count" => error_count,
      "warning_count" => warning_count,
      "remediation_count" => remediation_count,
      "remediation_action_counts" => remediation_action_counts,
      "remediation_category_counts" => remediation_category_counts,
      "remediation_path_counts" => remediation_path_counts,
      "trust_boundary_status" => Map.get(validation_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(validation_summary, "trust_boundaries", []),
      "branch_local_validation_pressure" => validation_pressure,
      "branch_local_schema_error_pressure" => schema_error_pressure,
      "branch_local_schema_warning_pressure" => schema_warning_pressure,
      "branch_local_remediation_pressure" => remediation_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_schema_validation_replay_summary",
        "import_approval" => "not_granted_by_schema_validation_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Common.compact_map()
  end

  defp replay_context(branch_validation_summary) do
    if branch_validation_summary do
      {
        "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.schema_validation_report",
        "schema_validation_candidate_source_report_summary_only"
      }
    else
      {
        "candidate_refresh.source_report_provenance.schema_validation_report",
        "schema_validation_source_report_provenance_only"
      }
    end
  end
end
