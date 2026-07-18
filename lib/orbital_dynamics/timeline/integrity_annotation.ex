defmodule OrbitalDynamics.Timeline.IntegrityAnnotation do
  @moduledoc false

  def annotate(rows, validate_missing_dependencies?, callbacks) when is_list(callbacks) do
    by_activity_id = Map.new(rows, &{&1["activity_id"], &1})
    by_timeline_id = Map.new(rows, &{&1["timeline_id"], &1})

    by_activity_dependency =
      dependency_graph(rows, "activity_id", "dependency_activity_ids", callbacks)

    by_timeline_dependency =
      dependency_graph(rows, "timeline_id", "dependency_timeline_ids", callbacks)

    rows
    |> Enum.map(fn row ->
      issues =
        timeline_integrity_issues(
          row,
          rows,
          by_activity_id,
          by_timeline_id,
          by_activity_dependency,
          by_timeline_dependency,
          validate_missing_dependencies?,
          callbacks
        )

      annotate_timeline_integrity_row(row, issues, callbacks)
    end)
  end

  defp timeline_integrity_issues(
         row,
         rows,
         by_activity_id,
         by_timeline_id,
         by_activity_dependency,
         by_timeline_dependency,
         validate_missing_dependencies?,
         callbacks
       ) do
    dependency_integrity_issues(
      row,
      by_activity_id,
      by_timeline_id,
      by_activity_dependency,
      by_timeline_dependency,
      validate_missing_dependencies?,
      callbacks
    ) ++
      exclusivity_integrity_issues(row, rows, by_activity_id, by_timeline_id, callbacks)
  end

  defp annotate_timeline_integrity_row(row, [], _callbacks), do: row

  defp annotate_timeline_integrity_row(row, issues, callbacks) do
    issue_types = issues |> Enum.map(& &1["type"]) |> Enum.uniq() |> Enum.sort()

    fields =
      %{
        "timeline_integrity_status" => "review_required",
        "timeline_integrity_issue_count" => length(issues),
        "timeline_integrity_issue_types" => issue_types,
        "timeline_integrity_issues" => issues,
        "missing_dependency_activity_ids" => issue_ids(issues, "missing_dependency_activity_id"),
        "missing_dependency_timeline_ids" => issue_ids(issues, "missing_dependency_timeline_id"),
        "self_dependency_activity_ids" => issue_ids(issues, "self_dependency_activity_id"),
        "self_dependency_timeline_ids" => issue_ids(issues, "self_dependency_timeline_id"),
        "duplicate_dependency_activity_ids" =>
          issue_ids(issues, "duplicate_dependency_activity_id"),
        "duplicate_dependency_timeline_ids" =>
          issue_ids(issues, "duplicate_dependency_timeline_id"),
        "duplicate_exclusivity_activity_ids" =>
          issue_ids(issues, "duplicate_exclusivity_activity_id"),
        "duplicate_exclusivity_timeline_ids" =>
          issue_ids(issues, "duplicate_exclusivity_timeline_id"),
        "dependency_cycle_activity_ids" => issue_ids(issues, "dependency_cycle_activity_id"),
        "dependency_cycle_timeline_ids" => issue_ids(issues, "dependency_cycle_timeline_id"),
        "dependency_order_violation_activity_ids" =>
          issue_ids(issues, "dependency_order_violation_activity_id"),
        "dependency_order_violation_timeline_ids" =>
          issue_ids(issues, "dependency_order_violation_timeline_id"),
        "exclusivity_violation_activity_ids" =>
          issue_ids(issues, "exclusivity_violation_activity_id"),
        "exclusivity_violation_timeline_ids" =>
          issue_ids(issues, "exclusivity_violation_timeline_id"),
        "exclusivity_violation_group" => issue_value(issues, "exclusivity_violation_group")
      }
      |> compact_map(callbacks)

    row
    |> maybe_supersede_for_timeline_integrity()
    |> Map.merge(fields)
  end

  defp maybe_supersede_for_timeline_integrity(
         %{"required_operator_action" => "review_duplicate_timeline_identity"} = row
       ) do
    row
  end

  defp maybe_supersede_for_timeline_integrity(row) do
    row
    |> Map.put_new("superseded_required_operator_action", row["required_operator_action"])
    |> Map.put_new("superseded_operator_action_reason", row["operator_action_reason"])
    |> Map.put("required_operator_action", "review_timeline_integrity")
    |> Map.put("operator_action_reason", "timeline_integrity_issue")
  end

  defp dependency_integrity_issues(
         row,
         by_activity_id,
         by_timeline_id,
         by_activity_dependency,
         by_timeline_dependency,
         validate_missing_dependencies?,
         callbacks
       ) do
    activity_dependency_issues(
      row,
      by_activity_id,
      by_activity_dependency,
      validate_missing_dependencies?,
      callbacks
    ) ++
      timeline_dependency_issues(
        row,
        by_timeline_id,
        by_timeline_dependency,
        validate_missing_dependencies?,
        callbacks
      )
  end

  defp activity_dependency_issues(
         row,
         by_activity_id,
         by_activity_dependency,
         validate_missing_dependencies?,
         callbacks
       ) do
    duplicate_reference_issues(
      row,
      "duplicate_dependency_activity_ids",
      "duplicate_dependency_activity",
      "duplicate_dependency_activity_id",
      callbacks
    ) ++
      (row
       |> list_value("dependency_activity_ids", callbacks)
       |> Enum.flat_map(fn dependency_id ->
         cond do
           dependency_id == row["activity_id"] ->
             [
               issue(
                 "self_dependency_activity",
                 %{
                   "self_dependency_activity_id" => dependency_id
                 },
                 callbacks
               )
             ]

           validate_missing_dependencies? and not Map.has_key?(by_activity_id, dependency_id) ->
             [
               issue(
                 "missing_dependency_activity",
                 %{
                   "missing_dependency_activity_id" => dependency_id
                 },
                 callbacks
               )
             ]

           dependency_cycle?(by_activity_dependency, dependency_id, row["activity_id"]) ->
             [
               issue(
                 "dependency_cycle",
                 %{
                   "dependency_cycle_activity_id" => dependency_id
                 },
                 callbacks
               )
             ]

           Map.has_key?(by_activity_id, dependency_id) and
               dependency_order_violation?(Map.fetch!(by_activity_id, dependency_id), row) ->
             [
               issue(
                 "dependency_order_violation",
                 %{
                   "dependency_order_violation_activity_id" => dependency_id
                 },
                 callbacks
               )
             ]

           true ->
             []
         end
       end))
  end

  defp timeline_dependency_issues(
         row,
         by_timeline_id,
         by_timeline_dependency,
         validate_missing_dependencies?,
         callbacks
       ) do
    duplicate_reference_issues(
      row,
      "duplicate_dependency_timeline_ids",
      "duplicate_dependency_timeline",
      "duplicate_dependency_timeline_id",
      callbacks
    ) ++
      (row
       |> list_value("dependency_timeline_ids", callbacks)
       |> Enum.flat_map(fn dependency_id ->
         cond do
           dependency_id == row["timeline_id"] ->
             [
               issue(
                 "self_dependency_timeline",
                 %{
                   "self_dependency_timeline_id" => dependency_id
                 },
                 callbacks
               )
             ]

           validate_missing_dependencies? and not Map.has_key?(by_timeline_id, dependency_id) ->
             [
               issue(
                 "missing_dependency_timeline",
                 %{
                   "missing_dependency_timeline_id" => dependency_id
                 },
                 callbacks
               )
             ]

           dependency_cycle?(by_timeline_dependency, dependency_id, row["timeline_id"]) ->
             [
               issue(
                 "dependency_cycle",
                 %{
                   "dependency_cycle_timeline_id" => dependency_id
                 },
                 callbacks
               )
             ]

           Map.has_key?(by_timeline_id, dependency_id) and
               dependency_order_violation?(Map.fetch!(by_timeline_id, dependency_id), row) ->
             [
               issue(
                 "dependency_order_violation",
                 %{
                   "dependency_order_violation_timeline_id" => dependency_id
                 },
                 callbacks
               )
             ]

           true ->
             []
         end
       end))
  end

  defp dependency_graph(rows, id_field, dependency_field, callbacks) do
    Map.new(rows, fn row ->
      {row[id_field], list_value(row, dependency_field, callbacks)}
    end)
  end

  defp dependency_cycle?(_graph, nil, _target_id), do: false
  defp dependency_cycle?(_graph, dependency_id, dependency_id), do: false

  defp dependency_cycle?(graph, dependency_id, target_id) do
    dependency_path?(graph, dependency_id, target_id, MapSet.new())
  end

  defp dependency_path?(_graph, current_id, current_id, _visited), do: true

  defp dependency_path?(graph, current_id, target_id, visited) do
    cond do
      is_nil(current_id) or is_nil(target_id) ->
        false

      MapSet.member?(visited, current_id) ->
        false

      true ->
        graph
        |> Map.get(current_id, [])
        |> Enum.any?(&dependency_path?(graph, &1, target_id, MapSet.put(visited, current_id)))
    end
  end

  defp exclusivity_integrity_issues(row, rows, by_activity_id, by_timeline_id, callbacks) do
    explicit_activity_exclusivity_issues(row, by_activity_id, callbacks) ++
      explicit_timeline_exclusivity_issues(row, by_timeline_id, callbacks) ++
      exclusivity_group_issues(row, rows, callbacks)
  end

  defp explicit_activity_exclusivity_issues(row, by_activity_id, callbacks) do
    duplicate_reference_issues(
      row,
      "duplicate_exclusivity_activity_ids",
      "duplicate_exclusivity_activity",
      "duplicate_exclusivity_activity_id",
      callbacks
    ) ++
      (row
       |> list_value("exclusive_with_activity_ids", callbacks)
       |> Enum.flat_map(fn exclusive_id ->
         case Map.get(by_activity_id, exclusive_id) do
           nil ->
             []

           other ->
             if overlap?(row, other) do
               [
                 issue(
                   "exclusivity_overlap",
                   %{
                     "exclusivity_violation_activity_id" => exclusive_id,
                     "exclusivity_violation_timeline_id" => other["timeline_id"]
                   },
                   callbacks
                 )
               ]
             else
               []
             end
         end
       end))
  end

  defp explicit_timeline_exclusivity_issues(row, by_timeline_id, callbacks) do
    duplicate_reference_issues(
      row,
      "duplicate_exclusivity_timeline_ids",
      "duplicate_exclusivity_timeline",
      "duplicate_exclusivity_timeline_id",
      callbacks
    ) ++
      (row
       |> list_value("exclusive_with_timeline_ids", callbacks)
       |> Enum.flat_map(fn exclusive_id ->
         case Map.get(by_timeline_id, exclusive_id) do
           nil ->
             []

           other ->
             if overlap?(row, other) do
               [
                 issue(
                   "exclusivity_overlap",
                   %{
                     "exclusivity_violation_activity_id" => other["activity_id"],
                     "exclusivity_violation_timeline_id" => exclusive_id
                   },
                   callbacks
                 )
               ]
             else
               []
             end
         end
       end))
  end

  defp duplicate_reference_issues(row, row_field, issue_type, issue_field, callbacks) do
    row
    |> list_value(row_field, callbacks)
    |> Enum.map(fn duplicate_id ->
      issue(issue_type, %{issue_field => duplicate_id}, callbacks)
    end)
  end

  defp exclusivity_group_issues(row, rows, callbacks) do
    case row["exclusivity_group"] || get_in(row, ["activity_context", "exclusivity_group"]) do
      nil ->
        []

      group ->
        rows
        |> Enum.reject(&(&1["activity_id"] == row["activity_id"]))
        |> Enum.filter(
          &((Map.get(&1, "exclusivity_group") ||
               get_in(&1, ["activity_context", "exclusivity_group"])) == group)
        )
        |> Enum.filter(&overlap?(row, &1))
        |> Enum.map(fn other ->
          issue(
            "exclusivity_group_overlap",
            %{
              "exclusivity_violation_activity_id" => other["activity_id"],
              "exclusivity_violation_timeline_id" => other["timeline_id"],
              "exclusivity_violation_group" => group
            },
            callbacks
          )
        end)
    end
  end

  defp dependency_order_violation?(dependency, row) do
    is_number(dependency["ends_at_s"]) and is_number(row["starts_at_s"]) and
      dependency["ends_at_s"] > row["starts_at_s"]
  end

  defp overlap?(left, right) do
    is_number(left["starts_at_s"]) and is_number(left["ends_at_s"]) and
      is_number(right["starts_at_s"]) and is_number(right["ends_at_s"]) and
      left["starts_at_s"] < right["ends_at_s"] and right["starts_at_s"] < left["ends_at_s"]
  end

  defp issue_ids(issues, field) do
    issues
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp issue_value(issues, field) do
    issues
    |> Enum.find_value(&Map.get(&1, field))
  end

  defp list_value(value, key, callbacks),
    do: apply(Keyword.fetch!(callbacks, :list_value), [value, key])

  defp issue(type, fields, callbacks),
    do: apply(Keyword.fetch!(callbacks, :issue), [type, fields])

  defp compact_map(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :compact_map), [value])
end
