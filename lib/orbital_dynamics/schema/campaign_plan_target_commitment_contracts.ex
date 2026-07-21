defmodule OrbitalDynamics.Schema.CampaignPlanTargetCommitmentContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_field_at_least: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_number_or_string: 4,
      expect_type: 5,
      require_fields: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [reject_duplicate_ids: 3, validate_stable_id_list: 4, validate_stable_ids: 4]

  @required_fields [
    "target_id",
    "candidate_activity_count",
    "candidate_duration_s",
    "selected_activity_count",
    "selected_duration_s",
    "selected_activity_ids",
    "status"
  ]

  @statuses ["selected", "candidate_available", "no_candidate_window"]

  def validate(issues, artifact) when is_map(artifact) do
    case Map.get(artifact, "target_commitments") do
      nil ->
        issues

      :null ->
        issues

      rows when is_list(rows) ->
        issues
        |> validate_rows("$.target_commitments", rows, &validate_row/3)
        |> reject_duplicate_targets(rows)
        |> reconcile_plan_evidence(rows, artifact)
        |> reconcile_objective_evidence(rows, Map.get(artifact, "objective_satisfaction_report"))

      _rows ->
        [error("$.target_commitments", "must be a list") | issues]
    end
  end

  defp validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, @required_fields)
    |> expect_type(path, row, "target_id", :binary)
    |> validate_stable_ids(path, row, ["target_id"])
    |> expect_optional_number_or_string(path, row, "priority")
    |> expect_non_negative_integer(path, row, "candidate_activity_count")
    |> expect_number(path, row, "candidate_duration_s")
    |> expect_field_at_least(path, row, "candidate_duration_s", 0.0)
    |> expect_non_negative_integer(path, row, "selected_activity_count")
    |> expect_number(path, row, "selected_duration_s")
    |> expect_field_at_least(path, row, "selected_duration_s", 0.0)
    |> expect_type(path, row, "selected_activity_ids", :list)
    |> validate_stable_id_list(path, row, "selected_activity_ids")
    |> reject_duplicate_selected_ids(path, row)
    |> expect_one_of(path, row, "status", @statuses)
  end

  defp reject_duplicate_selected_ids(issues, path, %{"selected_activity_ids" => ids})
       when is_list(ids),
       do: reject_duplicate_ids(issues, path <> ".selected_activity_ids", ids)

  defp reject_duplicate_selected_ids(issues, _path, _row), do: issues

  defp reject_duplicate_targets(issues, rows) do
    target_ids =
      rows
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, "target_id"))
      |> Enum.filter(&is_binary/1)

    duplicate_ids =
      target_ids
      |> Enum.frequencies()
      |> Enum.filter(fn {_target_id, count} -> count > 1 end)
      |> Enum.map(fn {target_id, _count} -> target_id end)
      |> Enum.sort()

    if duplicate_ids == [] do
      issues
    else
      [
        error(
          "$.target_commitments",
          "must not contain duplicate target rows: #{inspect(duplicate_ids)}"
        )
        | issues
      ]
    end
  end

  defp reconcile_plan_evidence(issues, rows, artifact) do
    candidates = map_rows(Map.get(artifact, "candidate_activities"))
    selected = map_rows(Map.get(artifact, "activities"))

    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{"target_id" => target_id} = row, index}, acc when is_binary(target_id) ->
        candidate_rows = target_activity_rows(candidates, target_id)
        selected_rows = target_activity_rows(selected, target_id)
        path = "$.target_commitments[#{index}]"

        acc
        |> expect_field_equals(
          path,
          row,
          "candidate_activity_count",
          length(candidate_rows),
          "must equal candidate observe activity count for target_id"
        )
        |> expect_field_equals(
          path,
          row,
          "candidate_duration_s",
          duration_sum(candidate_rows),
          "must equal candidate observe duration for target_id"
        )
        |> expect_field_equals(
          path,
          row,
          "selected_activity_count",
          length(selected_rows),
          "must equal selected observe activity count for target_id"
        )
        |> expect_field_equals(
          path,
          row,
          "selected_duration_s",
          duration_sum(selected_rows),
          "must equal selected observe duration for target_id"
        )
        |> expect_field_equals(
          path,
          row,
          "selected_activity_ids",
          Enum.map(selected_rows, &Map.get(&1, "id")),
          "must equal selected observe activity IDs for target_id"
        )
        |> expect_field_equals(
          path,
          row,
          "status",
          commitment_status(candidate_rows, selected_rows),
          "must match candidate and selected activity evidence"
        )

      {_row, _index}, acc ->
        acc
    end)
  end

  defp reconcile_objective_evidence(issues, rows, %{"rows" => objective_rows})
       when is_list(objective_rows) do
    commitment_rows = Enum.filter(rows, &valid_target_row?/1)

    target_objective_rows =
      Enum.filter(objective_rows, fn
        %{"objective" => "target_commitment", "target_id" => target_id}
        when is_binary(target_id) ->
          true

        _row ->
          false
      end)

    issues
    |> validate_objective_target_set(commitment_rows, target_objective_rows)
    |> validate_objective_rows(commitment_rows, target_objective_rows)
  end

  defp reconcile_objective_evidence(issues, _rows, _report), do: issues

  defp validate_objective_target_set(issues, commitment_rows, objective_rows) do
    commitment_ids = commitment_rows |> Enum.map(&Map.get(&1, "target_id")) |> Enum.sort()
    objective_ids = objective_rows |> Enum.map(&Map.get(&1, "target_id")) |> Enum.sort()

    if commitment_ids == objective_ids do
      issues
    else
      [
        error(
          "$.target_commitments",
          "target IDs must match objective-satisfaction target commitment rows"
        )
        | issues
      ]
    end
  end

  defp validate_objective_rows(issues, commitment_rows, objective_rows) do
    objective_by_target = Map.new(objective_rows, &{Map.get(&1, "target_id"), &1})

    commitment_rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      case Map.get(objective_by_target, Map.get(row, "target_id")) do
        %{} = objective_row ->
          path = "$.target_commitments[#{index}]"

          acc
          |> expect_field_equals(
            path,
            row,
            "candidate_activity_count",
            Map.get(objective_row, "candidate_count"),
            "must match objective-satisfaction candidate_count"
          )
          |> expect_field_equals(
            path,
            row,
            "selected_activity_count",
            Map.get(objective_row, "selected_count"),
            "must match objective-satisfaction selected_count"
          )
          |> expect_field_equals(
            path,
            row,
            "selected_activity_ids",
            Map.get(objective_row, "selected_activity_ids"),
            "must match objective-satisfaction selected_activity_ids"
          )
          |> expect_field_equals(
            path,
            row,
            "status",
            Map.get(objective_row, "status"),
            "must match objective-satisfaction status"
          )

        _objective_row ->
          acc
      end
    end)
  end

  defp valid_target_row?(%{"target_id" => target_id}) when is_binary(target_id), do: true
  defp valid_target_row?(_row), do: false

  defp map_rows(rows) when is_list(rows), do: Enum.filter(rows, &is_map/1)
  defp map_rows(_rows), do: []

  defp target_activity_rows(rows, target_id) do
    Enum.filter(
      rows,
      &(Map.get(&1, "type") == "observe" and Map.get(&1, "target_id") == target_id)
    )
  end

  defp duration_sum(rows) do
    rows
    |> Enum.map(&Map.get(&1, "duration_s", 0.0))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp commitment_status(_candidates, selected) when selected != [], do: "selected"
  defp commitment_status(candidates, _selected) when candidates != [], do: "candidate_available"
  defp commitment_status(_candidates, _selected), do: "no_candidate_window"
end
