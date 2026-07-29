defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CadenceImportValidation,
    DecisionSupportValidation,
    StableIdValidation
  }

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_type: 5,
      require_fields: 4
    ]

  @provenance_path "$.operational_feedback_provenance"
  @provenance_model "deterministic_merge_explicit_overrides_mission_state_overrides_prior_plan"
  @provenance_fields ~w(
    model
    merge_order
    input_keys
    effective_sources
    overridden_sources
    source_count
    sources
    explicit_request_override
  )
  @operational_feedback_fields ~w(
    contact_success_rate
    observation_success_rate
    image_quality_score
    image_quality_status
    image_quality_source
    cloud_cover_fraction
    blur_score
    maneuver_success_rate
    maneuver_execution_uncertainty
    command_success_rate
    station_throughput_factor
    downlink_demand_mb
    downlink_demand_sources
    downlink_demand_context
    target_priority_overrides
    resource_margin_overrides
    resource_availability_overrides
  )
  @source_provenance_fields ~w(
    source_plan_id
    source_planner
    source_plan_generated_at
    source_provenance
  )
  @recommendation_reasons %{
    "auto_approvable" => "best_expected_score_within_auto_approval_policy",
    "operator_review_required" => "best_expected_score_requiring_operator_review",
    "blocked_by_policy" => "all_branches_blocked_highest_score_reported_for_review"
  }
  @branch_comparison_feedback_fields [
    {"feedback_score_adjustment", "score_adjustment"},
    {"contact_success_factor", "contact_success_factor"},
    {"contact_success_factor_source", "contact_success_factor_source"},
    {"contact_success_factor_activity_source", "contact_success_factor_activity_source"},
    {"observation_success_factor", "observation_success_factor"},
    {"observation_success_factor_source", "observation_success_factor_source"},
    {"observation_success_factor_activity_source", "observation_success_factor_activity_source"},
    {"station_throughput_factor", "station_throughput_factor"},
    {"station_throughput_factor_source", "station_throughput_factor_source"},
    {"station_throughput_factor_activity_source", "station_throughput_factor_activity_source"}
  ]
  @branch_comparison_priority_target_fields [
    {"required", "required_target_ids"},
    {"satisfied", "satisfied_target_ids"},
    {"missed", "missed_target_ids"}
  ]
  @branch_comparison_priority_scalar_fields [
    {"priority_commitment_required_observation_count", "required_observation_count"},
    {"priority_commitment_planned_observation_count", "planned_observation_count"},
    {"priority_commitment_missing_observation_count", "missing_observation_count"},
    {"priority_commitment_ratio", "ratio"}
  ]
  @branch_comparison_downlink_fields [
    {"downlink_completion_required_contacts", "required_contacts"},
    {"downlink_completion_planned_contacts", "planned_contacts"},
    {"downlink_completion_planned_downlink_mb", "planned_downlink_mb"},
    {"downlink_completion_ratio", "ratio"}
  ]
  @branch_comparison_coverage_revisit_fields [
    {"coverage_observed_target_count", "coverage", "observed_target_count"},
    {"revisit_count", "revisit", "revisit_count"}
  ]
  @branch_comparison_resource_impact_fields [
    {"fuel_margin", "fuel_margin"},
    {"power_margin", "power_margin"},
    {"storage_margin", "storage_margin"},
    {"downlink_capacity_margin", "downlink_capacity_margin"},
    {"thermal_margin_c", "thermal_margin_c"},
    {"spacecraft_availability", "spacecraft_availability"},
    {"payload_availability", "payload_availability"},
    {"antenna_availability", "antenna_availability"},
    {"resource_score_adjustment", "score_adjustment"},
    {"fuel_preservation_mode", "fuel_preservation_mode"}
  ]
  @branch_comparison_resource_projection_minimum_fields [
    {"projected_storage_margin", "projected_storage_margin"},
    {"projected_downlink_margin", "projected_downlink_margin"},
    {"projected_power_margin", "projected_power_margin"}
  ]
  @branch_comparison_resource_projection_maximum_fields [
    {"projected_storage_overflow_mb", "projected_storage_overflow_mb"},
    {"projected_downlink_shortfall_mb", "projected_downlink_shortfall_mb"},
    {"projected_battery_overuse_wh", "projected_battery_overuse_wh"},
    {"storage_limited_downlinked_mb", "storage_limited_downlinked_mb"},
    {"unused_downlink_capacity_mb", "unused_downlink_capacity_mb"}
  ]
  @branch_comparison_resource_projection_peak_fields [
    {"resource_projection_peak_storage_overflow_mb", "storage_overflow_mb"},
    {"resource_projection_peak_downlink_shortfall_mb", "downlink_shortfall_mb"},
    {"resource_projection_peak_battery_overuse_wh", "battery_overuse_wh"},
    {"resource_projection_peak_unused_downlink_capacity_mb", "unused_downlink_capacity_mb"}
  ]
  @branch_comparison_resource_projection_availability_pairs [
    {"resource_projection_payload_unavailable_count",
     "resource_projection_payload_unavailable_spacecraft_ids", "payload_unavailable"},
    {"resource_projection_degraded_payload_unavailable_count",
     "resource_projection_degraded_payload_unavailable_spacecraft_ids",
     "spacecraft_degraded_payload_unavailable"},
    {"resource_projection_antenna_unavailable_count",
     "resource_projection_antenna_unavailable_spacecraft_ids", "antenna_unavailable"},
    {"resource_projection_activity_type_suppressed_count",
     "resource_projection_activity_type_suppressed_spacecraft_ids",
     "activity_type_suppressed_by_resource_summary"},
    {"resource_projection_activity_type_incompatible_count",
     "resource_projection_activity_type_incompatible_spacecraft_ids",
     "activity_type_incompatible_with_resource_summary"}
  ]
  @resource_projection_availability_pressure_types ~w(
    spacecraft_unavailable
    payload_unavailable
    spacecraft_degraded_payload_unavailable
    antenna_unavailable
    activity_type_suppressed_by_resource_summary
    activity_type_incompatible_with_resource_summary
  )
  @stable_id_regex ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def validate(issues, artifact) do
    issues
    |> StableIdValidation.validate_optional_stable_ids("$", artifact, ["source_repair_id"])
    |> validate_branch_metadata(artifact)
    |> validate_ranked_branch_eligibility(artifact)
    |> validate_recommended_branch_evidence(artifact)
    |> validate_branch_comparison_identity(artifact)
    |> validate_branch_comparison_score_evidence(artifact)
    |> validate_branch_comparison_operational_evidence(artifact)
    |> validate_branch_comparison_risk_classifications(artifact)
    |> validate_branch_comparison_resource_impacts(artifact)
    |> validate_branch_comparison_resource_projection_summary(artifact)
    |> validate_branch_comparison_resource_projection_aggregates(artifact)
    |> validate_branch_comparison_resource_projection_availability(artifact)
    |> validate_branch_comparison_resource_projection_peaks(artifact)
    |> validate_branch_comparison_feedback_evidence(artifact)
    |> validate_branch_comparison_priority_commitments(artifact)
    |> validate_branch_comparison_downlink_completion(artifact)
    |> validate_branch_comparison_coverage_and_revisit(artifact)
    |> validate_branch_comparison_repair_score_evidence(artifact)
    |> validate_branch_comparison_repair_link_selection_evidence(artifact)
    |> validate_branch_comparison_repair_constraint_evidence(artifact)
    |> validate_source_provenance(artifact)
    |> validate_optional_score_term_report(Map.get(artifact, "score_term_report"))
    |> validate_optional_objective_tradeoff_report(Map.get(artifact, "objective_tradeoff_report"))
    |> validate_optional_pareto_frontier_report(Map.get(artifact, "pareto_frontier_report"))
    |> validate_optional_cadence_import_manifest(Map.get(artifact, "cadence_import_manifest"))
    |> validate_optional_operational_feedback_provenance(artifact)
  end

  defp validate_branch_metadata(
         issues,
         %{"branches" => branches, "strategy_metadata" => %{} = metadata}
       )
       when is_list(branches) do
    issues =
      expect_equal(
        issues,
        "$.strategy_metadata",
        metadata,
        "branch_count",
        length(branches)
      )

    case Enum.filter(branches, &(is_map(&1) and Map.get(&1, "branch_id") == "baseline")) do
      [_baseline] ->
        expect_equal(
          issues,
          "$.strategy_metadata",
          metadata,
          "baseline_branch_id",
          "baseline"
        )

      _missing_or_ambiguous_baseline ->
        issues
    end
  end

  defp validate_branch_metadata(issues, _artifact), do: issues

  defp validate_ranked_branch_eligibility(
         issues,
         %{
           "branches" => branches,
           "recommendation" => %{"ranked_branch_ids" => ranked_branch_ids}
         }
       )
       when is_list(branches) and is_list(ranked_branch_ids) do
    if Enum.all?(branches, &valid_branch_rank_input?/1) and
         Enum.all?(ranked_branch_ids, &is_binary/1) do
      branch_ids = Enum.map(branches, &Map.fetch!(&1, "branch_id"))

      selectable_branch_ids =
        branches
        |> Enum.reject(&(&1["approval_status"] == "blocked_by_policy"))
        |> Enum.map(&Map.fetch!(&1, "branch_id"))

      expected_branch_ids =
        if selectable_branch_ids == [], do: branch_ids, else: selectable_branch_ids

      if ranked_branch_ids == expected_branch_ids do
        issues
      else
        [
          error(
            "$.recommendation.ranked_branch_ids",
            "must equal selectable branch IDs in enclosing branch order, falling back to all branch IDs when every branch is blocked"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_ranked_branch_eligibility(issues, _artifact), do: issues

  defp valid_branch_rank_input?(%{"branch_id" => id, "approval_status" => status}),
    do: is_binary(id) and is_binary(status)

  defp valid_branch_rank_input?(_branch), do: false

  defp validate_recommended_branch_evidence(
         issues,
         %{
           "branches" => branches,
           "recommendation" =>
             %{"recommended_branch_id" => recommended_branch_id} =
               recommendation
         }
       )
       when is_list(branches) and is_binary(recommended_branch_id) do
    case Enum.filter(
           branches,
           &(is_map(&1) and Map.get(&1, "branch_id") == recommended_branch_id)
         ) do
      [recommended_branch] ->
        issues
        |> validate_optional_copy(
          "$.recommendation.approval_status",
          recommendation,
          "approval_status",
          Map.get(recommended_branch, "approval_status"),
          "must match the recommended branch approval_status"
        )
        |> validate_optional_copy(
          "$.recommendation.risks_remaining",
          recommendation,
          "risks_remaining",
          Map.get(recommended_branch, "risk_indicators"),
          "must match the recommended branch risk_indicators"
        )
        |> validate_optional_copy(
          "$.recommendation.requires_approval",
          recommendation,
          "requires_approval",
          Map.get(recommended_branch, "approval_requirements"),
          "must match the recommended branch approval_requirements"
        )
        |> validate_recommendation_reason(recommendation, recommended_branch)

      _missing_or_ambiguous_branch ->
        issues
    end
  end

  defp validate_recommended_branch_evidence(issues, _artifact), do: issues

  defp validate_recommendation_reason(issues, recommendation, recommended_branch) do
    case Map.fetch(@recommendation_reasons, Map.get(recommended_branch, "approval_status")) do
      {:ok, expected_reason} ->
        validate_optional_copy(
          issues,
          "$.recommendation.reason",
          recommendation,
          "reason",
          expected_reason,
          "must match the recommended branch approval_status reason"
        )

      :error ->
        issues
    end
  end

  defp validate_branch_comparison_identity(
         issues,
         %{
           "branches" => branches,
           "recommendation" => %{} = recommendation,
           "branch_comparison_report" => %{"rows" => rows} = report
         }
       )
       when is_list(branches) and is_list(rows) do
    issues =
      validate_optional_copy(
        issues,
        "$.branch_comparison_report.recommended_branch_id",
        report,
        "recommended_branch_id",
        Map.get(recommendation, "recommended_branch_id"),
        "must match the enclosing CampaignStrategy recommendation"
      )

    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) do
      branch_ids = Enum.map(branches, &Map.fetch!(&1, "branch_id"))
      report_branch_ids = Enum.map(rows, &Map.fetch!(&1, "branch_id"))

      if report_branch_ids == branch_ids do
        issues
      else
        [
          error(
            "$.branch_comparison_report.rows",
            "branch_id values must match enclosing CampaignStrategy branches in order"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_branch_comparison_identity(issues, _artifact), do: issues

  defp branch_id_input?(%{"branch_id" => branch_id}), do: is_binary(branch_id)
  defp branch_id_input?(_row), do: false

  defp validate_branch_comparison_score_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_score_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_score_evidence(issues, _artifact), do: issues

  defp validate_branch_comparison_score_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    score_terms = Map.get(branch, "score_terms", %{})

    issues
    |> validate_optional_copy(
      path <> ".score",
      row,
      "score",
      Map.get(branch, "score"),
      "must match the enclosing branch score"
    )
    |> validate_optional_copy(
      path <> ".raw_score",
      row,
      "raw_score",
      Map.get(score_terms, "raw_score"),
      "must match the enclosing branch score_terms.raw_score"
    )
    |> validate_optional_copy(
      path <> ".branch_probability",
      row,
      "branch_probability",
      Map.get(branch, "probability"),
      "must match the enclosing branch probability"
    )
    |> validate_optional_copy(
      path <> ".expected_score",
      row,
      "expected_score",
      Map.get(score_terms, "expected_score", Map.get(branch, "score")),
      "must match the enclosing branch expected score"
    )
    |> validate_optional_copy(
      path <> ".score_terms",
      row,
      "score_terms",
      score_terms,
      "must match the enclosing branch score_terms"
    )
  end

  defp validate_branch_comparison_operational_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_operational_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_operational_evidence(issues, _artifact), do: issues

  defp validate_branch_comparison_operational_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"

    issues
    |> validate_optional_copy(
      path <> ".approval_status",
      row,
      "approval_status",
      Map.get(branch, "approval_status"),
      "must match the enclosing branch approval_status"
    )
    |> validate_optional_copy(
      path <> ".risk_count",
      row,
      "risk_count",
      list_length(Map.get(branch, "risk_indicators")),
      "must match the enclosing branch risk_indicators count"
    )
    |> validate_optional_copy(
      path <> ".approval_requirement_count",
      row,
      "approval_requirement_count",
      list_length(Map.get(branch, "approval_requirements")),
      "must match the enclosing branch approval_requirements count"
    )
    |> validate_optional_copy(
      path <> ".candidate_activity_count",
      row,
      "candidate_activity_count",
      nested_list_length(Map.get(branch, "candidate_plan"), "strategic_additions"),
      "must match the enclosing branch strategic_additions count"
    )
    |> validate_optional_copy(
      path <> ".repair_delta_count",
      row,
      "repair_delta_count",
      nested_list_length(Map.get(branch, "repair_result"), "deltas"),
      "must match the enclosing branch repair deltas count"
    )
  end

  defp list_length(values) when is_list(values), do: length(values)
  defp list_length(_values), do: nil

  defp nested_list_length(%{} = container, field),
    do: container |> Map.get(field, []) |> list_length()

  defp nested_list_length(_container, _field), do: nil

  defp validate_branch_comparison_risk_classifications(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_risk_classification_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_risk_classifications(issues, _artifact), do: issues

  defp validate_branch_comparison_risk_classification_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    risk_indicators = Map.get(branch, "risk_indicators", [])
    feedback_adjustments = map_value(branch, "feedback_adjustments")
    resource_impacts = map_value(branch, "resource_impacts")

    issues
    |> validate_optional_copy(
      path <> ".risk_types",
      row,
      "risk_types",
      branch_risk_types(risk_indicators),
      "must match the enclosing branch risk indicator types"
    )
    |> validate_optional_copy(
      path <> ".high_risk_types",
      row,
      "high_risk_types",
      branch_risk_types(risk_indicators, "high"),
      "must match the enclosing branch high-severity risk indicator types"
    )
    |> validate_optional_copy(
      path <> ".feedback_risk_types",
      row,
      "feedback_risk_types",
      feedback_adjustments |> Map.get("risk_indicators", []) |> risk_type_values(),
      "must match the enclosing branch feedback risk indicator types"
    )
    |> validate_optional_copy(
      path <> ".resource_risk_types",
      row,
      "resource_risk_types",
      resource_impacts
      |> Map.get("risk_indicators", [])
      |> risk_type_values()
      |> Enum.sort(),
      "must match the enclosing branch resource risk indicator types"
    )
  end

  defp branch_risk_types(risk_indicators, severity \\ nil) do
    risk_indicators
    |> list_maps()
    |> Enum.filter(fn risk -> is_nil(severity) or Map.get(risk, "severity") == severity end)
    |> risk_type_values()
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp risk_type_values(risk_indicators) do
    risk_indicators
    |> list_maps()
    |> Enum.map(&Map.get(&1, "type"))
    |> Enum.reject(&is_nil/1)
  end

  defp list_maps(values) when is_list(values), do: Enum.filter(values, &is_map/1)
  defp list_maps(_values), do: []

  defp validate_branch_comparison_resource_impacts(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_impact_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_impacts(issues, _artifact), do: issues

  defp validate_branch_comparison_resource_impact_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    resource_impacts = map_value(branch, "resource_impacts")

    Enum.reduce(
      @branch_comparison_resource_impact_fields,
      issues,
      fn {row_field, source_field}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          Map.get(resource_impacts, source_field),
          "must match the enclosing branch resource_impacts.#{source_field}"
        )
      end
    )
  end

  defp validate_branch_comparison_resource_projection_summary(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_projection_summary_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_projection_summary(issues, _artifact), do: issues

  defp validate_branch_comparison_resource_projection_summary_row(
         issues,
         branch,
         row,
         index
       ) do
    case Map.get(branch, "resource_projection_report") do
      %{"projected_resources" => resource_rows} = report
      when is_list(resource_rows) and resource_rows != [] ->
        path = "$.branch_comparison_report.rows[#{index}]"

        issues
        |> validate_optional_copy(
          path <> ".resource_projection_spacecraft_count",
          row,
          "resource_projection_spacecraft_count",
          length(resource_rows),
          "must match the enclosing branch resource projection spacecraft count"
        )
        |> validate_optional_copy(
          path <> ".resource_projection_flow_count",
          row,
          "resource_projection_flow_count",
          resource_projection_flow_count(resource_rows),
          "must match the enclosing branch resource projection flow count"
        )
        |> validate_optional_copy(
          path <> ".resource_projection_warning_count",
          row,
          "resource_projection_warning_count",
          report |> Map.get("warnings", []) |> list_length(),
          "must match the enclosing branch resource projection warning count"
        )
        |> validate_optional_copy(
          path <> ".resource_source_quality_counts",
          row,
          "resource_source_quality_counts",
          Map.get(report, "resource_source_quality_counts"),
          "must match the enclosing branch resource projection source-quality counts"
        )
        |> validate_optional_copy(
          path <> ".resource_trust_boundary_status_counts",
          row,
          "resource_trust_boundary_status_counts",
          Map.get(report, "resource_trust_boundary_status_counts"),
          "must match the enclosing branch resource projection trust-boundary counts"
        )

      _report ->
        issues
    end
  end

  defp resource_projection_flow_count(resource_rows) do
    resource_rows
    |> resource_projection_flow_rows()
    |> length()
  end

  defp resource_projection_flow_rows(resource_rows) do
    resource_rows
    |> Enum.flat_map(fn
      %{"activity_resource_flow" => flows} when is_list(flows) -> flows
      _row -> []
    end)
  end

  defp validate_branch_comparison_resource_projection_aggregates(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_projection_aggregate_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_projection_aggregates(issues, _artifact), do: issues

  defp validate_branch_comparison_resource_projection_aggregate_row(
         issues,
         branch,
         row,
         index
       ) do
    case Map.get(branch, "resource_projection_report") do
      %{"projected_resources" => resource_rows}
      when is_list(resource_rows) and resource_rows != [] ->
        path = "$.branch_comparison_report.rows[#{index}]"

        issues
        |> validate_resource_projection_aggregate_fields(
          path,
          row,
          resource_rows,
          @branch_comparison_resource_projection_minimum_fields,
          &minimum_present/2
        )
        |> validate_resource_projection_aggregate_fields(
          path,
          row,
          resource_rows,
          @branch_comparison_resource_projection_maximum_fields,
          &maximum_present/2
        )
        |> validate_optional_copy(
          path <> ".projected_storage_remaining_mb",
          row,
          "projected_storage_remaining_mb",
          minimum_projected_remaining(
            resource_rows,
            "projected_storage_remaining_mb",
            "storage_capacity_mb",
            "projected_storage_used_mb"
          ),
          "must match the enclosing branch projected storage remaining aggregate"
        )
        |> validate_optional_copy(
          path <> ".projected_downlink_remaining_mb",
          row,
          "projected_downlink_remaining_mb",
          minimum_projected_remaining(
            resource_rows,
            "projected_downlink_remaining_mb",
            "downlink_capacity_mb",
            "estimated_downlink_mb"
          ),
          "must match the enclosing branch projected downlink remaining aggregate"
        )

      _report ->
        issues
    end
  end

  defp validate_resource_projection_aggregate_fields(
         issues,
         path,
         row,
         resource_rows,
         fields,
         aggregate
       ) do
    Enum.reduce(fields, issues, fn {row_field, source_field}, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{row_field}",
        row,
        row_field,
        aggregate.(resource_rows, source_field),
        "must match the enclosing branch resource projection #{source_field} aggregate"
      )
    end)
  end

  defp minimum_present(rows, field) do
    rows
    |> Enum.map(&map_field(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp maximum_present(rows, field) do
    rows
    |> Enum.map(&map_field(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp minimum_projected_remaining(rows, remaining_field, capacity_field, used_or_demand_field) do
    rows
    |> Enum.flat_map(fn row ->
      remaining = map_field(row, remaining_field)
      capacity = map_field(row, capacity_field)
      used_or_demand = map_field(row, used_or_demand_field)

      cond do
        is_number(remaining) ->
          [remaining]

        is_number(capacity) and is_number(used_or_demand) ->
          [max(capacity - used_or_demand, 0.0)]

        true ->
          []
      end
    end)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp map_field(%{} = map, field), do: Map.get(map, field)
  defp map_field(_value, _field), do: nil

  defp validate_branch_comparison_resource_projection_availability(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_projection_availability_row(
          acc,
          branch,
          row,
          index
        )
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_projection_availability(issues, _artifact),
    do: issues

  defp validate_branch_comparison_resource_projection_availability_row(
         issues,
         branch,
         row,
         index
       ) do
    case Map.get(branch, "resource_projection_report") do
      %{"projected_resources" => resource_rows}
      when is_list(resource_rows) and resource_rows != [] ->
        path = "$.branch_comparison_report.rows[#{index}]"
        unavailable_ids = resource_projection_unavailable_spacecraft_ids(resource_rows)

        issues
        |> validate_optional_copy(
          path <> ".resource_projection_unavailable_spacecraft_count",
          row,
          "resource_projection_unavailable_spacecraft_count",
          length(unavailable_ids),
          "must match the enclosing branch unavailable spacecraft count"
        )
        |> validate_optional_copy(
          path <> ".resource_projection_unavailable_spacecraft_ids",
          row,
          "resource_projection_unavailable_spacecraft_ids",
          unavailable_ids,
          "must match the enclosing branch unavailable spacecraft IDs"
        )
        |> validate_resource_projection_availability_pairs(path, row, resource_rows)
        |> validate_optional_copy(
          path <> ".resource_projection_availability_pressure_types",
          row,
          "resource_projection_availability_pressure_types",
          resource_projection_availability_pressure_types(resource_rows),
          "must match the enclosing branch resource availability pressure types"
        )

      _report ->
        issues
    end
  end

  defp validate_resource_projection_availability_pairs(issues, path, row, resource_rows) do
    Enum.reduce(
      @branch_comparison_resource_projection_availability_pairs,
      issues,
      fn {count_field, ids_field, pressure_type}, acc ->
        ids =
          resource_projection_availability_pressure_spacecraft_ids(resource_rows, pressure_type)

        acc
        |> validate_optional_copy(
          path <> ".#{count_field}",
          row,
          count_field,
          length(ids),
          "must match the enclosing branch #{pressure_type} spacecraft count"
        )
        |> validate_optional_copy(
          path <> ".#{ids_field}",
          row,
          ids_field,
          ids,
          "must match the enclosing branch #{pressure_type} spacecraft IDs"
        )
      end
    )
  end

  defp resource_projection_unavailable_spacecraft_ids(resource_rows) do
    resource_rows
    |> Enum.filter(&(map_field(&1, "spacecraft_available") == false))
    |> Enum.map(&map_field(&1, "spacecraft_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_projection_availability_pressure_spacecraft_ids(resource_rows, pressure_type) do
    resource_rows
    |> Enum.filter(fn resource_row ->
      pressure_type in List.wrap(map_field(resource_row, "resource_pressure_types"))
    end)
    |> Enum.map(fn resource_row ->
      map_field(resource_row, "spacecraft_id") || map_field(resource_row, "scenario_id")
    end)
    |> Enum.filter(&stable_id_string?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_projection_availability_pressure_types(resource_rows) do
    resource_rows
    |> Enum.flat_map(&(map_field(&1, "resource_pressure_types") |> List.wrap()))
    |> Enum.filter(&(&1 in @resource_projection_availability_pressure_types))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stable_id_string?(value),
    do: is_binary(value) and value != "" and Regex.match?(@stable_id_regex, value)

  defp validate_branch_comparison_resource_projection_peaks(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_projection_peak_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_projection_peaks(issues, _artifact), do: issues

  defp validate_branch_comparison_resource_projection_peak_row(issues, branch, row, index) do
    case Map.get(branch, "resource_projection_report") do
      %{"projected_resources" => resource_rows}
      when is_list(resource_rows) and resource_rows != [] ->
        validate_resource_projection_aggregate_fields(
          issues,
          "$.branch_comparison_report.rows[#{index}]",
          row,
          resource_projection_flow_rows(resource_rows),
          @branch_comparison_resource_projection_peak_fields,
          &maximum_present/2
        )

      _report ->
        issues
    end
  end

  defp validate_branch_comparison_feedback_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_feedback_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_feedback_evidence(issues, _artifact), do: issues

  defp validate_branch_comparison_feedback_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    feedback_adjustments = map_value(branch, "feedback_adjustments")

    Enum.reduce(@branch_comparison_feedback_fields, issues, fn {row_field, source_field}, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{row_field}",
        row,
        row_field,
        Map.get(feedback_adjustments, source_field),
        "must match the enclosing branch feedback_adjustments.#{source_field}"
      )
    end)
  end

  defp validate_branch_comparison_priority_commitments(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_priority_commitment_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_priority_commitments(issues, _artifact), do: issues

  defp validate_branch_comparison_priority_commitment_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"

    priority_commitments =
      branch
      |> map_value("objective_satisfaction")
      |> map_value("priority_commitments")

    issues =
      Enum.reduce(
        @branch_comparison_priority_target_fields,
        issues,
        fn {kind, source_field}, acc ->
          target_ids = list_value(priority_commitments, source_field)
          count_field = "priority_commitment_#{kind}_target_count"
          ids_field = "priority_commitment_#{kind}_target_ids"

          acc
          |> validate_optional_copy(
            path <> ".#{count_field}",
            row,
            count_field,
            length(target_ids),
            "must match the enclosing branch #{source_field} count"
          )
          |> validate_optional_copy(
            path <> ".#{ids_field}",
            row,
            ids_field,
            target_ids,
            "must match the enclosing branch objective priority #{source_field}"
          )
        end
      )

    Enum.reduce(
      @branch_comparison_priority_scalar_fields,
      issues,
      fn {row_field, source_field}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          Map.get(priority_commitments, source_field),
          "must match the enclosing branch objective priority #{source_field}"
        )
      end
    )
  end

  defp list_value(%{} = container, field) do
    case Map.get(container, field, []) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp validate_branch_comparison_downlink_completion(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_downlink_completion_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_downlink_completion(issues, _artifact), do: issues

  defp validate_branch_comparison_downlink_completion_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"

    downlink_completion =
      branch
      |> map_value("objective_satisfaction")
      |> map_value("downlink_completion")

    Enum.reduce(@branch_comparison_downlink_fields, issues, fn {row_field, source_field}, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{row_field}",
        row,
        row_field,
        Map.get(downlink_completion, source_field),
        "must match the enclosing branch objective downlink_completion.#{source_field}"
      )
    end)
  end

  defp validate_branch_comparison_coverage_and_revisit(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_coverage_and_revisit_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_coverage_and_revisit(issues, _artifact), do: issues

  defp validate_branch_comparison_coverage_and_revisit_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    objective_satisfaction = map_value(branch, "objective_satisfaction")

    Enum.reduce(
      @branch_comparison_coverage_revisit_fields,
      issues,
      fn {row_field, group, source_field}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          objective_satisfaction |> map_value(group) |> Map.get(source_field),
          "must match the enclosing branch objective #{group}.#{source_field}"
        )
      end
    )
  end

  defp validate_branch_comparison_repair_score_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_repair_score_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_repair_score_evidence(issues, _artifact), do: issues

  defp validate_branch_comparison_repair_score_row(
         issues,
         %{"repair_result" => %{} = repair_result},
         row,
         index
       ) do
    path = "$.branch_comparison_report.rows[#{index}]"
    score_terms = map_value(repair_result, "score_terms")
    score_term_report = map_value(repair_result, "score_term_report")

    issues
    |> validate_optional_copy(
      path <> ".repair_score",
      row,
      "repair_score",
      Map.get(repair_result, "score"),
      "must match the enclosing branch repair score"
    )
    |> validate_optional_copy(
      path <> ".repair_score_term_count",
      row,
      "repair_score_term_count",
      Map.get(score_term_report, "row_count"),
      "must match the enclosing branch repair score_term_report.row_count"
    )
    |> validate_optional_copy(
      path <> ".repair_score_term_keys",
      row,
      "repair_score_term_keys",
      Map.get(score_term_report, "score_term_keys"),
      "must match the enclosing branch repair score_term_report.score_term_keys"
    )
    |> validate_optional_copy(
      path <> ".repair_activity_score",
      row,
      "repair_activity_score",
      Map.get(score_terms, "activity_score"),
      "must match the enclosing branch repair score_terms.activity_score"
    )
    |> validate_optional_copy(
      path <> ".repair_schedule_churn_penalty",
      row,
      "repair_schedule_churn_penalty",
      Map.get(score_terms, "schedule_churn_penalty"),
      "must match the enclosing branch repair score_terms.schedule_churn_penalty"
    )
    |> validate_optional_copy(
      path <> ".repair_schedule_move_penalty",
      row,
      "repair_schedule_move_penalty",
      Map.get(score_terms, "schedule_move_penalty"),
      "must match the enclosing branch repair score_terms.schedule_move_penalty"
    )
  end

  defp validate_branch_comparison_repair_score_row(issues, _branch, _row, _index),
    do: issues

  defp validate_branch_comparison_repair_link_selection_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_repair_link_selection_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_repair_link_selection_evidence(issues, _artifact),
    do: issues

  defp validate_branch_comparison_repair_link_selection_row(
         issues,
         %{"repair_result" => %{} = repair_result},
         row,
         index
       ) do
    path = "$.branch_comparison_report.rows[#{index}]"
    link_capacity_report = map_value(repair_result, "link_capacity_report")

    issues
    |> validate_optional_copy(
      path <> ".repair_link_contact_count",
      row,
      "repair_link_contact_count",
      Map.get(link_capacity_report, "contact_count"),
      "must match the enclosing branch repair link_capacity_report.contact_count"
    )
    |> validate_optional_copy(
      path <> ".repair_link_selected_contact_count",
      row,
      "repair_link_selected_contact_count",
      Map.get(link_capacity_report, "selected_contact_count"),
      "must match the enclosing branch repair link_capacity_report.selected_contact_count"
    )
    |> validate_optional_copy(
      path <> ".repair_link_selected_estimated_throughput_mb",
      row,
      "repair_link_selected_estimated_throughput_mb",
      Map.get(link_capacity_report, "selected_estimated_throughput_mb"),
      "must match the enclosing branch repair link_capacity_report.selected_estimated_throughput_mb"
    )
    |> validate_optional_copy(
      path <> ".repair_link_selected_capacity_adjusted_throughput_mb",
      row,
      "repair_link_selected_capacity_adjusted_throughput_mb",
      Map.get(link_capacity_report, "selected_capacity_adjusted_throughput_mb"),
      "must match the enclosing branch repair link_capacity_report.selected_capacity_adjusted_throughput_mb"
    )
  end

  defp validate_branch_comparison_repair_link_selection_row(
         issues,
         _branch,
         _row,
         _index
       ),
       do: issues

  defp validate_branch_comparison_repair_constraint_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_repair_constraint_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_repair_constraint_evidence(issues, _artifact),
    do: issues

  defp validate_branch_comparison_repair_constraint_row(
         issues,
         %{"repair_result" => %{} = repair_result},
         row,
         index
       ) do
    path = "$.branch_comparison_report.rows[#{index}]"
    constraint_report = map_value(repair_result, "constraint_report")

    issues
    |> validate_optional_copy(
      path <> ".repair_constraint_count",
      row,
      "repair_constraint_count",
      Map.get(constraint_report, "constraint_count"),
      "must match the enclosing branch repair constraint_report.constraint_count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_row_count",
      row,
      "repair_constraint_row_count",
      Map.get(constraint_report, "row_count"),
      "must match the enclosing branch repair constraint_report.row_count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_status",
      row,
      "repair_constraint_status",
      Map.get(constraint_report, "status"),
      "must match the enclosing branch repair constraint_report.status"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_pass_count",
      row,
      "repair_constraint_pass_count",
      constraint_status_count(constraint_report, "pass"),
      "must match the enclosing branch repair constraint pass count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_warning_count",
      row,
      "repair_constraint_warning_count",
      constraint_status_count(constraint_report, "warning"),
      "must match the enclosing branch repair constraint warning count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_fail_count",
      row,
      "repair_constraint_fail_count",
      constraint_status_count(constraint_report, "fail"),
      "must match the enclosing branch repair constraint fail count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_failed_ids",
      row,
      "repair_constraint_failed_ids",
      constraint_ids_for_status(constraint_report, "fail"),
      "must match the enclosing branch failed repair constraint IDs"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_warning_ids",
      row,
      "repair_constraint_warning_ids",
      constraint_ids_for_status(constraint_report, "warning"),
      "must match the enclosing branch warning repair constraint IDs"
    )
  end

  defp validate_branch_comparison_repair_constraint_row(issues, _branch, _row, _index),
    do: issues

  defp constraint_status_count(report, status) do
    report
    |> constraint_rows()
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  defp constraint_ids_for_status(report, status) do
    report
    |> constraint_rows()
    |> Enum.filter(&(Map.get(&1, "status") == status))
    |> Enum.map(&Map.get(&1, "constraint_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp constraint_rows(%{} = report) do
    case Map.get(report, "rows") do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp map_value(%{} = container, field) do
    case Map.get(container, field) do
      %{} = value -> value
      _value -> %{}
    end
  end

  defp validate_source_provenance(issues, artifact) do
    provenance = Map.get(artifact, "provenance")

    issues
    |> validate_optional_copy(
      "$.provenance.source_plan_id",
      provenance,
      "source_plan_id",
      Map.get(artifact, "source_plan_id"),
      "must match enclosing CampaignStrategy source_plan_id"
    )
    |> validate_operator_review_provenance(
      provenance,
      get_in(artifact, ["operator_review_package", "provenance"])
    )
    |> validate_optional_copy(
      "$.cadence_import_manifest.provenance.source_plan_id",
      get_in(artifact, ["cadence_import_manifest", "provenance"]),
      "source_plan_id",
      Map.get(artifact, "source_plan_id"),
      "must match enclosing CampaignStrategy source_plan_id"
    )
  end

  defp validate_operator_review_provenance(
         issues,
         %{} = provenance,
         %{} = review_provenance
       ) do
    Enum.reduce(@source_provenance_fields, issues, fn field, acc ->
      if Map.has_key?(provenance, field) and Map.has_key?(review_provenance, field) do
        validate_optional_copy(
          acc,
          "$.operator_review_package.provenance.#{field}",
          review_provenance,
          field,
          Map.get(provenance, field),
          "must match enclosing CampaignStrategy provenance.#{field}"
        )
      else
        acc
      end
    end)
  end

  defp validate_operator_review_provenance(issues, _provenance, _review_provenance),
    do: issues

  defp validate_optional_copy(issues, path, %{} = container, field, expected, message) do
    if Map.has_key?(container, field) and Map.get(container, field) != expected,
      do: [error(path, message) | issues],
      else: issues
  end

  defp validate_optional_copy(issues, _path, _container, _field, _expected, _message),
    do: issues

  defp validate_optional_score_term_report(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_score_term_report(issues, %{} = report) do
    DecisionSupportValidation.validate_score_term_report(
      issues,
      "$.score_term_report",
      report
    )
  end

  defp validate_optional_score_term_report(issues, _report),
    do: [error("$.score_term_report", "must be an object") | issues]

  defp validate_optional_objective_tradeoff_report(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_objective_tradeoff_report(issues, %{} = report) do
    DecisionSupportValidation.validate_objective_tradeoff_report(
      issues,
      "$.objective_tradeoff_report",
      report
    )
  end

  defp validate_optional_objective_tradeoff_report(issues, _report),
    do: [error("$.objective_tradeoff_report", "must be an object") | issues]

  defp validate_optional_pareto_frontier_report(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_pareto_frontier_report(issues, %{} = report) do
    DecisionSupportValidation.validate_pareto_frontier_report(
      issues,
      "$.pareto_frontier_report",
      report
    )
  end

  defp validate_optional_pareto_frontier_report(issues, _report),
    do: [error("$.pareto_frontier_report", "must be an object") | issues]

  defp validate_optional_cadence_import_manifest(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_cadence_import_manifest(issues, %{} = manifest) do
    CadenceImportValidation.validate_manifest_artifact(
      issues,
      "$.cadence_import_manifest",
      manifest
    )
  end

  defp validate_optional_cadence_import_manifest(issues, _manifest),
    do: [error("$.cadence_import_manifest", "must be an object") | issues]

  defp validate_optional_operational_feedback_provenance(issues, artifact) do
    case Map.get(artifact, "operational_feedback_provenance") do
      value when value in [nil, :null] ->
        issues

      %{} = provenance ->
        issues
        |> require_fields(@provenance_path, provenance, @provenance_fields)
        |> expect_equal(@provenance_path, provenance, "model", @provenance_model)
        |> expect_type(@provenance_path, provenance, "merge_order", :list)
        |> expect_type(@provenance_path, provenance, "input_keys", :list)
        |> expect_type(@provenance_path, provenance, "effective_sources", :map)
        |> expect_type(@provenance_path, provenance, "overridden_sources", :map)
        |> expect_type(@provenance_path, provenance, "source_count", :integer)
        |> expect_non_negative_integer(@provenance_path, provenance, "source_count")
        |> expect_type(@provenance_path, provenance, "sources", :list)
        |> expect_type(@provenance_path, provenance, "explicit_request_override", :boolean)
        |> validate_unique_string_list(
          "#{@provenance_path}.merge_order",
          provenance["merge_order"],
          false
        )
        |> validate_unique_string_list(
          "#{@provenance_path}.input_keys",
          provenance["input_keys"],
          true
        )
        |> validate_source_rows(provenance["sources"])
        |> validate_source_count(provenance)
        |> validate_source_resolution(provenance)
        |> validate_feedback_input_keys(provenance, artifact["operational_feedback"])

      _value ->
        [error(@provenance_path, "must be an object") | issues]
    end
  end

  defp validate_source_rows(issues, rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = row, index}, acc ->
        path = "#{@provenance_path}.sources[#{index}]"

        acc
        |> require_fields(path, row, ["source", "input_keys"])
        |> expect_type(path, row, "source", :binary)
        |> expect_type(path, row, "input_keys", :list)
        |> validate_unique_string_list("#{path}.input_keys", row["input_keys"], true)

      {_row, index}, acc ->
        [error("#{@provenance_path}.sources[#{index}]", "must be an object") | acc]
    end)
  end

  defp validate_source_rows(issues, _rows), do: issues

  defp validate_source_count(issues, %{"sources" => rows, "source_count" => count})
       when is_list(rows) and is_integer(count) do
    if count == length(rows) do
      issues
    else
      [error("#{@provenance_path}.source_count", "must equal sources row count") | issues]
    end
  end

  defp validate_source_count(issues, _provenance), do: issues

  defp validate_source_resolution(
         issues,
         %{
           "input_keys" => input_keys,
           "effective_sources" => effective_sources,
           "overridden_sources" => overridden_sources,
           "sources" => sources
         }
       )
       when is_list(input_keys) and is_map(effective_sources) and is_map(overridden_sources) and
              is_list(sources) do
    source_names =
      sources
      |> Enum.flat_map(fn
        %{"source" => source} when is_binary(source) -> [source]
        _row -> []
      end)
      |> MapSet.new()

    issues
    |> validate_effective_source_keys(input_keys, effective_sources)
    |> validate_string_source_map(
      "#{@provenance_path}.effective_sources",
      effective_sources,
      source_names
    )
    |> validate_string_source_list_map(
      "#{@provenance_path}.overridden_sources",
      overridden_sources,
      input_keys,
      source_names
    )
  end

  defp validate_source_resolution(issues, _provenance), do: issues

  defp validate_effective_source_keys(issues, input_keys, effective_sources) do
    if Enum.sort(Map.keys(effective_sources)) == input_keys do
      issues
    else
      [
        error(
          "#{@provenance_path}.effective_sources",
          "keys must equal sorted operational-feedback input keys"
        )
        | issues
      ]
    end
  end

  defp validate_string_source_map(issues, path, values, source_names) do
    Enum.reduce(values, issues, fn {key, value}, acc ->
      cond do
        not is_binary(key) ->
          [error(path, "keys must be strings") | acc]

        not is_binary(value) ->
          [error("#{path}.#{key}", "must be a string") | acc]

        not MapSet.member?(source_names, value) ->
          [error("#{path}.#{key}", "must reference a declared source") | acc]

        true ->
          acc
      end
    end)
  end

  defp validate_string_source_list_map(issues, path, values, input_keys, source_names) do
    input_key_set = MapSet.new(input_keys)

    Enum.reduce(values, issues, fn {key, source_values}, acc ->
      acc =
        if is_binary(key) and MapSet.member?(input_key_set, key) do
          acc
        else
          [error(path, "keys must reference operational-feedback input keys") | acc]
        end

      case source_values do
        values when is_list(values) ->
          values
          |> Enum.with_index()
          |> Enum.reduce(acc, fn {source, index}, nested_acc ->
            if is_binary(source) and MapSet.member?(source_names, source) do
              nested_acc
            else
              [error("#{path}.#{key}[#{index}]", "must reference a declared source") | nested_acc]
            end
          end)

        _value ->
          [error("#{path}.#{key}", "must be a list") | acc]
      end
    end)
  end

  defp validate_feedback_input_keys(issues, provenance, %{} = operational_feedback) do
    expected_input_keys =
      @operational_feedback_fields
      |> Enum.filter(fn field ->
        case Map.get(operational_feedback, field) do
          %{} = values -> map_size(values) > 0
          _value -> false
        end
      end)
      |> Enum.sort()

    if provenance["input_keys"] == expected_input_keys do
      issues
    else
      [
        error(
          "#{@provenance_path}.input_keys",
          "must equal nonempty operational-feedback field keys"
        )
        | issues
      ]
    end
  end

  defp validate_feedback_input_keys(issues, _provenance, _operational_feedback), do: issues

  defp validate_unique_string_list(issues, path, values, sorted?) when is_list(values) do
    issues =
      values
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {value, index}, acc ->
        if is_binary(value), do: acc, else: [error("#{path}[#{index}]", "must be a string") | acc]
      end)

    cond do
      Enum.uniq(values) != values -> [error(path, "must contain unique values") | issues]
      sorted? and Enum.sort(values) != values -> [error(path, "must be sorted") | issues]
      true -> issues
    end
  end

  defp validate_unique_string_list(issues, _path, _values, _sorted?), do: issues
end
