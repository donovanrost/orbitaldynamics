defmodule OrbitalDynamics.CandidateRefresh.TargetLookup do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ObservationObjectives
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def targets(refresh) do
    [
      Map.get(refresh, "targets", []),
      get_in(refresh, ["mission_state", "targets"]) || [],
      get_in(refresh, ["accepted_planning_state", "targets"]) || []
    ]
    |> Enum.flat_map(&List.wrap/1)
  end

  def by_id(refresh, target_id, refresh_objectives) do
    target_id = encode_value(target_id)

    target_rows =
      refresh
      |> targets()
      |> Enum.map(&stringify_keys/1)
      |> Enum.group_by(&Map.get(&1, "id"))
      |> Map.get(target_id, [])

    case target_rows do
      [] ->
        objective_target_spec_by_id(
          refresh,
          target_id,
          refresh_objectives
        )

      rows ->
        unique_target_match(rows)
    end
  end

  defp objective_target_spec_by_id(
         refresh,
         target_id,
         refresh_objectives
       ) do
    refresh
    |> refresh_objectives.()
    |> Enum.flat_map(&ObservationObjectives.target_specs/1)
    |> Enum.filter(&(target_identity_value(&1) == target_id))
    |> unique_target_match()
  end

  defp unique_target_match([target]), do: target
  defp unique_target_match(_matches), do: nil

  defp target_identity_value(%{} = target) do
    ObservationObjectives.target_identity_value(target, &encode_value/1)
  end

  defp target_identity_value(value),
    do: ObservationObjectives.target_identity_value(value, &encode_value/1)

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
