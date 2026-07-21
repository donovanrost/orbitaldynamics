defmodule OrbitalDynamics.Schema.CampaignPlanScoreContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_numeric_map: 3, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_type: 5,
      require_fields: 4
    ]

  alias OrbitalDynamics.CampaignPlanner.DownlinkActivityNormalization
  alias OrbitalDynamics.Schema.{ActivityContracts, StableIdValidation}

  @required_aggregate_terms ~w(activity_score activity_count_penalty)
  @required_count_terms ~w(selected_observation_count selected_contact_count)
  @required_component_terms ~w(target_value contact_value eclipse_penalty)
  @optional_aggregate_terms ~w(
    downlink_completion_score
    timeline_precondition_pressure_penalty
    resource_projection_pressure_penalty
  )

  def validate(issues, artifact) when is_map(artifact) do
    timelines = Map.get(artifact, "ranked_timelines")
    scoring_policy = scoring_policy(artifact)

    issues
    |> validate_rows("$.ranked_timelines", timelines, fn acc, path, timeline ->
      validate_timeline(acc, path, timeline, scoring_policy)
    end)
    |> validate_timeline_order(timelines)
    |> validate_score_term_report(timelines, Map.get(artifact, "score_term_report"))
  end

  defp validate_timeline(issues, path, timeline, scoring_policy) do
    score_terms = Map.get(timeline, "score_terms")

    issues
    |> require_fields(path, timeline, [
      "scenario_id",
      "score",
      "score_terms",
      "activity_count",
      "activities"
    ])
    |> StableIdValidation.validate_stable_ids(path, timeline, ["scenario_id"])
    |> expect_number(path, timeline, "score")
    |> expect_type(path, timeline, "score_terms", :map)
    |> require_score_terms(path, score_terms)
    |> validate_selection_count_term_shapes(path, score_terms)
    |> validate_numeric_map(path <> ".score_terms", score_terms)
    |> expect_non_negative_integer(path, timeline, "activity_count")
    |> expect_type(path, timeline, "activities", :list)
    |> validate_rows(
      path <> ".activities",
      Map.get(timeline, "activities"),
      &ActivityContracts.validate/3
    )
    |> validate_activity_count(path, timeline)
    |> validate_timeline_score(path, timeline)
    |> validate_timeline_score_evidence(path, timeline, scoring_policy)
  end

  defp require_score_terms(issues, path, score_terms) when is_map(score_terms),
    do:
      require_fields(
        issues,
        path <> ".score_terms",
        score_terms,
        @required_aggregate_terms ++ @required_count_terms ++ @required_component_terms
      )

  defp require_score_terms(issues, _path, _score_terms), do: issues

  defp validate_selection_count_term_shapes(issues, path, score_terms)
       when is_map(score_terms) do
    Enum.reduce(@required_count_terms, issues, fn term, acc ->
      expect_non_negative_integer(acc, path <> ".score_terms", score_terms, term)
    end)
  end

  defp validate_selection_count_term_shapes(issues, _path, _score_terms), do: issues

  defp validate_activity_count(issues, path, %{
         "activity_count" => activity_count,
         "activities" => activities
       })
       when is_integer(activity_count) and is_list(activities) do
    validate_equal(
      issues,
      path <> ".activity_count",
      activity_count,
      length(activities),
      "must equal activities count"
    )
  end

  defp validate_activity_count(issues, _path, _timeline), do: issues

  defp validate_timeline_score(
         issues,
         path,
         %{"score" => score, "score_terms" => score_terms}
       )
       when is_number(score) and is_map(score_terms) do
    if aggregate_terms_valid?(score_terms) do
      expected_score =
        (@required_aggregate_terms ++ @optional_aggregate_terms)
        |> Enum.map(&Map.get(score_terms, &1, 0.0))
        |> Enum.sum()

      validate_number_equal(
        issues,
        path <> ".score",
        score,
        expected_score,
        "must equal aggregate score terms"
      )
    else
      issues
    end
  end

  defp validate_timeline_score(issues, _path, _timeline), do: issues

  defp validate_timeline_score_evidence(issues, path, timeline, scoring_policy) do
    issues
    |> validate_activity_score_evidence(path, timeline)
    |> validate_activity_count_penalty_evidence(path, timeline, scoring_policy)
    |> validate_selection_count_evidence(path, timeline)
    |> validate_component_score_evidence(path, timeline)
  end

  defp validate_activity_score_evidence(
         issues,
         path,
         %{"score_terms" => score_terms, "activities" => activities}
       )
       when is_map(score_terms) and is_list(activities) do
    activity_score = Map.get(score_terms, "activity_score")

    nested_scores =
      Enum.map(activities, fn
        %{} = activity -> Map.get(activity, "score")
        _activity -> :invalid
      end)

    if is_number(activity_score) and Enum.all?(nested_scores, &is_number/1) do
      validate_number_equal(
        issues,
        path <> ".score_terms.activity_score",
        activity_score,
        Enum.sum(nested_scores),
        "must equal nested activity score sum"
      )
    else
      issues
    end
  end

  defp validate_activity_score_evidence(issues, _path, _timeline), do: issues

  defp validate_activity_count_penalty_evidence(
         issues,
         path,
         %{"score_terms" => score_terms, "activities" => activities},
         {:ok, policy}
       )
       when is_map(score_terms) and is_list(activities) do
    activity_count_penalty = Map.get(score_terms, "activity_count_penalty")
    policy_penalty = Map.get(policy, "activity_count_penalty", 0.0)

    if is_number(activity_count_penalty) and is_number(policy_penalty) do
      validate_number_equal(
        issues,
        path <> ".score_terms.activity_count_penalty",
        activity_count_penalty,
        -length(activities) * policy_penalty,
        "must match activity count and scoring policy"
      )
    else
      issues
    end
  end

  defp validate_activity_count_penalty_evidence(
         issues,
         _path,
         _timeline,
         _scoring_policy
       ),
       do: issues

  defp validate_selection_count_evidence(
         issues,
         path,
         %{"score_terms" => score_terms, "activities" => activities}
       )
       when is_map(score_terms) and is_list(activities) do
    observation_count = Map.get(score_terms, "selected_observation_count")
    contact_count = Map.get(score_terms, "selected_contact_count")

    if non_negative_integer?(observation_count) and non_negative_integer?(contact_count) and
         Enum.all?(activities, &valid_count_activity?/1) do
      issues
      |> validate_equal(
        path <> ".score_terms.selected_observation_count",
        observation_count,
        Enum.count(activities, &(&1["type"] == "observe")),
        "must match nested observation activity count"
      )
      |> validate_equal(
        path <> ".score_terms.selected_contact_count",
        contact_count,
        Enum.count(activities, &DownlinkActivityNormalization.downlink?/1),
        "must match nested downlink contact count"
      )
    else
      issues
    end
  end

  defp validate_selection_count_evidence(issues, _path, _timeline), do: issues

  defp valid_count_activity?(%{"type" => type}) when is_binary(type), do: true
  defp valid_count_activity?(_activity), do: false

  defp non_negative_integer?(value), do: is_integer(value) and value >= 0

  defp validate_component_score_evidence(
         issues,
         path,
         %{"score_terms" => score_terms, "activities" => activities}
       )
       when is_map(score_terms) and is_list(activities) do
    Enum.reduce(@required_component_terms, issues, fn term, acc ->
      component_value = Map.get(score_terms, term)

      nested_values =
        Enum.map(activities, fn
          %{"score_terms" => nested_terms} when is_map(nested_terms) ->
            Map.get(nested_terms, term, 0.0)

          _activity ->
            :invalid
        end)

      if is_number(component_value) and Enum.all?(nested_values, &is_number/1) do
        validate_number_equal(
          acc,
          path <> ".score_terms.#{term}",
          component_value,
          Enum.sum(nested_values),
          "must equal nested activity #{term} sum"
        )
      else
        acc
      end
    end)
  end

  defp validate_component_score_evidence(issues, _path, _timeline), do: issues

  defp scoring_policy(%{"assumptions" => assumptions}) when is_map(assumptions) do
    case Map.fetch(assumptions, "scoring_policy") do
      {:ok, policy} when is_map(policy) -> {:ok, policy}
      :error -> {:ok, %{}}
      {:ok, _policy} -> :error
    end
  end

  defp scoring_policy(_artifact), do: :error

  defp aggregate_terms_valid?(score_terms) do
    Enum.all?(@required_aggregate_terms, &is_number(Map.get(score_terms, &1))) and
      Enum.all?(@optional_aggregate_terms, fn term ->
        not Map.has_key?(score_terms, term) or is_number(Map.get(score_terms, term))
      end)
  end

  defp validate_timeline_order(issues, timelines) when is_list(timelines) do
    timelines
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index(1)
    |> Enum.reduce(issues, fn {[previous, current], index}, acc ->
      if comparable_timeline?(previous) and comparable_timeline?(current) and
           not ordered_timeline_pair?(previous, current) do
        [
          error(
            "$.ranked_timelines[#{index}]",
            "must follow descending score and ascending scenario_id tie-break order"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_timeline_order(issues, _timelines), do: issues

  defp comparable_timeline?(%{"score" => score, "scenario_id" => scenario_id}),
    do: is_number(score) and StableIdValidation.valid?(scenario_id)

  defp comparable_timeline?(_timeline), do: false

  defp ordered_timeline_pair?(previous, current) do
    previous_score = previous["score"]
    current_score = current["score"]

    previous_score > current_score or
      (previous_score == current_score and previous["scenario_id"] <= current["scenario_id"])
  end

  defp validate_score_term_report(issues, timelines, %{"rows" => rows} = report)
       when is_list(timelines) and is_list(rows) do
    if valid_timeline_scores?(timelines) and Enum.all?(rows, &is_map/1) do
      expected_rows = expected_rows(timelines)
      expected_by_key = Map.new(expected_rows, &{row_key(&1), &1})
      expected_keys = MapSet.new(Map.keys(expected_by_key))
      actual_keys = Enum.map(rows, &row_key/1)

      issues
      |> validate_equal(
        "$.score_term_report.model",
        Map.get(report, "model"),
        "ranked_timeline_score_terms",
        "must identify ranked timeline score terms"
      )
      |> validate_equal(
        "$.score_term_report.source",
        Map.get(report, "source"),
        "campaign_plan.ranked_timelines",
        "must identify campaign_plan.ranked_timelines"
      )
      |> validate_equal(
        "$.score_term_report.score_term_keys",
        Map.get(report, "score_term_keys"),
        expected_score_term_keys(timelines),
        "must match enclosing ranked timeline score-term keys"
      )
      |> validate_equal(
        "$.score_term_report.rows",
        length(actual_keys),
        MapSet.size(MapSet.new(actual_keys)),
        "must contain unique rank, scenario, and term rows"
      )
      |> validate_equal(
        "$.score_term_report.rows",
        MapSet.new(actual_keys),
        expected_keys,
        "must contain exactly one row for each ranked timeline score term"
      )
      |> validate_report_rows(rows, expected_by_key)
    else
      issues
    end
  end

  defp validate_score_term_report(issues, _timelines, _report), do: issues

  defp valid_timeline_scores?(timelines) do
    Enum.all?(timelines, fn
      %{"scenario_id" => scenario_id, "score" => score, "score_terms" => score_terms}
      when is_binary(scenario_id) and is_number(score) and is_map(score_terms) ->
        Enum.all?(Map.values(score_terms), &is_number/1)

      _timeline ->
        false
    end)
  end

  defp expected_rows(timelines) do
    timelines
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {timeline, rank} ->
      Enum.map(timeline["score_terms"], fn {term_key, value} ->
        %{
          "rank" => rank,
          "scenario_id" => timeline["scenario_id"],
          "term_key" => term_key,
          "value" => value,
          "timeline_score" => timeline["score"],
          "selected" => rank == 1
        }
      end)
    end)
  end

  defp expected_score_term_keys(timelines) do
    timelines
    |> Enum.flat_map(&Map.keys(&1["score_terms"]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp validate_report_rows(issues, rows, expected_by_key) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      path = "$.score_term_report.rows[#{index}]"

      case Map.fetch(expected_by_key, row_key(row)) do
        {:ok, expected} ->
          acc
          |> validate_number_equal(
            path <> ".value",
            Map.get(row, "value"),
            expected["value"],
            "must match the enclosing ranked timeline score term"
          )
          |> validate_number_equal(
            path <> ".timeline_score",
            Map.get(row, "timeline_score"),
            expected["timeline_score"],
            "must match the enclosing ranked timeline score"
          )
          |> validate_equal(
            path <> ".selected",
            Map.get(row, "selected"),
            expected["selected"],
            "must match the enclosing ranked timeline selection"
          )

        :error ->
          [error(path, "must match an enclosing ranked timeline score term") | acc]
      end
    end)
  end

  defp row_key(row),
    do: {Map.get(row, "rank"), Map.get(row, "scenario_id"), Map.get(row, "term_key")}

  defp validate_number_equal(issues, _path, left, right, _message)
       when not is_number(left) or not is_number(right),
       do: issues

  defp validate_number_equal(issues, path, left, right, message) do
    if close?(left, right), do: issues, else: [error(path, message) | issues]
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]

  defp close?(left, right), do: abs(left - right) <= 1.0e-9
end
