defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePreservation.Summary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePreservation.ReplayInput
  alias __MODULE__.Counts
  alias __MODULE__.RowValues

  def summary(refresh_or_artifact) do
    {rows, branch_rows?} =
      ReplayInput.rows_with_source(refresh_or_artifact)

    {summary_source, replay_scope} =
      if branch_rows? do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request.timeline_preservation",
          "timeline_preservation_candidate_source_review_provenance_only"
        }
      else
        {
          "candidate_refresh.review_provenance.timeline_preservation",
          "timeline_preservation_review_provenance_only"
        }
      end

    counts = Counts.counts(rows)

    preservation_required_rows =
      Enum.filter(rows, &(&1["timeline_preservation_status"] == "preservation_required"))

    review_required_rows =
      Enum.filter(rows, &(&1["timeline_preservation_status"] == "review_required"))

    preserve_rows =
      Enum.filter(rows, &(&1["timeline_preservation_protection_decision"] == "preserve"))

    review_change_rows =
      Enum.filter(rows, &(&1["timeline_preservation_protection_decision"] == "review_change"))

    action_routing = RowValues.action_routing(rows) |> empty_map_if_nil()

    trust_boundaries =
      rows
      |> RowValues.trust_boundaries()

    review_pressure = review_required_rows != []
    preservation_pressure = preservation_required_rows != [] or preserve_rows != []

    routing_pressure =
      map_size(counts.activity_id_counts) > 0 or map_size(counts.timeline_id_counts) > 0

    action_pressure = map_size(action_routing) > 0

    %{
      "model" => "artifact_only_candidate_refresh_timeline_preservation_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(%{"contract" => nil}, nil),
      "source_artifact_count" => length(counts.source_paths),
      "source_report_row_count" => length(rows),
      "source_report_paths" => counts.source_paths,
      "source_summary_schema_contract_counts" => counts.source_contract_counts,
      "source_summary_model_counts" => counts.source_model_counts,
      "timeline_preservation_status_counts" => counts.preservation_status_counts,
      "required_operator_action_counts" => counts.required_action_counts,
      "protection_decision_counts" => counts.protection_decision_counts,
      "protection_category_counts" => counts.protection_category_counts,
      "protection_reason_counts" => counts.protection_reason_counts,
      "activity_id_counts" => counts.activity_id_counts,
      "timeline_id_counts" => counts.timeline_id_counts,
      "preservation_required_activity_ids" =>
        RowValues.ids(preservation_required_rows, "activity_id"),
      "preservation_required_timeline_ids" =>
        RowValues.ids(preservation_required_rows, "timeline_id"),
      "review_required_activity_ids" => RowValues.ids(review_required_rows, "activity_id"),
      "review_required_timeline_ids" => RowValues.ids(review_required_rows, "timeline_id"),
      "preserve_activity_ids" => RowValues.ids(preserve_rows, "activity_id"),
      "preserve_timeline_ids" => RowValues.ids(preserve_rows, "timeline_id"),
      "review_change_activity_ids" => RowValues.ids(review_change_rows, "activity_id"),
      "review_change_timeline_ids" => RowValues.ids(review_change_rows, "timeline_id"),
      "action_routing" => action_routing,
      "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
      "trust_boundaries" => trust_boundaries,
      "branch_local_timeline_preservation_pressure" => rows != [],
      "branch_local_timeline_preservation_review_pressure" => review_pressure,
      "branch_local_timeline_preservation_record_pressure" => preservation_pressure,
      "branch_local_timeline_preservation_action_pressure" => action_pressure,
      "branch_local_timeline_preservation_routing_pressure" => routing_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_timeline_preservation_replay_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "timeline_preservation_application" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_preservation_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
