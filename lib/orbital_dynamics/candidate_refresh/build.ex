defmodule OrbitalDynamics.CandidateRefresh.Build do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactIntent

  alias OrbitalDynamics.CandidateRefresh.{
    BuildAssumptions,
    BuildContext,
    BuildGroundNetwork,
    BuildOperationalFeedback,
    BuildProvenance,
    BuildRefreshId,
    BuildWarnings,
    CandidateActivities,
    CandidateActivityContext,
    CandidateActivityFields,
    CandidateBudget,
    CandidateDiffReport,
    ContactGate,
    ObjectiveMatching,
    RefreshedWindows,
    ResourceFiltering,
    SourceObjectives,
    SourceReportSummary.InputProvenance,
    SourceWindowLineage,
    UnavailableResourceCandidateFilter,
    ValueEncoding
  }

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Assembly,
    as: OperationalFeedbackAssembly

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Provenance,
    as: OperationalFeedbackProvenance

  alias OrbitalDynamics.{ResultSet, Validation}

  @schema_version 1

  def build(%ResultSet{} = result_set, opts \\ []) do
    raw_refresh = Keyword.fetch!(opts, :candidate_refresh)

    prepared_refresh = BuildContext.prepare_refresh_for_build(raw_refresh)
    accepted_state_evidence_authority = Map.fetch!(prepared_refresh, :evidence_authority)

    refresh =
      prepared_refresh
      |> Map.fetch!(:refresh)
      |> ValueEncoding.stringify_keys()

    generated_at = Keyword.get_lazy(opts, :generated_at, &DateTime.utc_now/0)
    policy = Map.get(refresh, "scoring_policy", %{})
    constraints = Map.get(refresh, "constraints", %{})

    {event_results, invalid_observation_lighting} =
      case RefreshedWindows.admit_event_results(result_set.event_results) do
        {:ok, event_results, invalid_observation_lighting} ->
          {RefreshedWindows.canonical_event_results(event_results), invalid_observation_lighting}

        {:error, {:invalid_observation_lighting, _reason}} ->
          {[], RefreshedWindows.empty_invalid_observation_lighting()}
      end

    windows =
      RefreshedWindows.refreshed_windows(
        event_results,
        CandidateActivityFields.event_timing_keys()
      )

    {resource_summaries, resource_filter_summaries} =
      ResourceFiltering.summary_inputs(refresh, &OperationalFeedbackAssembly.build/1)

    raw_candidates =
      event_results
      |> CandidateActivities.build(
        refresh,
        constraints,
        policy,
        &OperationalFeedbackAssembly.build/1,
        &SourceObjectives.objectives/1,
        &BuildGroundNetwork.build/1,
        invalid_observation_lighting
      )
      |> Enum.sort_by(&{&1["scenario_id"], &1["starts_at_s"], &1["id"]})

    {contact_candidates, contact_filter_report} =
      ContactGate.filter_candidates(raw_candidates, refresh, &BuildGroundNetwork.build/1)

    {contact_candidates, quality_gate_dropped_candidates,
     candidate_scoped_quality_gate_dropped_candidates, readiness_dropped_candidates,
     candidate_scoped_readiness_dropped_candidates,
     contact_allocation_resource_dropped_candidates, candidate_rejection_report} =
      UnavailableResourceCandidateFilter.apply(contact_candidates, refresh)

    {candidates, resource_filter_report} =
      ResourceFiltering.apply_filters(
        contact_candidates,
        refresh,
        resource_summaries,
        resource_filter_summaries,
        &ObjectiveMatching.spacecraft_identity_by_scenario/1
      )

    contact_allocation_report =
      ContactGate.allocation_report(
        candidates,
        refresh,
        contact_filter_report,
        &BuildGroundNetwork.build/1
      )

    {candidates, allocation_dropped_candidates} =
      ContactGate.apply_allocation(candidates, contact_allocation_report)

    {candidates, budget_dropped_candidates, refresh_budget_report} =
      CandidateBudget.apply(candidates, refresh)

    candidates = CandidateActivityContext.attach(candidates)

    invalidated_candidates =
      CandidateDiffReport.invalidated_candidates(
        refresh,
        candidates,
        CandidateDiffReport.mark_dropped_candidates(
          quality_gate_dropped_candidates,
          "dropped_by_quality_gate_unavailable_resource"
        ) ++
          CandidateDiffReport.mark_dropped_candidates(
            candidate_scoped_quality_gate_dropped_candidates,
            "dropped_by_candidate_scoped_quality_gate"
          ) ++
          CandidateDiffReport.mark_dropped_candidates(
            allocation_dropped_candidates,
            "dropped_by_contact_allocation"
          ) ++
          CandidateDiffReport.mark_dropped_candidates(
            readiness_dropped_candidates,
            "dropped_by_operational_readiness_unavailable_resource"
          ) ++
          CandidateDiffReport.mark_dropped_candidates(
            candidate_scoped_readiness_dropped_candidates,
            "dropped_by_candidate_scoped_operational_readiness"
          ) ++
          CandidateDiffReport.mark_dropped_candidates(
            contact_allocation_resource_dropped_candidates,
            "dropped_by_contact_allocation_unavailable_resource"
          ) ++
          CandidateDiffReport.mark_dropped_candidates(
            budget_dropped_candidates,
            "dropped_by_candidate_budget"
          )
      )

    candidate_diff_report =
      CandidateDiffReport.report(
        refresh,
        candidates,
        invalidated_candidates
      )

    freshness_report =
      BuildContext.freshness_report(
        refresh,
        generated_at,
        &model_limits/0,
        &ValueEncoding.numeric_value/1
      )

    %{
      "schema_version" => @schema_version,
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "generated_at" => DateTime.to_iso8601(generated_at),
      "planner" => "OrbitalDynamics.CandidateRefresh.V1",
      "refresh_id" =>
        BuildRefreshId.build(
          refresh,
          result_set.study_id,
          &BuildGroundNetwork.build/1,
          &SourceObjectives.objectives/1
        ),
      "study_id" => ValueEncoding.encode_value(result_set.study_id),
      "snapshot_id" => BuildContext.snapshot_id(refresh),
      "current_epoch_s" => BuildContext.current_epoch_s(refresh, &ValueEncoding.numeric_value/1),
      "remaining_horizon" =>
        BuildContext.remaining_horizon(refresh, &ValueEncoding.numeric_value/1),
      "accepted_planning_state" =>
        BuildContext.accepted_planning_state_ref(refresh, accepted_state_evidence_authority),
      "refreshed_windows" => windows,
      "candidate_activities" => candidates,
      "contact_intents" =>
        ContactIntent.from_activities(candidates,
          approval_policy: Map.get(refresh, "approval_policy")
        ),
      "contact_filter_report" => contact_filter_report,
      "resource_summaries" => resource_summaries,
      "resource_filter_report" => resource_filter_report,
      "refresh_budget_report" => refresh_budget_report,
      "candidate_diff_report" => candidate_diff_report,
      "freshness_report" => freshness_report,
      "invalidated_candidates" => invalidated_candidates,
      "contact_allocation_report" => contact_allocation_report,
      "validation_records" => Validation.records_for_result_set(result_set),
      "warnings" =>
        BuildWarnings.build(%{
          refresh: refresh,
          candidates: candidates,
          result_errors: result_set.errors,
          contact_filter_report: contact_filter_report,
          quality_gate_dropped_candidates: quality_gate_dropped_candidates,
          candidate_scoped_quality_gate_dropped_candidates:
            candidate_scoped_quality_gate_dropped_candidates,
          readiness_dropped_candidates: readiness_dropped_candidates,
          candidate_scoped_readiness_dropped_candidates:
            candidate_scoped_readiness_dropped_candidates,
          contact_allocation_resource_dropped_candidates:
            contact_allocation_resource_dropped_candidates,
          allocation_dropped_candidates: allocation_dropped_candidates,
          resource_filter_report: resource_filter_report,
          refresh_budget_report: refresh_budget_report,
          freshness_report: freshness_report,
          accepted_state_evidence_authority: accepted_state_evidence_authority
        }),
      "model_limits" => model_limits(),
      "assumptions" =>
        BuildAssumptions.build(
          refresh,
          result_set.assumptions
        ),
      "provenance" =>
        BuildProvenance.build(
          refresh,
          result_set.metadata,
          &OperationalFeedbackProvenance.build/1,
          &InputProvenance.build/1,
          accepted_state_evidence_authority
        ),
      "source_window_lineage" => SourceWindowLineage.build(candidates)
    }
    |> maybe_put_candidate_rejection_report(candidate_rejection_report)
    |> BuildOperationalFeedback.maybe_put(refresh, &OperationalFeedbackAssembly.build/1)
  end

  defp maybe_put_candidate_rejection_report(artifact, nil), do: artifact

  defp maybe_put_candidate_rejection_report(artifact, report),
    do: Map.put(artifact, "candidate_rejection_report", report)

  defp model_limits do
    OrbitalDynamics.CandidateRefresh.ModelLimits.strings()
  end
end
