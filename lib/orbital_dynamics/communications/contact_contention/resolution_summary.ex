defmodule OrbitalDynamics.Communications.ContactContention.ResolutionSummary do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactContention.{
    CapacityDemand,
    ContactNormalization,
    ResolutionSummaryValues
  }

  @resolution_contract "contact_contention_resolution_report.v1"
  @resolution_summary_contract "contact_contention_resolution_summary.v1"

  def build(report, model_limits) do
    report = ContactNormalization.stringify_keys(report)
    recommendations = report |> Map.get("recommendations", []) |> Enum.filter(&is_map/1)

    review_recommendations =
      Enum.filter(recommendations, &(&1["review_status"] == "operator_review_required"))

    capacity_pack_demand = CapacityDemand.build(recommendations)

    %{
      "schema_contract" => @resolution_summary_contract,
      "model" => "artifact_only_contact_contention_resolution_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @resolution_contract),
      "model_limits" => model_limits,
      "conflict_group_count" =>
        length(ResolutionSummaryValues.values(recommendations, "group_id")),
      "recommendation_count" => length(recommendations),
      "policy" => report["policy"],
      "recommendation_group_ids" => ResolutionSummaryValues.values(recommendations, "group_id"),
      "review_group_ids" => ResolutionSummaryValues.values(review_recommendations, "group_id"),
      "selected_contact_ids" =>
        ResolutionSummaryValues.values(recommendations, "selected_contact_id"),
      "selected_contact_ids_by_group_id" =>
        ResolutionSummaryValues.values_by_field(
          recommendations,
          "group_id",
          "selected_contact_id"
        ),
      "deferred_contact_ids" =>
        ResolutionSummaryValues.list_values(recommendations, "deferred_contact_ids"),
      "deferred_contact_ids_by_group_id" =>
        ResolutionSummaryValues.list_values_by_field(
          recommendations,
          "group_id",
          "deferred_contact_ids"
        ),
      "ambiguous_group_ids" =>
        recommendations
        |> Enum.filter(&(&1["resolution_status"] == "ambiguous_contact_identity"))
        |> ResolutionSummaryValues.values("group_id"),
      "ambiguous_duplicate_contact_ids" =>
        ResolutionSummaryValues.list_values(recommendations, "duplicate_contact_ids"),
      "ambiguous_duplicate_contact_ids_by_group_id" =>
        ResolutionSummaryValues.list_values_by_field(
          recommendations,
          "group_id",
          "duplicate_contact_ids"
        ),
      "review_contact_ids" => ResolutionSummaryValues.review_contact_ids(review_recommendations),
      "review_contact_ids_by_group_id" =>
        ResolutionSummaryValues.review_contact_ids_by_field(review_recommendations, "group_id"),
      "review_recommendation_count" => length(review_recommendations),
      "resource_scope_counts" =>
        ResolutionSummaryValues.count_by_field(recommendations, "resource_scope"),
      "selected_contact_ids_by_resource_scope" =>
        ResolutionSummaryValues.values_by_field(
          recommendations,
          "resource_scope",
          "selected_contact_id"
        ),
      "deferred_contact_ids_by_resource_scope" =>
        ResolutionSummaryValues.list_values_by_field(
          recommendations,
          "resource_scope",
          "deferred_contact_ids"
        ),
      "review_contact_ids_by_resource_scope" =>
        ResolutionSummaryValues.review_contact_ids_by_field(
          review_recommendations,
          "resource_scope"
        ),
      "selection_reason_counts" =>
        ResolutionSummaryValues.count_by_field(recommendations, "selection_reason"),
      "selected_contact_ids_by_selection_reason" =>
        ResolutionSummaryValues.values_by_field(
          recommendations,
          "selection_reason",
          "selected_contact_id"
        ),
      "action_counts" => ResolutionSummaryValues.count_by_field(recommendations, "action"),
      "review_contact_ids_by_action" =>
        ResolutionSummaryValues.review_contact_ids_by_field(review_recommendations, "action"),
      "capacity_pack_required_capacity_fraction" =>
        capacity_pack_demand["capacity_pack_required_capacity_fraction"],
      "capacity_pack_selected_required_capacity_fraction" =>
        capacity_pack_demand["capacity_pack_selected_required_capacity_fraction"],
      "capacity_pack_deferred_required_capacity_fraction" =>
        capacity_pack_demand["capacity_pack_deferred_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_status" =>
        capacity_pack_demand["capacity_pack_required_capacity_fraction_by_status"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_demand["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_demand[
          "capacity_pack_selected_required_capacity_fraction_by_ground_station_id"
        ],
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        capacity_pack_demand[
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
        ],
      "required_capacity_fraction_source_counts" =>
        capacity_pack_demand["required_capacity_fraction_source_counts"],
      "required_capacity_fraction_contact_ids_by_source" =>
        capacity_pack_demand["required_capacity_fraction_contact_ids_by_source"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "candidate_mutation" => "none",
        "operator_authority" => "not_granted_by_summary",
        "source" => "contact_contention_resolution_report.v1"
      }
    }
    |> ContactNormalization.compact_map()
  end
end
