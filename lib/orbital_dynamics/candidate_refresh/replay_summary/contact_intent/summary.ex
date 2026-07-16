defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.Summary do
  @moduledoc false

  import __MODULE__.Values,
    only: [
      compact_map: 1,
      numeric_value: 1,
      source_report_summary_contract: 2,
      summary_integer: 2
    ]

  alias __MODULE__.ContactCount
  alias __MODULE__.Pressure

  def summary(intent_summary, summary_source, replay_scope) do
    station_feedback_count = summary_integer(intent_summary, "station_feedback_count")

    source_report_row_count =
      ContactCount.contact_count(intent_summary, "row_count")

    required_contact_count =
      ContactCount.capacity_pack_contact_count(
        intent_summary,
        "capacity_pack_required_contact_count"
      )

    required_capacity_fraction =
      numeric_value(Map.get(intent_summary, "capacity_pack_required_capacity_fraction")) || 0.0

    station_calendar_status_counts =
      Map.get(intent_summary, "station_calendar_status_counts", %{})

    cadence_import_status_counts =
      Map.get(intent_summary, "cadence_import_status_counts", %{})

    policy_classification_counts =
      Map.get(intent_summary, "policy_classification_counts", %{})

    required_by_station =
      Map.get(intent_summary, "capacity_pack_required_capacity_fraction_by_ground_station", %{})

    required_by_direction =
      Map.get(intent_summary, "capacity_pack_required_capacity_fraction_by_direction", %{})

    required_by_direction_and_station =
      Map.get(
        intent_summary,
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station",
        %{}
      )

    required_source_counts =
      Map.get(intent_summary, "required_capacity_fraction_source_counts", %{})

    required_contact_ids_by_source =
      Map.get(intent_summary, "required_capacity_fraction_contact_ids_by_source", %{})

    capacity_contact_ids_by_station =
      Map.get(intent_summary, "capacity_pack_contact_ids_by_ground_station", %{})

    contact_ids_by_station = Map.get(intent_summary, "contact_ids_by_ground_station", %{})

    capacity_contact_ids_by_direction =
      Map.get(intent_summary, "capacity_pack_contact_ids_by_direction", %{})

    capacity_contact_ids_by_direction_and_station =
      Map.get(intent_summary, "capacity_pack_contact_ids_by_direction_and_ground_station", %{})

    contact_ids_by_direction_and_station =
      Map.get(intent_summary, "contact_ids_by_direction_and_ground_station", %{})

    directions = Map.get(intent_summary, "directions", [])
    direction_counts = Map.get(intent_summary, "direction_counts", %{})
    contact_ids_by_direction = Map.get(intent_summary, "contact_ids_by_direction", %{})

    direction_routing =
      intent_summary
      |> Map.get("direction_routing", %{})
      |> normalize_direction_routing()

    pressure_fields =
      Pressure.fields(%{
        station_feedback_count: station_feedback_count,
        required_contact_count: required_contact_count,
        station_calendar_status_counts: station_calendar_status_counts,
        cadence_import_status_counts: cadence_import_status_counts,
        policy_classification_counts: policy_classification_counts,
        required_capacity_fraction: required_capacity_fraction,
        required_by_station: required_by_station,
        required_by_direction: required_by_direction,
        required_by_direction_and_station: required_by_direction_and_station,
        required_source_counts: required_source_counts,
        required_contact_ids_by_source: required_contact_ids_by_source,
        capacity_contact_ids_by_station: capacity_contact_ids_by_station,
        contact_ids_by_station: contact_ids_by_station,
        capacity_contact_ids_by_direction: capacity_contact_ids_by_direction,
        capacity_contact_ids_by_direction_and_station:
          capacity_contact_ids_by_direction_and_station,
        contact_ids_by_direction_and_station: contact_ids_by_direction_and_station,
        directions: directions,
        direction_counts: direction_counts,
        contact_ids_by_direction: contact_ids_by_direction,
        direction_routing: direction_routing
      })

    %{
      "model" => "artifact_only_candidate_refresh_contact_intent_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(intent_summary, "contact_intent.v1"),
      "source_report_count" => summary_integer(intent_summary, "count"),
      "source_report_row_count" => source_report_row_count,
      "source_report_paths" => Map.get(intent_summary, "paths", []),
      "station_feedback_count" => station_feedback_count,
      "station_calendar_status_counts" => station_calendar_status_counts,
      "cadence_import_status_counts" => cadence_import_status_counts,
      "policy_classification_counts" => policy_classification_counts,
      "capacity_pack_required_contact_count" => required_contact_count,
      "capacity_pack_required_capacity_fraction" => required_capacity_fraction,
      "capacity_pack_required_capacity_fraction_by_ground_station" => required_by_station,
      "capacity_pack_required_capacity_fraction_by_direction" => required_by_direction,
      "capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
        required_by_direction_and_station,
      "required_capacity_fraction_source_counts" => required_source_counts,
      "required_capacity_fraction_contact_ids_by_source" => required_contact_ids_by_source,
      "capacity_pack_contact_ids_by_ground_station" => capacity_contact_ids_by_station,
      "contact_ids_by_ground_station" => contact_ids_by_station,
      "capacity_pack_contact_ids_by_direction" => capacity_contact_ids_by_direction,
      "capacity_pack_contact_ids_by_direction_and_ground_station" =>
        capacity_contact_ids_by_direction_and_station,
      "directions" => directions,
      "direction_counts" => direction_counts,
      "contact_ids_by_direction" => contact_ids_by_direction,
      "contact_ids_by_direction_and_ground_station" => contact_ids_by_direction_and_station,
      "direction_routing" => direction_routing,
      "trust_boundary_status" => Map.get(intent_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(intent_summary, "trust_boundaries", []),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_contact_intent_replay_summary",
        "contact_generation" => "not_performed_by_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_intent_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Map.merge(pressure_fields)
    |> compact_map()
  end

  defp normalize_direction_routing(%{} = direction_routing) do
    Map.new(direction_routing, fn {direction, route} ->
      {direction, normalize_direction_route(route)}
    end)
  end

  defp normalize_direction_routing(_direction_routing), do: %{}

  defp normalize_direction_route(%{} = route) do
    route
    |> normalize_list_field("contact_ids")
    |> normalize_list_field("capacity_pack_contact_ids")
    |> normalize_list_field("ground_station_ids")
  end

  defp normalize_direction_route(route), do: route

  defp normalize_list_field(route, field) when not is_map_key(route, field), do: route

  defp normalize_list_field(route, field) do
    Map.update!(route, field, fn
      %{} = empty_map when map_size(empty_map) == 0 -> []
      values when is_list(values) -> values
      value -> value
    end)
  end
end
