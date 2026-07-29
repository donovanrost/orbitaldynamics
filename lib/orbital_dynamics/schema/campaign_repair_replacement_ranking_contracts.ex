defmodule OrbitalDynamics.Schema.CampaignRepairReplacementRankingContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ActivityIdentity, RepairActivityIdentity}
  alias OrbitalDynamics.Schema.CampaignRepairReplacementRankingVersion

  @model "greedy_repair_replacement_ranking"
  @selection_scope "viable_unique_candidates_within_repair_intent"
  @station_pressure_sources [
    "campaign_repair.source_contact_allocation_report.rows",
    "campaign_repair.source_station_calendar_report.affected_contacts"
  ]
  @contact_intent_pressure_statuses [
    "blocked_by_policy",
    "cadence_import_invalid",
    "cadence_import_missing",
    "invalid_activity_input"
  ]
  @penalty_fields [
    "schedule_churn_penalty",
    "schedule_move_penalty",
    "station_calendar_pressure_penalty",
    "contact_intent_pressure_penalty",
    "contact_contention_resolution_pressure_penalty",
    "link_capacity_pressure_penalty",
    "resource_projection_pressure_penalty"
  ]
  @required_row_fields [
    "rank",
    "candidate_id",
    "semantic_candidate_diff_match",
    "candidate_diff_priority",
    "candidate_score",
    "schedule_churn_s",
    "schedule_churn_penalty",
    "schedule_move_penalty",
    "station_calendar_pressure_penalty",
    "link_capacity_pressure_penalty",
    "resource_projection_pressure_penalty",
    "ranking_score",
    "selected"
  ]
  @current_handoff_fields [
    "source_activity_id",
    "source_timeline_id",
    "replacement_timeline_id",
    "timeline_link"
  ]
  @current_timeline_link_fields [
    "source_activity_id",
    "replacement_activity_id",
    "source_timeline_id",
    "replacement_timeline_id"
  ]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_at_least: 5,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_list: 4,
      expect_optional_non_negative_number: 4,
      expect_optional_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate_activities(issues, path, activities),
    do: validate_activities(issues, path, activities, [])

  def validate_activities(issues, path, activities, deltas)
      when is_list(activities) and is_list(deltas) do
    deltas_by_replacement_id =
      deltas
      |> Enum.filter(&is_map/1)
      |> Enum.group_by(&Map.get(&1, "replacement_activity_id"))

    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, index}, acc ->
      validate_activity(acc, "#{path}[#{index}]", activity, deltas_by_replacement_id)
    end)
  end

  def validate_activities(issues, _path, _activities, _deltas), do: issues

  defp validate_activity(issues, path, %{} = activity, deltas_by_replacement_id) do
    case Map.get(activity, "repair") do
      nil ->
        issues

      :null ->
        issues

      %{} = repair ->
        issues
        |> validate_repair(path <> ".repair", repair, activity)
        |> validate_current_delta_handoff(
          path <> ".repair",
          repair,
          activity,
          deltas_by_replacement_id
        )

      _value ->
        [error(path <> ".repair", "must be a map") | issues]
    end
  end

  defp validate_activity(issues, _path, _activity, _deltas_by_replacement_id), do: issues

  defp validate_current_delta_handoff(
         issues,
         path,
         repair,
         activity,
         deltas_by_replacement_id
       ) do
    rows = get_in(repair, ["replacement_ranking", "rows"])

    if CampaignRepairReplacementRankingVersion.current?(rows) do
      matching_deltas =
        deltas_by_replacement_id
        |> Map.get(activity_id(activity), [])
        |> Enum.filter(&(Map.get(&1, "activity_id") == Map.get(repair, "source_activity_id")))

      case matching_deltas do
        [%{} = delta] ->
          issues
          |> validate_current_delta_string(
            path <> ".action",
            repair,
            "action",
            delta,
            "repair_action",
            "must match the corresponding Repair delta repair_action"
          )
          |> validate_current_delta_string(
            path <> ".reason",
            repair,
            "reason",
            delta,
            "reason",
            "must match the corresponding Repair delta reason"
          )

        _missing_or_ambiguous_delta ->
          issues
      end
    else
      issues
    end
  end

  defp validate_current_delta_string(
         issues,
         path,
         repair,
         repair_field,
         delta,
         delta_field,
         message
       ) do
    case {Map.get(repair, repair_field), Map.get(delta, delta_field)} do
      {actual, expected} when is_binary(actual) and is_binary(expected) ->
        validate_equal(issues, path, actual, expected, message)

      _unreplayable ->
        issues
    end
  end

  defp validate_repair(issues, path, repair, activity) do
    case Map.get(repair, "replacement_ranking") do
      nil ->
        issues

      :null ->
        issues

      %{} = ranking ->
        validate_ranking(
          issues,
          path <> ".replacement_ranking",
          ranking,
          path,
          repair,
          activity
        )

      _value ->
        [error(path <> ".replacement_ranking", "must be a map") | issues]
    end
  end

  defp validate_ranking(issues, path, ranking, repair_path, repair, activity) do
    rows = Map.get(ranking, "rows")

    issues
    |> require_fields(path, ranking, [
      "model",
      "selection_scope",
      "selected_candidate_id",
      "evaluated_candidate_count",
      "rows",
      "global_optimization"
    ])
    |> expect_equal(path, ranking, "model", @model)
    |> expect_equal(path, ranking, "selection_scope", @selection_scope)
    |> expect_equal(path, ranking, "global_optimization", false)
    |> expect_non_negative_integer(path, ranking, "evaluated_candidate_count")
    |> expect_field_at_least(path, ranking, "evaluated_candidate_count", 1)
    |> expect_type(path, ranking, "rows", :list)
    |> validate_stable_ids(path, ranking, ["selected_candidate_id"])
    |> validate_rows(path <> ".rows", rows)
    |> validate_consistency(path, ranking, rows)
    |> validate_current_handoff(repair_path, repair, rows)
    |> validate_selected_handoff(path, ranking, repair_path, repair, activity)
  end

  defp validate_current_handoff(issues, repair_path, repair, rows) do
    if CampaignRepairReplacementRankingVersion.current?(rows) do
      timeline_link = Map.get(repair, "timeline_link")

      issues
      |> require_fields(repair_path, repair, @current_handoff_fields)
      |> validate_stable_ids(repair_path, repair, [
        "source_activity_id",
        "source_timeline_id",
        "replacement_timeline_id"
      ])
      |> expect_type(repair_path, repair, "timeline_link", :map)
      |> validate_current_timeline_link(repair_path <> ".timeline_link", timeline_link)
      |> validate_current_source_identity(repair_path, repair)
    else
      issues
    end
  end

  defp validate_current_timeline_link(issues, path, %{} = timeline_link) do
    issues
    |> require_fields(path, timeline_link, @current_timeline_link_fields)
    |> validate_stable_ids(path, timeline_link, @current_timeline_link_fields)
  end

  defp validate_current_timeline_link(issues, _path, _timeline_link), do: issues

  defp validate_current_source_identity(
         issues,
         repair_path,
         %{"source_activity_context" => %{} = source_context} = repair
       ) do
    identity = Map.get(source_context, "timeline_identity")
    identity_path = repair_path <> ".source_activity_context.timeline_identity"

    issues
    |> require_fields(repair_path <> ".source_activity_context", source_context, [
      "timeline_identity"
    ])
    |> expect_type(
      repair_path <> ".source_activity_context",
      source_context,
      "timeline_identity",
      :map
    )
    |> validate_current_source_timeline_identity(identity_path, identity, repair)
  end

  defp validate_current_source_identity(issues, _repair_path, _repair), do: issues

  defp validate_current_source_timeline_identity(issues, path, %{} = identity, repair) do
    issues
    |> require_fields(path, identity, ["activity_id", "timeline_id"])
    |> validate_stable_ids(path, identity, ["activity_id", "timeline_id"])
    |> validate_equal(
      path <> ".activity_id",
      Map.get(identity, "activity_id"),
      Map.get(repair, "source_activity_id"),
      "must match repair.source_activity_id"
    )
    |> validate_equal(
      path <> ".timeline_id",
      Map.get(identity, "timeline_id"),
      Map.get(repair, "source_timeline_id"),
      "must match repair.source_timeline_id"
    )
  end

  defp validate_current_source_timeline_identity(issues, _path, _identity, _repair),
    do: issues

  defp validate_selected_handoff(issues, path, ranking, repair_path, repair, activity) do
    activity_id = activity_id(activity)
    replacement_timeline_id = RepairActivityIdentity.timeline_id(activity)

    issues
    |> validate_equal(
      path <> ".selected_candidate_id",
      Map.get(ranking, "selected_candidate_id"),
      activity_id,
      "must equal enclosing repaired activity ID"
    )
    |> validate_optional_equal(
      repair_path <> ".replacement_timeline_id",
      repair,
      "replacement_timeline_id",
      replacement_timeline_id,
      "must equal enclosing repaired activity timeline ID"
    )
    |> validate_optional_timeline_link(
      repair_path <> ".timeline_link",
      Map.get(repair, "timeline_link"),
      %{
        "source_activity_id" => Map.get(repair, "source_activity_id"),
        "replacement_activity_id" => activity_id,
        "source_timeline_id" => Map.get(repair, "source_timeline_id"),
        "replacement_timeline_id" => replacement_timeline_id
      }
    )
    |> validate_current_selected_churn(ranking, repair_path, repair)
  end

  defp validate_current_selected_churn(issues, ranking, repair_path, repair) do
    rows = Map.get(ranking, "rows")

    if CampaignRepairReplacementRankingVersion.current?(rows) do
      selected_rows = Enum.filter(rows, &(Map.get(&1, "selected") == true))

      case {Map.get(repair, "schedule_churn_s"), selected_rows} do
        {actual, [%{"schedule_churn_s" => expected}]}
        when is_number(actual) and is_number(expected) ->
          validate_equal(
            issues,
            repair_path <> ".schedule_churn_s",
            actual,
            expected,
            "must match the selected replacement-ranking row schedule_churn_s"
          )

        _unreplayable ->
          issues
      end
    else
      issues
    end
  end

  defp activity_id(%{"id" => _id} = activity), do: ActivityIdentity.activity_id(activity)
  defp activity_id(_activity), do: nil

  defp validate_optional_timeline_link(issues, path, %{} = link, expected_fields) do
    Enum.reduce(expected_fields, issues, fn {field, expected}, acc ->
      validate_optional_equal(
        acc,
        path <> "." <> field,
        link,
        field,
        expected,
        "must match enclosing repair handoff identity"
      )
    end)
  end

  defp validate_optional_timeline_link(issues, _path, _link, _expected_fields), do: issues

  defp validate_optional_equal(issues, path, map, field, expected, message) do
    case Map.fetch(map, field) do
      {:ok, actual} when actual in [nil, :null] -> issues
      {:ok, actual} -> validate_equal(issues, path, actual, expected, message)
      :error -> issues
    end
  end

  defp validate_rows(issues, path, rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      validate_row(acc, "#{path}[#{index}]", row)
    end)
  end

  defp validate_rows(issues, _path, _rows), do: issues

  defp validate_row(issues, path, %{} = row) do
    issues
    |> require_fields(path, row, @required_row_fields)
    |> expect_non_negative_integer(path, row, "rank")
    |> expect_one_of(path, row, "candidate_diff_priority", [0, 1])
    |> expect_number(path, row, "candidate_score")
    |> expect_number(path, row, "schedule_churn_s")
    |> expect_field_at_least(path, row, "schedule_churn_s", 0.0)
    |> expect_number(path, row, "schedule_churn_penalty")
    |> expect_number(path, row, "schedule_move_penalty")
    |> expect_number(path, row, "station_calendar_pressure_penalty")
    |> expect_optional_number(path, row, "contact_intent_pressure_penalty")
    |> expect_optional_number(path, row, "contact_contention_resolution_pressure_penalty")
    |> expect_number(path, row, "link_capacity_pressure_penalty")
    |> expect_number(path, row, "resource_projection_pressure_penalty")
    |> expect_number(path, row, "ranking_score")
    |> expect_type(path, row, "semantic_candidate_diff_match", :boolean)
    |> expect_type(path, row, "selected", :boolean)
    |> validate_stable_ids(path, row, ["candidate_id"])
    |> expect_optional_list(path, row, "station_calendar_pressure_sources")
    |> validate_string_list_items(path, row, "station_calendar_pressure_sources")
    |> validate_station_pressure_sources(path, row)
    |> expect_optional_list(path, row, "contact_intent_pressure_statuses")
    |> validate_string_list_items(path, row, "contact_intent_pressure_statuses")
    |> validate_contact_intent_pressure_statuses(path, row)
    |> expect_optional_list(path, row, "contact_contention_resolution_group_ids")
    |> validate_string_list_items(path, row, "contact_contention_resolution_group_ids")
    |> validate_contact_contention_resolution_group_ids(path, row)
    |> expect_optional_non_negative_number(
      path,
      row,
      "link_capacity_pressure_required_downlink_mb"
    )
    |> expect_optional_non_negative_number(
      path,
      row,
      "link_capacity_pressure_selected_capacity_adjusted_throughput_mb"
    )
    |> expect_optional_non_negative_number(path, row, "link_capacity_pressure_shortfall_mb")
    |> validate_positive_optional_number(path, row, "link_capacity_pressure_shortfall_mb")
    |> expect_optional_list(path, row, "resource_projection_pressure_risk_indicators")
    |> validate_resource_risk_indicators(path, row)
    |> validate_candidate_diff_priority(path, row)
    |> validate_ranking_score(path, row)
    |> validate_pressure_evidence(path, row)
  end

  defp validate_row(issues, path, _row),
    do: [error(path, "must be a map") | issues]

  defp validate_station_pressure_sources(issues, path, row) do
    case Map.get(row, "station_calendar_pressure_sources") do
      sources when is_list(sources) and sources != [] ->
        cond do
          Enum.any?(sources, &(&1 not in @station_pressure_sources)) ->
            [
              error(
                path <> ".station_calendar_pressure_sources",
                "must contain only known station-pressure source paths"
              )
              | issues
            ]

          sources != sources |> Enum.uniq() |> Enum.sort() ->
            [
              error(
                path <> ".station_calendar_pressure_sources",
                "must be unique and lexically sorted"
              )
              | issues
            ]

          true ->
            issues
        end

      [] ->
        [
          error(
            path <> ".station_calendar_pressure_sources",
            "must be omitted instead of empty"
          )
          | issues
        ]

      _value ->
        issues
    end
  end

  defp validate_positive_optional_number(issues, path, row, field) do
    case Map.get(row, field) do
      value when is_number(value) and value <= 0.0 ->
        [error("#{path}.#{field}", "must be positive when present") | issues]

      _value ->
        issues
    end
  end

  defp validate_contact_intent_pressure_statuses(issues, path, row) do
    case Map.get(row, "contact_intent_pressure_statuses") do
      statuses when is_list(statuses) and statuses != [] ->
        cond do
          Enum.any?(statuses, &(&1 not in @contact_intent_pressure_statuses)) ->
            [
              error(
                path <> ".contact_intent_pressure_statuses",
                "must contain only known contact-intent pressure statuses"
              )
              | issues
            ]

          statuses != statuses |> Enum.uniq() |> Enum.sort() ->
            [
              error(
                path <> ".contact_intent_pressure_statuses",
                "must be unique and lexically sorted"
              )
              | issues
            ]

          true ->
            issues
        end

      [] ->
        [
          error(
            path <> ".contact_intent_pressure_statuses",
            "must be omitted instead of empty"
          )
          | issues
        ]

      _value ->
        issues
    end
  end

  defp validate_contact_contention_resolution_group_ids(issues, path, row) do
    case Map.get(row, "contact_contention_resolution_group_ids") do
      group_ids when is_list(group_ids) and group_ids != [] ->
        if group_ids == group_ids |> Enum.uniq() |> Enum.sort() do
          issues
        else
          [
            error(
              path <> ".contact_contention_resolution_group_ids",
              "must be unique and lexically sorted"
            )
            | issues
          ]
        end

      [] ->
        [
          error(
            path <> ".contact_contention_resolution_group_ids",
            "must be omitted instead of empty"
          )
          | issues
        ]

      _value ->
        issues
    end
  end

  defp validate_resource_risk_indicators(issues, path, row) do
    case Map.get(row, "resource_projection_pressure_risk_indicators") do
      indicators when is_list(indicators) and indicators != [] ->
        indicators
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {indicator, index}, acc ->
          validate_resource_risk_indicator(
            acc,
            "#{path}.resource_projection_pressure_risk_indicators[#{index}]",
            indicator,
            Map.get(row, "candidate_id")
          )
        end)

      [] ->
        [
          error(
            path <> ".resource_projection_pressure_risk_indicators",
            "must be omitted instead of empty"
          )
          | issues
        ]

      _value ->
        issues
    end
  end

  defp validate_resource_risk_indicator(issues, path, %{} = indicator, candidate_id) do
    issues
    |> require_fields(path, indicator, ["type", "severity", "reason", "spacecraft_id"])
    |> expect_type(path, indicator, "type", :binary)
    |> expect_type(path, indicator, "severity", :binary)
    |> expect_type(path, indicator, "reason", :binary)
    |> validate_stable_ids(path, indicator, ["candidate_id", "spacecraft_id"])
    |> validate_resource_risk_candidate_id(path, indicator, candidate_id)
    |> expect_optional_type(path, indicator, "resource_pressure_types", :list)
    |> validate_string_list_items(path, indicator, "resource_pressure_types")
  end

  defp validate_resource_risk_indicator(issues, path, _indicator, _candidate_id),
    do: [error(path, "must be a map") | issues]

  defp validate_resource_risk_candidate_id(issues, _path, indicator, _candidate_id)
       when not is_map_key(indicator, "candidate_id"),
       do: issues

  defp validate_resource_risk_candidate_id(issues, path, indicator, candidate_id),
    do: expect_equal(issues, path, indicator, "candidate_id", candidate_id)

  defp validate_candidate_diff_priority(issues, path, row) do
    expected_priority =
      case Map.get(row, "semantic_candidate_diff_match") do
        true -> 0
        false -> 1
        _value -> nil
      end

    if is_integer(expected_priority) and
         Map.get(row, "candidate_diff_priority") != expected_priority do
      [
        error(
          path <> ".candidate_diff_priority",
          "must equal 0 for a semantic candidate-diff match and 1 otherwise"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_ranking_score(issues, path, row) do
    values = [
      Map.get(row, "candidate_score") | Enum.map(@penalty_fields, &penalty_value(row, &1))
    ]

    ranking_score = Map.get(row, "ranking_score")

    if is_number(ranking_score) and Enum.all?(values, &is_number/1) do
      expected_score = Enum.sum(values)

      if abs(ranking_score - expected_score) <= 1.0e-9 do
        issues
      else
        [
          error(
            path <> ".ranking_score",
            "must equal candidate score plus all ranking penalties"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp penalty_value(row, field)
       when field in [
              "contact_intent_pressure_penalty",
              "contact_contention_resolution_pressure_penalty"
            ],
       do: Map.get(row, field, 0.0)

  defp penalty_value(row, field), do: Map.get(row, field)

  defp validate_pressure_evidence(issues, path, row) do
    issues
    |> require_nonzero_penalty_evidence(
      path,
      row,
      "station_calendar_pressure_penalty",
      "station_calendar_pressure_sources",
      &nonempty_list?/1
    )
    |> require_nonzero_penalty_evidence(
      path,
      row,
      "contact_intent_pressure_penalty",
      "contact_intent_pressure_statuses",
      &nonempty_list?/1
    )
    |> require_nonzero_penalty_evidence(
      path,
      row,
      "contact_contention_resolution_pressure_penalty",
      "contact_contention_resolution_group_ids",
      &nonempty_list?/1
    )
    |> require_nonzero_penalty_evidence(
      path,
      row,
      "link_capacity_pressure_penalty",
      "link_capacity_pressure_shortfall_mb",
      &positive_number?/1
    )
    |> require_nonzero_penalty_evidence(
      path,
      row,
      "resource_projection_pressure_penalty",
      "resource_projection_pressure_risk_indicators",
      &nonempty_list?/1
    )
  end

  defp require_nonzero_penalty_evidence(
         issues,
         path,
         row,
         penalty_field,
         evidence_field,
         evidence?
       ) do
    penalty = Map.get(row, penalty_field)

    if is_number(penalty) and penalty != 0 and not evidence?.(Map.get(row, evidence_field)) do
      [
        error(
          "#{path}.#{evidence_field}",
          "must be present when #{penalty_field} is nonzero"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp nonempty_list?(value), do: is_list(value) and value != []
  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp validate_consistency(issues, path, ranking, rows) when is_list(rows) do
    if Enum.all?(rows, &is_map/1) do
      candidate_ids = Enum.map(rows, &Map.get(&1, "candidate_id"))
      selected_rows = Enum.filter(rows, &(Map.get(&1, "selected") == true))
      expected_ranks = if rows == [], do: [], else: Enum.to_list(1..length(rows))

      issues
      |> validate_equal(
        path <> ".evaluated_candidate_count",
        Map.get(ranking, "evaluated_candidate_count"),
        length(rows),
        "must match replacement-ranking row count"
      )
      |> validate_equal(
        path <> ".rows",
        Enum.map(rows, &Map.get(&1, "rank")),
        expected_ranks,
        "must use sequential ranks in row order"
      )
      |> validate_equal(
        path <> ".rows",
        length(Enum.uniq(candidate_ids)),
        length(candidate_ids),
        "must contain unique candidate IDs"
      )
      |> validate_row_order(path, rows)
      |> validate_selected_candidate(path, ranking, selected_rows)
    else
      issues
    end
  end

  defp validate_consistency(issues, _path, _ranking, _rows), do: issues

  defp validate_row_order(issues, path, rows) do
    order_values =
      Enum.map(rows, &{Map.get(&1, "candidate_diff_priority"), Map.get(&1, "ranking_score")})

    if Enum.all?(order_values, fn {priority, score} ->
         is_integer(priority) and is_number(score)
       end) and not ordered_rows?(order_values) do
      [
        error(
          path <> ".rows",
          "must be ordered by candidate-diff priority ascending then ranking score descending"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp ordered_rows?(order_values) do
    order_values
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.all?(fn [{left_priority, left_score}, {right_priority, right_score}] ->
      left_priority < right_priority or
        (left_priority == right_priority and left_score >= right_score)
    end)
  end

  defp validate_selected_candidate(issues, path, ranking, [selected_row]) do
    issues
    |> validate_equal(
      path <> ".selected_candidate_id",
      Map.get(ranking, "selected_candidate_id"),
      Map.get(selected_row, "candidate_id"),
      "must match the only selected ranking row"
    )
    |> validate_equal(
      path <> ".rows",
      Map.get(selected_row, "rank"),
      1,
      "selected ranking row must have rank 1"
    )
  end

  defp validate_selected_candidate(issues, path, _ranking, _selected_rows) do
    [error(path <> ".rows", "must contain exactly one selected row") | issues]
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
