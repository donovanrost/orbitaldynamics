defmodule OrbitalDynamics.CandidateRefresh.SourceObjectives.TimelineDiff do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def objectives(source_reports) when is_list(source_reports) do
    Enum.flat_map(source_reports, fn {path, report} ->
      report
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.flat_map(fn row ->
        cond do
          removed_observation_objective_row?(row) ->
            [removed_observation_objective(path, row)]

          changed_observation_objective_row?(row) ->
            [changed_observation_objective(path, row)]

          true ->
            []
        end
      end)
    end)
  end

  def objectives(_source_reports), do: []

  def removed_observation_objective_row?(%{} = row) do
    OperationalFeedback.timeline_diff_status(row) == "removed" and
      OperationalFeedback.timeline_diff_observation_activity?(row, "source") and
      removed_observation_target_id(row) not in [nil, ""]
  end

  def changed_observation_objective_row?(%{} = row) do
    OperationalFeedback.timeline_diff_status(row) == "changed" and
      OperationalFeedback.timeline_diff_observation_activity?(row) and
      OperationalFeedback.timeline_diff_changed_observation_target_id(row) not in [nil, ""] and
      is_number(OperationalFeedback.timeline_diff_changed_observation_success_factor(row))
  end

  defp removed_observation_target_id(row) do
    target_identity_value(
      row["source_target_id"] ||
        get_in(row, ["source_activity_context", "target_id"]) ||
        get_in(row, ["source_activity_context", "target"]) ||
        get_in(row, ["source_activity_context", "timeline_identity", "subject_id"])
    )
  end

  defp removed_observation_required_revisits(row) do
    numeric_value(
      row["source_required_revisits"] ||
        row["source_required_observations"] ||
        get_in(row, ["source_activity_context", "required_revisits"]) ||
        get_in(row, ["source_activity_context", "required_observations"])
    ) || 1.0
  end

  defp removed_observation_objective(path, row) do
    target_id = removed_observation_target_id(row)
    required_revisits = max(removed_observation_required_revisits(row), 1.0)

    %{
      "id" => "timeline_diff:target_revisit:#{target_id}:#{objective_suffix(path, row)}",
      "type" => "target_revisit",
      "target_id" => target_id,
      "scenario_id" => stable_id_or_nil(row["scenario_id"]),
      "spacecraft_id" =>
        stable_id_or_nil(
          row["source_spacecraft_id"] ||
            get_in(row, ["source_activity_context", "spacecraft_id"])
        ),
      "required_revisits" => required_revisits,
      "source" => "timeline_diff_report.rows",
      "source_path" => path,
      "source_diff_status" => OperationalFeedback.timeline_diff_status(row),
      "source_timeline_id" => stable_id_or_nil(row["timeline_id"]),
      "source_activity_id" => stable_id_or_nil(row["source_activity_id"]),
      "source_activity_type" => row["source_activity_type"],
      "source_required_operator_action" => row["required_operator_action"],
      "source_reason" => row["reason"],
      "source_starts_at_s" => numeric_value(row["source_starts_at_s"]),
      "source_ends_at_s" => numeric_value(row["source_ends_at_s"])
    }
    |> compact_map()
  end

  defp changed_observation_objective(path, row) do
    target_id = OperationalFeedback.timeline_diff_changed_observation_target_id(row)
    success_factor = OperationalFeedback.timeline_diff_changed_observation_success_factor(row)

    %{
      "id" => "timeline_diff:target_revisit:#{target_id}:#{objective_suffix(path, row)}",
      "type" => "target_revisit",
      "target_id" => target_id,
      "scenario_id" => stable_id_or_nil(row["scenario_id"]),
      "spacecraft_id" =>
        stable_id_or_nil(
          row["replacement_spacecraft_id"] ||
            row["source_spacecraft_id"] ||
            get_in(row, ["replacement_activity_context", "spacecraft_id"]) ||
            get_in(row, ["source_activity_context", "spacecraft_id"])
        ),
      "required_revisits" => 1.0,
      "source" => "timeline_diff_report.rows",
      "source_path" => path,
      "source_diff_status" => OperationalFeedback.timeline_diff_status(row),
      "source_timeline_id" => stable_id_or_nil(row["timeline_id"]),
      "source_activity_id" => stable_id_or_nil(row["source_activity_id"]),
      "replacement_activity_id" => stable_id_or_nil(row["replacement_activity_id"]),
      "source_activity_type" => row["source_activity_type"],
      "replacement_activity_type" => row["replacement_activity_type"],
      "source_required_operator_action" => row["required_operator_action"],
      "source_reason" => row["reason"],
      "source_changed_fields" => OperationalFeedback.timeline_diff_changed_fields(row),
      "observation_success_factor" => success_factor,
      "source_starts_at_s" => numeric_value(row["source_starts_at_s"]),
      "source_ends_at_s" => numeric_value(row["source_ends_at_s"]),
      "replacement_starts_at_s" => numeric_value(row["replacement_starts_at_s"]),
      "replacement_ends_at_s" => numeric_value(row["replacement_ends_at_s"])
    }
    |> compact_map()
  end

  defp objective_suffix(path, row) do
    :crypto.hash(
      :sha256,
      :erlang.term_to_binary({
        path,
        row["timeline_id"],
        row["source_activity_id"],
        row["replacement_activity_id"],
        row["source_target_id"],
        row["replacement_target_id"],
        row["source_activity_context"],
        row["replacement_activity_context"]
      })
    )
    |> Base.encode16(case: :lower)
    |> binary_part(0, 8)
  end

  defp target_identity_value(%{} = target) do
    stable_id_or_nil(target["id"] || target["target_id"] || target["name"]) ||
      encode_value(target["id"] || target["target_id"] || target["name"])
  end

  defp target_identity_value(value), do: encode_value(value)

  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)
  defp stringify_keys(value), do: ValueEncoding.stringify_keys_preserving_lists(value)
  defp numeric_value(value), do: ValueEncoding.numeric_value(value)
  defp compact_map(map), do: ValueEncoding.compact_nil_values(map)

  defp encode_value(value), do: ValueEncoding.encode_value_preserving_lists(value)
end
