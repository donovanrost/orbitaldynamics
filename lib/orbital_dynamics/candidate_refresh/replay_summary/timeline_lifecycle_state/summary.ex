defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState.Summary do
  @moduledoc false

  alias __MODULE__.LifecycleFields
  alias __MODULE__.Pressure

  def summary(lifecycle_summary, summary_source, replay_scope) do
    row_count = summary_integer(lifecycle_summary, "row_count")
    planned_activity_count = summary_integer(lifecycle_summary, "planned_activity_count")
    realized_activity_count = summary_integer(lifecycle_summary, "realized_activity_count")
    recordable_count = summary_integer(lifecycle_summary, "recordable_count")
    preserved_count = summary_integer(lifecycle_summary, "preserved_count")
    review_required_count = summary_integer(lifecycle_summary, "review_required_count")

    duplicate_timeline_identity_count =
      summary_integer(lifecycle_summary, "duplicate_timeline_identity_count")

    invalid_activity_input_count =
      summary_integer(lifecycle_summary, "invalid_activity_input_count")

    transition_application_provenance_count =
      summary_integer(lifecycle_summary, "transition_application_provenance_count")

    lifecycle_fields = LifecycleFields.fields(lifecycle_summary)

    pressure_fields =
      Pressure.fields(lifecycle_fields, %{
        row_count: row_count,
        planned_activity_count: planned_activity_count,
        realized_activity_count: realized_activity_count,
        recordable_count: recordable_count,
        preserved_count: preserved_count,
        review_required_count: review_required_count,
        duplicate_timeline_identity_count: duplicate_timeline_identity_count,
        invalid_activity_input_count: invalid_activity_input_count,
        transition_application_provenance_count: transition_application_provenance_count
      })

    %{
      "model" => "artifact_only_candidate_refresh_timeline_lifecycle_state_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(
          lifecycle_summary,
          "timeline_lifecycle_state_summary.v1"
        ),
      "source_report_count" => summary_integer(lifecycle_summary, "count"),
      "source_report_row_count" => row_count,
      "source_report_paths" => Map.get(lifecycle_summary, "paths", []),
      "planned_activity_count" => planned_activity_count,
      "realized_activity_count" => realized_activity_count,
      "recordable_count" => recordable_count,
      "preserved_count" => preserved_count,
      "review_required_count" => review_required_count,
      "duplicate_timeline_identity_count" => duplicate_timeline_identity_count,
      "invalid_activity_input_count" => invalid_activity_input_count,
      "transition_application_provenance_count" => transition_application_provenance_count,
      "trust_boundary_status" => Map.get(lifecycle_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(lifecycle_summary, "trust_boundaries", []),
      "branch_local_timeline_lifecycle_state_pressure" =>
        Map.get(pressure_fields, "branch_local_timeline_lifecycle_state_pressure"),
      "branch_local_lifecycle_review_pressure" =>
        Map.get(pressure_fields, "branch_local_lifecycle_review_pressure"),
      "branch_local_lifecycle_recordable_pressure" =>
        Map.get(pressure_fields, "branch_local_lifecycle_recordable_pressure"),
      "branch_local_lifecycle_preservation_pressure" =>
        Map.get(pressure_fields, "branch_local_lifecycle_preservation_pressure"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_timeline_lifecycle_state_replay_summary",
        "timeline_lifecycle_application" => "not_performed_by_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_lifecycle_state_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(lifecycle_fields)
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
end
