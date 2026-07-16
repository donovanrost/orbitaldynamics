defmodule OrbitalDynamics.Schema.CandidateHandoffContracts do
  @moduledoc false

  @candidate_rejection_source_field_pairs [
    {"subject_id", "candidate_id"},
    {"candidate_id", "candidate_id"},
    {"activity_id", "activity_id"},
    {"timeline_id", "timeline_id"},
    {"activity_type", "activity_type"},
    {"operational_kind", "operational_kind"},
    {"source_window_id", "source_window_id"},
    {"source_window_type", "source_window_type"},
    {"candidate_rejection_status", "rejection_status"},
    {"candidate_rejection_reasons", "rejection_reasons"},
    {"primary_rejection_reason", "primary_rejection_reason"},
    {"candidate_rejection_reason_count", "reason_count"},
    {"reviewable", "reviewable"},
    {"violated_constraint", "violated_constraint"},
    {"required_margin", "required_margin"},
    {"actual_margin", "actual_margin"},
    {"activity_context", "activity_context"}
  ]
  @candidate_rejection_source_review_fields Enum.map(
                                              [
                                                "subject_id",
                                                "candidate_id",
                                                "activity_id",
                                                "timeline_id",
                                                "activity_type",
                                                "operational_kind",
                                                "source_window_id",
                                                "source_window_type",
                                                "required_operator_action",
                                                "candidate_rejection_status",
                                                "candidate_rejection_reasons",
                                                "primary_rejection_reason",
                                                "candidate_rejection_reason_count",
                                                "reviewable",
                                                "violated_constraint",
                                                "required_margin",
                                                "actual_margin",
                                                "activity_context",
                                                "source_candidate_rejection"
                                              ],
                                              &{&1, &1}
                                            )
  @candidate_diff_source_field_pairs [
    {"subject_id", "id"},
    {"activity_id", "id"},
    {"activity_type", "type"},
    {"scenario_id", "scenario_id"},
    {"target_id", "target_id"},
    {"source_target_id", "source_target_id"},
    {"source_target", "source_target"},
    {"target_latitude_deg", "target_latitude_deg"},
    {"target_longitude_deg", "target_longitude_deg"},
    {"target_minimum_elevation_deg", "target_minimum_elevation_deg"},
    {"target_priority", "target_priority"},
    {"target_priority_source", "target_priority_source"},
    {"target_priority_objective_ids", "target_priority_objective_ids"},
    {"target_priority_objective_type", "target_priority_objective_type"},
    {"ground_station_id", "ground_station_id"},
    {"direction", "direction"},
    {"source_window_id", "source_window_id"},
    {"source_window_type", "source_window_type"},
    {"starts_at_s", "starts_at_s"},
    {"ends_at_s", "ends_at_s"},
    {"invalidated_candidate_ids", "invalidated_candidate_ids"},
    {"replacement_candidate_id", "replacement_candidate_id"},
    {"invalidated_reason", "invalidated_reason"},
    {"semantic_change_details", "semantic_change_details"},
    {"candidate_diff_match_status", "candidate_diff_match_status"},
    {"candidate_diff_match_count", "candidate_diff_match_count"},
    {"semantic_match_status", "semantic_match_status"},
    {"semantic_match_candidate_count", "semantic_match_candidate_count"},
    {"semantic_match_candidate_ids", "semantic_match_candidate_ids"},
    {"candidate_budget_match_status", "candidate_budget_match_status"},
    {"candidate_budget_match_count", "candidate_budget_match_count"},
    {"budget_dropped_candidate_ids", "budget_dropped_candidate_ids"},
    {"invalid_prior_candidate_input", "invalid_prior_candidate_input"},
    {"invalid_prior_candidate_input_reason", "invalid_prior_candidate_input_reason"}
  ]
  @candidate_diff_source_review_fields Enum.map(
                                         [
                                           "subject_id",
                                           "activity_id",
                                           "activity_type",
                                           "scenario_id",
                                           "target_id",
                                           "source_target_id",
                                           "source_target",
                                           "target_latitude_deg",
                                           "target_longitude_deg",
                                           "target_minimum_elevation_deg",
                                           "target_priority",
                                           "target_priority_source",
                                           "target_priority_objective_ids",
                                           "target_priority_objective_type",
                                           "ground_station_id",
                                           "direction",
                                           "source_window_id",
                                           "source_window_type",
                                           "starts_at_s",
                                           "ends_at_s",
                                           "reason",
                                           "approval_status",
                                           "required_operator_action",
                                           "candidate_diff",
                                           "invalidated_candidate_id",
                                           "invalidated_candidate_ids",
                                           "replacement_candidate_id",
                                           "invalidated_reason",
                                           "semantic_change_reasons",
                                           "semantic_change_details",
                                           "changed_fields",
                                           "candidate_diff_changed_fields",
                                           "candidate_diff_changed_field_count",
                                           "candidate_diff_match_status",
                                           "candidate_diff_match_count",
                                           "semantic_match_status",
                                           "semantic_match_candidate_count",
                                           "semantic_match_candidate_ids",
                                           "candidate_budget_match_status",
                                           "candidate_budget_match_count",
                                           "budget_dropped_candidate_ids",
                                           "invalid_prior_candidate_input",
                                           "invalid_prior_candidate_input_reason",
                                           "source_candidate",
                                           "source_candidate_diff"
                                         ],
                                         &{&1, &1}
                                       )

  def validate_candidate_rejection_matches_source(
        issues,
        path,
        %{"source_candidate_rejection" => %{} = source_row} = row
      ) do
    if candidate_rejection_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @candidate_rejection_source_field_pairs,
        "source_candidate_rejection"
      )
    else
      issues
    end
  end

  def validate_candidate_rejection_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_candidate_rejection_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if candidate_rejection_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @candidate_rejection_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_candidate_rejection_matches(issues, _path, _row),
    do: issues

  def validate_candidate_diff_matches_source(
        issues,
        path,
        %{"source_candidate_diff" => %{} = source_row} = row
      ) do
    if candidate_diff_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @candidate_diff_source_field_pairs,
        "source_candidate_diff"
      )
    else
      issues
    end
  end

  def validate_candidate_diff_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_candidate_diff_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if candidate_diff_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @candidate_diff_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_candidate_diff_matches(issues, _path, _row), do: issues

  def candidate_rejection_handoff_row?(row) do
    Map.get(row, "review_type") == "candidate_rejection_review" or
      Map.get(row, "source_review_type") == "candidate_rejection_review" or
      Map.get(row, "import_action") == "review_candidate_rejection"
  end

  def candidate_diff_handoff_row?(row) do
    Map.get(row, "review_type") == "candidate_diff_review" or
      Map.get(row, "source_review_type") == "candidate_diff_review" or
      Map.get(row, "import_action") == "review_candidate_diff"
  end

  defp validate_source_pairs(issues, path, row, source_row, field_pairs, source_key) do
    Enum.reduce(field_pairs, issues, fn {row_field, source_field}, acc ->
      row_value = Map.get(row, row_field)
      source_value = Map.get(source_row, source_field)

      if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
        [error("#{path}.#{row_field}", "must match #{source_key}.#{source_field}") | acc]
      else
        acc
      end
    end)
  end

  defp validate_cadence_source_review_pairs(
         issues,
         path,
         row,
         source_review_row,
         field_pairs
       ) do
    Enum.reduce(field_pairs, issues, fn {source_field, row_field}, acc ->
      source_value = Map.get(source_review_row, source_field)
      row_value = Map.get(row, row_field)

      if not is_nil(source_value) and not is_nil(row_value) and source_value != row_value do
        [
          error(
            "#{path}.source_review_row.#{source_field}",
            "must match #{row_field} on Cadence import row"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
