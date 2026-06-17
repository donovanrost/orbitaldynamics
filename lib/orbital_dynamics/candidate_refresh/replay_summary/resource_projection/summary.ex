defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.Summary do
  @moduledoc false

  alias __MODULE__.Pressure
  alias __MODULE__.ResourcePressureFields

  def summary(projection_summary, summary_source, replay_scope) do
    projected_resource_count =
      summary_integer(projection_summary, "projected_resource_count")

    invalid_activity_input_count =
      summary_integer(projection_summary, "invalid_activity_input_count")

    invalid_resource_summary_input_count =
      summary_integer(projection_summary, "invalid_resource_summary_input_count")

    source_artifact_type_counts =
      projection_summary
      |> Map.get("source_artifact_type_counts", %{})
      |> non_empty_map()

    source_flow_summary_model_counts =
      projection_summary
      |> Map.get("source_flow_summary_model_counts", %{})
      |> non_empty_map()

    resource_pressure_fields = ResourcePressureFields.fields(projection_summary)

    pressure_fields =
      Pressure.fields(
        resource_pressure_fields,
        projected_resource_count,
        invalid_activity_input_count,
        invalid_resource_summary_input_count
      )

    source_report_paths = Map.get(projection_summary, "paths") || []

    %{
      "model" => "artifact_only_candidate_refresh_resource_projection_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(projection_summary, "resource_projection_report.v1"),
      "source_report_count" => summary_integer(projection_summary, "count"),
      "source_report_row_count" => summary_integer(projection_summary, "row_count"),
      "source_report_paths" => source_report_paths,
      "projected_resource_count" => projected_resource_count,
      "source_artifact_type_counts" => source_artifact_type_counts,
      "source_flow_summary_model_counts" => source_flow_summary_model_counts,
      "invalid_activity_input_count" => invalid_activity_input_count,
      "invalid_resource_summary_input_count" => invalid_resource_summary_input_count,
      "trust_boundary_status" => Map.get(projection_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(projection_summary, "trust_boundaries", []),
      "branch_local_resource_projection_pressure" =>
        Map.get(pressure_fields, "branch_local_resource_projection_pressure"),
      "branch_local_projected_resource_pressure" =>
        Map.get(pressure_fields, "branch_local_projected_resource_pressure"),
      "branch_local_invalid_resource_projection_pressure" =>
        Map.get(pressure_fields, "branch_local_invalid_resource_projection_pressure"),
      "branch_local_activity_pressure" =>
        Map.get(pressure_fields, "branch_local_activity_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_resource_projection_replay_summary",
        "resource_projection" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_resource_projection_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(resource_pressure_fields)
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

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
