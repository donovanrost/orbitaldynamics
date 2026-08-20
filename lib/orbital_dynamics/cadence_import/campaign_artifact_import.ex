defmodule OrbitalDynamics.CadenceImport.CampaignArtifactImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{JsonNormalization, ReviewSummaryContext}
  alias OrbitalDynamics.OperatorReview

  @review_types ~w(
    contact_contention_recommendation
    contact_contention_review
    operational_timeline_review
    timeline_integrity_review
    command_window_review
    station_calendar_review
    link_capacity_review
    resource_projection_review
    timeline_activity_precondition_review
    objective_satisfaction_review
    local_search_review
    score_term_review
    objective_tradeoff_review
    contact_allocation_review
    contact_intent_review
    constraint_review
  )

  def build(artifact, opts, callbacks) do
    artifact = JsonNormalization.stringify_keys(artifact)
    source_id = Keyword.get(opts, :source_artifact_id, artifact["plan_id"])
    review_package = OperatorReview.from_campaign_artifact(artifact)

    rows =
      artifact
      |> Map.get("proposed_contacts", [])
      |> Enum.map(&JsonNormalization.stringify_keys/1)
      |> Enum.sort_by(&{Map.get(&1, "starts_at_s", 0.0), Map.get(&1, "id", "")})
      |> Enum.with_index(1)
      |> Enum.map(fn {contact, rank} ->
        callback(callbacks, :proposed_contact_row).(contact, rank)
      end)

    review_rows =
      review_package
      |> Map.get("rows", [])
      |> Enum.filter(&(&1["review_type"] in @review_types))
      |> Enum.with_index(length(rows) + 1)
      |> Enum.map(fn {row, rank} -> callback(callbacks, :review_row).(row, rank) end)

    summary_context = ReviewSummaryContext.build(review_package)

    callback(callbacks, :build_manifest).(
      rows ++ review_rows,
      %{
        "source" => "OrbitalDynamics.CadenceImport.from_campaign_artifact",
        "source_artifact_type" => "campaign_plan.v1",
        "source_artifact_id" => source_id,
        "source_plan_id" => artifact["plan_id"],
        "source_proposed_contact_count" => length(Map.get(artifact, "proposed_contacts", []))
      }
      |> Map.merge(summary_context),
      %{
        "source_artifact_type" => "campaign_plan.v1",
        "source_artifact_id" => source_id,
        "row_source" => row_source(artifact),
        "deterministic_ordering" =>
          "proposed_contacts_starts_at_s_then_contact_id_then_operator_review_row_order"
      }
      |> Map.merge(summary_context)
    )
  end

  defp row_source(%{"optimizer_search_trace" => %{}}) do
    "campaign_plan.proposed_contacts_contact_contention_groups_recommendations_operational_timeline_integrity_activity_precondition_command_window_station_calendar_link_capacity_resource_projection_objective_satisfaction_local_search_score_term_objective_tradeoff_and_contact_allocation_rows"
  end

  defp row_source(_artifact) do
    "campaign_plan.proposed_contacts_contact_contention_groups_recommendations_operational_timeline_integrity_activity_precondition_command_window_station_calendar_link_capacity_resource_projection_objective_satisfaction_score_term_objective_tradeoff_and_contact_allocation_rows"
  end

  defp callback(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
