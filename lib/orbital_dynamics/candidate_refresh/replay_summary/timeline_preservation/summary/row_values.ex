defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePreservation.Summary.RowValues do
  @moduledoc false

  alias __MODULE__.Values

  def action_routing(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "required_operator_action"))
    |> Map.delete(nil)
    |> Map.delete("none")
    |> Enum.map(fn {action, action_rows} ->
      route =
        %{
          "review_count" => length(action_rows),
          "activity_ids" => ids(action_rows, "activity_id"),
          "timeline_ids" => ids(action_rows, "timeline_id"),
          "timeline_preservation_statuses" =>
            action_rows
            |> Enum.map(&Map.get(&1, "timeline_preservation_status"))
            |> sorted_string_values(),
          "protection_decisions" =>
            action_rows
            |> Enum.map(&Map.get(&1, "timeline_preservation_protection_decision"))
            |> sorted_string_values(),
          "protection_categories" =>
            action_rows
            |> Enum.map(&Map.get(&1, "timeline_preservation_protection_category"))
            |> sorted_string_values()
        }
        |> Values.compact_map()

      {action, route}
    end)
    |> Map.new()
    |> Values.non_empty_map()
  end

  def source_contract(%{} = row) do
    source = Map.get(row, "source")
    source_state = Map.get(row, "source_timeline_preservation", %{})

    cond do
      is_binary(Map.get(source_state, "schema_contract")) ->
        Map.get(source_state, "schema_contract")

      is_binary(source) and String.ends_with?(source, ".status") ->
        "timeline_preservation_status.v1"

      is_binary(source) and String.ends_with?(source, ".rows") ->
        "timeline_preservation_report.v1"

      true ->
        nil
    end
  end

  def source_model(%{} = row) do
    source = Map.get(row, "source")
    source_state = Map.get(row, "source_timeline_preservation", %{})

    cond do
      is_binary(Map.get(source_state, "model")) ->
        Map.get(source_state, "model")

      source_contract(row) == "timeline_preservation_status.v1" ->
        "artifact_only_lifecycle_preservation_status"

      is_binary(source) and String.ends_with?(source, ".rows") ->
        "artifact_only_lifecycle_preservation_summary"

      true ->
        nil
    end
  end

  def count_ids(rows, field) do
    rows
    |> Enum.flat_map(&row_ids(&1, field))
    |> count_values()
  end

  def ids(rows, field) do
    rows
    |> Enum.flat_map(&row_ids(&1, field))
    |> sorted_string_values()
  end

  def trust_boundaries(reports) do
    reports
    |> Enum.flat_map(fn report ->
      [
        Map.get(report, "trust_boundary"),
        get_in(report, ["provenance", "trust_boundary"]),
        get_in(report, ["metadata", "trust_boundary"])
        | List.wrap(Map.get(report, "trust_boundaries"))
      ]
    end)
    |> Values.sorted_string_values()
  end

  def sorted_string_values(values), do: Values.sorted_string_values(values)

  def count_values(values), do: Values.count_values(values)

  defp row_ids(%{} = row, "activity_id") do
    [
      row["activity_id"],
      get_in(row, ["source_timeline_preservation", "activity_id"])
    ]
  end

  defp row_ids(%{} = row, "timeline_id") do
    [
      row["timeline_id"],
      row["subject_id"],
      get_in(row, ["source_timeline_preservation", "timeline_id"])
    ]
  end
end
