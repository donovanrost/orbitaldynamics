defmodule OrbitalDynamics.CampaignPlanner.OperatorReviewPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CadenceImportDirectPressureBranches,
    CandidateDiffPressureEvents,
    CommandWindowOperationalFeedback,
    ConstraintPressureBranches,
    ContactAllocationPressureFanout,
    ContactContentionPressureBranches,
    ContactFilterPressureBranches,
    ContactIntentPressureBranches,
    LinkCapacityPressureBranches,
    ManeuverReviewOperationalFeedback,
    ObjectiveSatisfactionPressureBranches,
    ObjectiveTradeoffPressureBranches,
    OperationalTimelinePressureEvents,
    OperatorReviewSourceReports,
    RealizedFeedbackPressureEvents,
    RefreshBudgetPressureEvents,
    RefreshFreshnessPressureEvents,
    ResourceFilterPressureBranches,
    ResourceProjectionPressureBranches,
    ReviewRowSources,
    ScoreTermPressureBranches,
    StationCalendarReviewRows,
    TimelineDiffPressureEventCallbacks,
    TimelineDiffPressureEvents,
    TimelineDiffReviewRows,
    ValueEncoding
  }

  def from_row(
        %{"review_type" => "objective_satisfaction_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.objective_satisfaction(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ObjectiveSatisfactionPressureBranches.branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  def from_row(
        %{"review_type" => "objective_tradeoff_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.objective_tradeoff(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ObjectiveTradeoffPressureBranches.branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  def from_row(
        %{"review_type" => "constraint_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.constraint(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ConstraintPressureBranches.branch("#{source_prefix}.#{source_suffix}", index)
  end

  def from_row(
        %{"review_type" => "timeline_diff_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = TimelineDiffReviewRows.source(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> timeline_diff_pressure_branch("#{source_prefix}.#{source_suffix}", index)
  end

  def from_row(
        %{"review_type" => "operational_timeline_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.operational_timeline(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> OperationalTimelinePressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  def from_row(
        %{"review_type" => "candidate_diff_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.candidate_diff(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> CandidateDiffPressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  def from_row(
        %{"review_type" => "refresh_budget_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.refresh_budget(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> RefreshBudgetPressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  def from_row(
        %{"review_type" => "freshness_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.freshness(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> RefreshFreshnessPressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  def from_row(
        %{"review_type" => "plan_delta_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = TimelineDiffReviewRows.plan_delta_source(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> timeline_diff_pressure_branch("#{source_prefix}.#{source_suffix}", index)
  end

  def from_row(
        %{"review_type" => "command_window_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.command_window(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> CommandWindowOperationalFeedback.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  def from_row(
        %{"review_type" => "maneuver_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.maneuver_review(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ManeuverReviewOperationalFeedback.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  def from_row(
        %{"review_type" => "realized_feedback"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.realized_feedback(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> RealizedFeedbackPressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  def from_row(
        %{"review_type" => "resource_projection_review"} = row,
        _index,
        policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.resource_projection(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ResourceProjectionPressureBranches.build(
      "#{source_prefix}.#{source_suffix}",
      policy
    )
  end

  def from_row(
        %{"review_type" => "link_capacity_review"} = row,
        _index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.link_capacity(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> Map.put_new("source_report", "operator_review_package")
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> LinkCapacityPressureBranches.build("#{source_prefix}.#{source_suffix}")
  end

  def from_row(
        %{"review_type" => "contact_allocation_review"} = row,
        _index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.contact_allocation(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> contact_allocation_pressure_branch("#{source_prefix}.#{source_suffix}")
  end

  def from_row(
        %{"review_type" => "contact_allocation_capacity_pack_review"} = row,
        _index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.contact_allocation_capacity_pack(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> CadenceImportDirectPressureBranches.capacity_pack_branches(
      "#{source_prefix}.#{source_suffix}"
    )
  end

  def from_row(
        %{"review_type" => "contact_intent_review"} = row,
        _index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.contact_intent(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ContactIntentPressureBranches.build("#{source_prefix}.#{source_suffix}")
  end

  def from_row(
        %{"review_type" => "station_calendar_review"} = row,
        _index,
        _policy,
        source_prefix
      ) do
    StationCalendarReviewRows.pressure_branches(
      row,
      OperatorReviewSourceReports.Rows.trust_boundary(row),
      source_prefix
    )
  end

  def from_row(
        %{"review_type" => "contact_contention_recommendation"} = row,
        _index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = contact_contention_recommendation_source(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> Map.put_new("review_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> contact_contention_resolution_pressure_branches("#{source_prefix}.#{source_suffix}")
  end

  def from_row(
        %{"review_type" => "contact_suppression"} = row,
        _index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.contact_suppression(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ContactFilterPressureBranches.build("#{source_prefix}.#{source_suffix}")
  end

  def from_row(
        %{"review_type" => "resource_suppression"} = row,
        _index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.resource_suppression(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ResourceFilterPressureBranches.build("#{source_prefix}.#{source_suffix}")
  end

  def from_row(
        %{"review_type" => "score_term_review"} = row,
        index,
        _policy,
        source_prefix
      ) do
    {source, source_suffix} = ReviewRowSources.score_term(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ScoreTermPressureBranches.branch("#{source_prefix}.#{source_suffix}", index)
  end

  def from_row(_row, _index, _policy, _source_prefix), do: []

  defp contact_contention_recommendation_source(%{"source_recommendation" => %{} = source})
       when map_size(source) > 0,
       do: {source, "source_recommendation"}

  defp contact_contention_recommendation_source(row),
    do: {row, "contact_contention_recommendation"}

  defp timeline_diff_pressure_branch(row, source_path, index) do
    TimelineDiffPressureEvents.pressure_branch(
      row,
      source_path,
      index,
      %{},
      TimelineDiffPressureEventCallbacks.callbacks()
    )
  end

  defp contact_allocation_pressure_branch(row, source_path) do
    ContactAllocationPressureFanout.branches(row, source_path)
  end

  defp contact_contention_resolution_pressure_branches(recommendation, source_path) do
    ContactContentionPressureBranches.resolution(recommendation, source_path)
  end
end
