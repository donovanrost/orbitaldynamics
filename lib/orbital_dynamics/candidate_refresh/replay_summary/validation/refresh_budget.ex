defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.RefreshBudget do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.Common
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields

  def from_refresh(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_budget_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "refresh_budget_report")

    budget_summary =
      branch_budget_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "refresh_budget_report"]) ||
        %{}

    {summary_source, replay_scope} = replay_context(branch_budget_summary)

    summary(budget_summary, summary_source, replay_scope)
  end

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_budget_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "refresh_budget_report")

    budget_summary =
      branch_budget_summary || Map.get(source_reports, "refresh_budget_report", %{})

    {summary_source, replay_scope} = replay_context(branch_budget_summary)

    summary = summary(budget_summary, summary_source, replay_scope)

    %{
      "source_report_refresh_budget_branch_local_budget_pressure" =>
        Map.get(summary, "branch_local_budget_pressure"),
      "source_report_refresh_budget_branch_local_dropped_candidate_pressure" =>
        Map.get(summary, "branch_local_dropped_candidate_pressure"),
      "source_report_refresh_budget_branch_local_invalid_limit_pressure" =>
        Map.get(summary, "branch_local_invalid_limit_pressure"),
      "source_report_refresh_budget_branch_local_candidate_limit_applied" =>
        Map.get(summary, "branch_local_candidate_limit_applied")
    }
    |> Map.merge(SourceReportFields.refresh_budget_fields(source_reports))
  end

  def summary(budget_summary, summary_source, replay_scope) do
    input_candidate_count = Common.summary_integer(budget_summary, "input_candidate_count")
    kept_candidate_count = Common.summary_integer(budget_summary, "kept_candidate_count")
    dropped_candidate_count = Common.summary_integer(budget_summary, "dropped_candidate_count")

    invalid_candidate_limit_policy_count =
      Common.summary_integer(budget_summary, "invalid_candidate_limit_policy_count")

    invalid_candidate_limit_policy_reason_counts =
      Map.get(budget_summary, "invalid_candidate_limit_policy_reason_counts", %{})

    kept_candidate_ids = Map.get(budget_summary, "kept_candidate_ids", [])
    dropped_candidate_ids = Map.get(budget_summary, "dropped_candidate_ids", [])

    dropped_candidate_pressure = dropped_candidate_count > 0 or dropped_candidate_ids != []

    invalid_limit_pressure =
      invalid_candidate_limit_policy_count > 0 or
        map_size(invalid_candidate_limit_policy_reason_counts) > 0

    candidate_limit_applied =
      dropped_candidate_pressure or
        (input_candidate_count > 0 and kept_candidate_count < input_candidate_count)

    budget_pressure =
      dropped_candidate_pressure or invalid_limit_pressure or candidate_limit_applied

    %{
      "model" => "artifact_only_candidate_refresh_refresh_budget_replay_summary",
      "source" => summary_source,
      "contract" =>
        Common.source_report_summary_contract(budget_summary, "refresh_budget_report.v1"),
      "source_report_count" => Common.summary_integer(budget_summary, "count"),
      "source_report_row_count" => Common.summary_integer(budget_summary, "row_count"),
      "source_report_paths" => Map.get(budget_summary, "paths", []),
      "input_candidate_count" => input_candidate_count,
      "kept_candidate_count" => kept_candidate_count,
      "dropped_candidate_count" => dropped_candidate_count,
      "invalid_candidate_limit_policy_count" => invalid_candidate_limit_policy_count,
      "invalid_candidate_limit_policy_reason_counts" =>
        invalid_candidate_limit_policy_reason_counts,
      "kept_candidate_ids" => kept_candidate_ids,
      "dropped_candidate_ids" => dropped_candidate_ids,
      "trust_boundary_status" => Map.get(budget_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(budget_summary, "trust_boundaries", []),
      "branch_local_budget_pressure" => budget_pressure,
      "branch_local_dropped_candidate_pressure" => dropped_candidate_pressure,
      "branch_local_invalid_limit_pressure" => invalid_limit_pressure,
      "branch_local_candidate_limit_applied" => candidate_limit_applied,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_refresh_budget_replay_summary",
        "import_approval" => "not_granted_by_refresh_budget_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Common.compact_map()
  end

  defp replay_context(branch_budget_summary) do
    if branch_budget_summary do
      {
        "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.refresh_budget_report",
        "refresh_budget_candidate_source_report_summary_only"
      }
    else
      {
        "candidate_refresh.source_report_provenance.refresh_budget_report",
        "refresh_budget_source_report_provenance_only"
      }
    end
  end
end
