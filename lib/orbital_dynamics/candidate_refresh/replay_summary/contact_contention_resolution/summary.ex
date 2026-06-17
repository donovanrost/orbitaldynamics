defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary do
  @moduledoc false

  alias __MODULE__.CapacityPack
  alias __MODULE__.Pressure
  alias __MODULE__.ResolutionFields

  def summary(resolution_summary, summary_source, replay_scope) do
    recommendation_count = summary_integer(resolution_summary, "recommendation_count")
    deferred_contact_count = summary_integer(resolution_summary, "deferred_contact_count")

    source_summary_model_counts =
      Map.get(resolution_summary, "source_summary_model_counts", %{}) |> non_empty_map()

    source_summary_schema_contract_counts =
      Map.get(resolution_summary, "source_summary_schema_contract_counts", %{})
      |> non_empty_map()

    source_artifact_type_counts =
      Map.get(resolution_summary, "source_artifact_type_counts", %{}) |> non_empty_map()

    conflict_group_count = summary_integer(resolution_summary, "conflict_group_count")

    review_recommendation_count =
      summary_integer(resolution_summary, "review_recommendation_count")

    capacity_pack_fields = CapacityPack.fields(resolution_summary)
    resolution_fields = ResolutionFields.fields(resolution_summary)

    source_report_paths = Map.get(resolution_summary, "paths") || []

    pressure_fields =
      Pressure.fields(
        resolution_fields,
        capacity_pack_fields,
        recommendation_count,
        deferred_contact_count,
        conflict_group_count,
        review_recommendation_count
      )

    %{
      "model" => "artifact_only_candidate_refresh_contact_contention_resolution_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(
          resolution_summary,
          "contact_contention_resolution_report.v1"
        ),
      "source_report_count" => summary_integer(resolution_summary, "count"),
      "source_report_row_count" => summary_integer(resolution_summary, "row_count"),
      "source_report_paths" => source_report_paths,
      "source_summary_model_counts" => source_summary_model_counts,
      "source_summary_schema_contract_counts" => source_summary_schema_contract_counts,
      "source_artifact_type_counts" => source_artifact_type_counts,
      "conflict_group_count" =>
        case conflict_group_count do
          count when count > 0 -> count
          _count -> nil
        end,
      "recommendation_count" => recommendation_count,
      "review_recommendation_count" =>
        case review_recommendation_count do
          count when count > 0 -> count
          _count -> nil
        end,
      "deferred_contact_count" => deferred_contact_count,
      "trust_boundary_status" => Map.get(resolution_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(resolution_summary, "trust_boundaries", []),
      "branch_local_contact_contention_resolution_pressure" =>
        Map.get(pressure_fields, "branch_local_contact_contention_resolution_pressure"),
      "branch_local_deferred_contact_pressure" =>
        Map.get(pressure_fields, "branch_local_deferred_contact_pressure"),
      "branch_local_capacity_pack_pressure" =>
        Map.get(pressure_fields, "branch_local_capacity_pack_pressure"),
      "branch_local_contact_contention_resolution_action_pressure" =>
        Map.get(
          pressure_fields,
          "branch_local_contact_contention_resolution_action_pressure"
        ),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_contact_contention_resolution_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_contention_resolution_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(ResolutionFields.output_fields(resolution_fields))
    |> Map.merge(capacity_pack_fields)
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
