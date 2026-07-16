defmodule OrbitalDynamics.Schema.OptimizationHandoffContracts do
  @moduledoc false

  @constraint_source_field_pairs [
    {"subject_id", "scenario_id"},
    {"scenario_id", "scenario_id"},
    {"constraint_id", "constraint_id"},
    {"metric", "metric"},
    {"operator", "operator"},
    {"threshold", "threshold"},
    {"value", "value"},
    {"score", "score"},
    {"violation_severity", "violation_severity"},
    {"constraint_status", "status"}
  ]
  @constraint_source_review_fields Enum.map(
                                     [
                                       "subject_id",
                                       "scenario_id",
                                       "branch_id",
                                       "constraint_id",
                                       "metric",
                                       "operator",
                                       "threshold",
                                       "value",
                                       "score",
                                       "violation_severity",
                                       "constraint_status",
                                       "approval_status",
                                       "required_operator_action",
                                       "reason",
                                       "source_constraint_row"
                                     ],
                                     &{&1, &1}
                                   )
  @objective_satisfaction_source_field_pairs [
    {"objective", "objective"},
    {"objective_status", "status"},
    {"target_id", "target_id"},
    {"required_count", "required_count"},
    {"candidate_count", "candidate_count"},
    {"selected_count", "selected_count"},
    {"satisfied_count", "satisfied_count"},
    {"candidate_target_ids", "candidate_target_ids"},
    {"selected_target_ids", "selected_target_ids"},
    {"selected_activity_ids", "selected_activity_ids"},
    {"selected_contact_ids", "selected_contact_ids"},
    {"required_downlink_mb", "required_downlink_mb"},
    {"candidate_downlink_mb", "candidate_downlink_mb"},
    {"selected_downlink_mb", "selected_downlink_mb"},
    {"satisfied_downlink_mb", "satisfied_downlink_mb"}
  ]
  @objective_satisfaction_source_review_fields Enum.map(
                                                 [
                                                   "subject_id",
                                                   "objective",
                                                   "objective_status",
                                                   "target_id",
                                                   "required_count",
                                                   "candidate_count",
                                                   "selected_count",
                                                   "satisfied_count",
                                                   "candidate_target_ids",
                                                   "selected_target_ids",
                                                   "selected_activity_ids",
                                                   "selected_contact_ids",
                                                   "required_downlink_mb",
                                                   "candidate_downlink_mb",
                                                   "selected_downlink_mb",
                                                   "satisfied_downlink_mb",
                                                   "approval_status",
                                                   "required_operator_action",
                                                   "reason",
                                                   "source_objective_satisfaction"
                                                 ],
                                                 &{&1, &1}
                                               )
  @score_term_source_field_pairs [
    {"subject_id", "id"},
    {"scenario_id", "scenario_id"},
    {"branch_id", "branch_id"},
    {"term_key", "term_key"},
    {"value", "value"},
    {"timeline_score", "timeline_score"},
    {"selected", "selected"}
  ]
  @score_term_source_review_fields Enum.map(
                                     [
                                       "subject_id",
                                       "scenario_id",
                                       "branch_id",
                                       "term_key",
                                       "value",
                                       "timeline_score",
                                       "selected",
                                       "approval_status",
                                       "required_operator_action",
                                       "reason",
                                       "source_score_term"
                                     ],
                                     &{&1, &1}
                                   )
  @objective_tradeoff_source_field_pairs [
    {"subject_id", "scenario_id"},
    {"scenario_id", "scenario_id"},
    {"branch_id", "branch_id"},
    {"score", "score"},
    {"score_delta_from_selected", "score_delta_from_selected"},
    {"activity_count", "activity_count"},
    {"selected_observation_count", "selected_observation_count"},
    {"selected_contact_count", "selected_contact_count"},
    {"score_terms", "score_terms"},
    {"activity_ids", "activity_ids"}
  ]
  @objective_tradeoff_source_review_fields Enum.map(
                                             [
                                               "subject_id",
                                               "scenario_id",
                                               "branch_id",
                                               "score",
                                               "score_delta_from_selected",
                                               "activity_count",
                                               "selected_observation_count",
                                               "selected_contact_count",
                                               "score_terms",
                                               "activity_ids",
                                               "approval_status",
                                               "required_operator_action",
                                               "reason",
                                               "source_objective_tradeoff"
                                             ],
                                             &{&1, &1}
                                           )

  def validate_constraint_matches_source(
        issues,
        path,
        %{"source_constraint_row" => %{} = source_row} = row
      ) do
    if constraint_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @constraint_source_field_pairs,
        "source_constraint_row"
      )
    else
      issues
    end
  end

  def validate_constraint_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_constraint_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if constraint_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @constraint_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_constraint_matches(issues, _path, _row), do: issues

  def validate_objective_satisfaction_matches_source(
        issues,
        path,
        %{"source_objective_satisfaction" => %{} = source_row} = row
      ) do
    if objective_satisfaction_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @objective_satisfaction_source_field_pairs,
        "source_objective_satisfaction"
      )
    else
      issues
    end
  end

  def validate_objective_satisfaction_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_objective_satisfaction_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if objective_satisfaction_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @objective_satisfaction_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_objective_satisfaction_matches(issues, _path, _row),
    do: issues

  def validate_score_term_matches_source(
        issues,
        path,
        %{"source_score_term" => %{} = source_row} = row
      ) do
    if score_term_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @score_term_source_field_pairs,
        "source_score_term"
      )
    else
      issues
    end
  end

  def validate_score_term_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_score_term_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if score_term_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @score_term_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_score_term_matches(issues, _path, _row), do: issues

  def validate_objective_tradeoff_matches_source(
        issues,
        path,
        %{"source_objective_tradeoff" => %{} = source_row} = row
      ) do
    if objective_tradeoff_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @objective_tradeoff_source_field_pairs,
        "source_objective_tradeoff"
      )
    else
      issues
    end
  end

  def validate_objective_tradeoff_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_objective_tradeoff_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if objective_tradeoff_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @objective_tradeoff_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_objective_tradeoff_matches(issues, _path, _row),
    do: issues

  def constraint_handoff_row?(row) do
    Map.get(row, "review_type") == "constraint_review" or
      Map.get(row, "source_review_type") == "constraint_review" or
      Map.get(row, "import_action") == "review_constraint"
  end

  def objective_satisfaction_handoff_row?(row) do
    Map.get(row, "review_type") == "objective_satisfaction_review" or
      Map.get(row, "source_review_type") == "objective_satisfaction_review" or
      Map.get(row, "import_action") == "review_objective_satisfaction"
  end

  def score_term_handoff_row?(row) do
    Map.get(row, "review_type") == "score_term_review" or
      Map.get(row, "source_review_type") == "score_term_review" or
      Map.get(row, "import_action") == "review_score_term"
  end

  def objective_tradeoff_handoff_row?(row) do
    Map.get(row, "review_type") == "objective_tradeoff_review" or
      Map.get(row, "source_review_type") == "objective_tradeoff_review" or
      Map.get(row, "import_action") == "review_objective_tradeoff"
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
