defmodule OrbitalDynamics.CandidateRefresh.BuildWarnings do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.AcceptedStateEvidenceAuthority
  alias OrbitalDynamics.CandidateRefresh.BuildContext
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Assembly,
    as: OperationalFeedbackAssembly

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Input

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Provenance,
    as: OperationalFeedbackProvenance

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceReports

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter,
    as: ContactFilterReplaySummary

  alias OrbitalDynamics.CandidateRefresh.ResourceFiltering
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def build(context) do
    refresh = Map.fetch!(context, :refresh)
    candidates = Map.fetch!(context, :candidates)
    result_errors = Map.fetch!(context, :result_errors)
    contact_filter_report = Map.fetch!(context, :contact_filter_report)
    quality_gate_dropped_candidates = Map.fetch!(context, :quality_gate_dropped_candidates)

    candidate_scoped_quality_gate_dropped_candidates =
      Map.fetch!(context, :candidate_scoped_quality_gate_dropped_candidates)

    readiness_dropped_candidates = Map.fetch!(context, :readiness_dropped_candidates)

    candidate_scoped_readiness_dropped_candidates =
      Map.fetch!(context, :candidate_scoped_readiness_dropped_candidates)

    contact_allocation_resource_dropped_candidates =
      Map.fetch!(context, :contact_allocation_resource_dropped_candidates)

    allocation_dropped_candidates = Map.fetch!(context, :allocation_dropped_candidates)
    resource_filter_report = Map.fetch!(context, :resource_filter_report)
    refresh_budget_report = Map.fetch!(context, :refresh_budget_report)
    freshness_report = Map.fetch!(context, :freshness_report)

    accepted_state_evidence_authority =
      case Map.fetch(context, :accepted_state_evidence_authority) do
        {:ok, summary} -> summary
        :error -> BuildContext.accepted_state_evidence_authority(refresh)
      end

    invalid_operational_feedback_input? = Input.invalid?(refresh)
    invalid_operational_feedback_sections = Input.invalid_sections(refresh)

    operational_feedback_trust_boundary_status =
      operational_feedback_trust_boundary_status(refresh)

    operational_feedback_applied? = operational_feedback_applied?(refresh)

    []
    |> maybe_warn(candidates == [], "no refreshed candidate activities were generated")
    |> maybe_warn(result_errors != [], "study completed with propagation or event errors")
    |> maybe_warn(
      Map.get(refresh, "prior_candidate_activities", []) == [],
      "no prior candidates compared"
    )
    |> maybe_warn(
      Map.get(contact_filter_report, "suppressed_candidate_count", 0) > 0,
      "ground network filters suppressed refreshed contact candidates"
    )
    |> maybe_warn(
      allocation_dropped_candidates != [],
      "contact allocation excluded refreshed contact candidates"
    )
    |> maybe_warn(
      quality_gate_dropped_candidates != [],
      "unavailable-resource quality gates excluded explicitly scoped contact candidates"
    )
    |> maybe_warn(
      candidate_scoped_quality_gate_dropped_candidates != [],
      "blocked quality gates excluded exact source-artifact candidates"
    )
    |> maybe_warn(
      readiness_dropped_candidates != [],
      "operational readiness excluded explicitly scoped unavailable-resource contact candidates"
    )
    |> maybe_warn(
      candidate_scoped_readiness_dropped_candidates != [],
      "blocked operational readiness excluded exact source-artifact candidates"
    )
    |> maybe_warn(
      contact_allocation_resource_dropped_candidates != [],
      "contact allocation resource evidence excluded explicitly scoped contact candidates"
    )
    |> maybe_warn(
      Map.get(resource_filter_report, "suppressed_candidate_count", 0) > 0,
      "resource summary filters suppressed refreshed candidates"
    )
    |> maybe_warn(
      ResourceFiltering.summary_inputs_invalid_count(resource_filter_report) > 0,
      "resource summary inputs require operator review"
    )
    |> maybe_warn(
      source_resource_projection_report_invalid_input_count(refresh) > 0,
      "source resource projection reports include invalid inputs requiring review"
    )
    |> maybe_warn(
      source_resource_filter_report_invalid_resource_summary_input_count(refresh) > 0,
      "source resource filter reports include invalid resource summaries requiring review"
    )
    |> maybe_warn(
      source_contact_filter_report_invalid_contact_input_count(refresh) > 0,
      "source contact filter reports include invalid contact inputs requiring review"
    )
    |> maybe_warn(
      source_operational_timeline_report_integrity_issue_count(refresh) > 0,
      "source operational timeline reports include dependency or exclusivity integrity issues"
    )
    |> maybe_warn(
      Map.get(refresh_budget_report, "dropped_candidate_count", 0) > 0,
      "candidate refresh budget dropped candidate activities"
    )
    |> maybe_warn(
      Map.get(refresh_budget_report, "invalid_candidate_limit_policy") == true,
      "candidate refresh budget policy is invalid"
    )
    |> maybe_warn(
      Map.get(freshness_report, "status") == "stale",
      "candidate refresh freshness policy marked the snapshot, horizon, or state quality stale"
    )
    |> maybe_warn(
      Map.get(freshness_report, "status") == "unknown",
      "candidate refresh freshness could not be fully evaluated"
    )
    |> maybe_warn(
      AcceptedStateEvidenceAuthority.review_required?(accepted_state_evidence_authority),
      AcceptedStateEvidenceAuthority.warning_message()
    )
    |> maybe_warn(
      invalid_operational_feedback_input?,
      "operational feedback input is invalid"
    )
    |> maybe_warn(
      invalid_operational_feedback_sections != [],
      "operational feedback input is invalid"
    )
    |> maybe_warn(
      operational_feedback_trust_boundary_status == "missing" and
        not invalid_operational_feedback_input? and operational_feedback_applied?,
      "operational feedback was applied without a declared trust boundary"
    )
    |> Enum.reverse()
  end

  defp source_resource_projection_report_invalid_input_count(refresh) do
    source_report_warning_count(
      refresh,
      :source_resource_projection_reports,
      &resource_projection_report_invalid_input_count/1
    )
  end

  defp source_resource_filter_report_invalid_resource_summary_input_count(refresh) do
    source_report_warning_count(
      refresh,
      :source_resource_filter_reports,
      &SourceReportSummary.ResourceFilter.invalid_resource_summary_input_count/1
    )
  end

  defp source_contact_filter_report_invalid_contact_input_count(refresh) do
    source_report_warning_count(
      refresh,
      :source_contact_filter_reports,
      &ContactFilterReplaySummary.SourceReportFields.Report.invalid_contact_input_count/1
    )
  end

  defp source_operational_timeline_report_integrity_issue_count(refresh) do
    source_report_warning_count(
      refresh,
      :source_operational_timeline_reports,
      &SourceReportSummary.OperationalTimeline.operational_timeline_report_integrity_issue_count/1
    )
  end

  defp source_report_warning_count(refresh, source_key, count_fun) do
    refresh
    |> SourceReports.reports(source_key)
    |> Enum.map(fn {_path, report} -> report end)
    |> sum_report_count(count_fun)
  end

  defp resource_projection_report_invalid_input_count(report) do
    SourceReportSummary.ResourceProjection.resource_projection_report_invalid_activity_input_count(
      report
    ) +
      SourceReportSummary.ResourceProjection.resource_projection_report_invalid_resource_summary_input_count(
        report
      )
  end

  defp operational_feedback_trust_boundary_status(refresh) do
    case OperationalFeedbackProvenance.build(refresh) do
      %{"trust_boundary_status" => status} -> status
      _provenance -> nil
    end
  end

  defp operational_feedback_applied?(refresh) do
    refresh
    |> OperationalFeedbackAssembly.build()
    |> OperationalFeedback.data_keys()
    |> Kernel.!=([])
  end

  defp maybe_warn(warnings, true, message), do: [message | warnings]
  defp maybe_warn(warnings, false, _message), do: warnings
end
