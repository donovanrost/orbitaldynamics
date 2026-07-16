defmodule OrbitalDynamics.CandidateRefresh.DownlinkCandidate do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.CandidateActivityFields
  alias OrbitalDynamics.CandidateRefresh.ContactSuccess
  alias OrbitalDynamics.CandidateRefresh.DownlinkCompletionObjectives
  alias OrbitalDynamics.CandidateRefresh.DownlinkDemand
  alias OrbitalDynamics.CandidateRefresh.DownlinkStationContext
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common

  def build(
        result,
        {event, index},
        refresh,
        policy,
        operational_feedback_fun,
        refresh_objectives_fun,
        refresh_ground_network_fun
      ) do
    starts_at_s = CandidateActivityFields.epoch_seconds(event.starts_at)
    ends_at_s = CandidateActivityFields.epoch_seconds(event.ends_at)
    ground_station_id = result.source.ground_station_id
    duration_s = ends_at_s - starts_at_s
    downlink_rate_mb_s = Map.get(policy, "downlink_rate_mb_s", 1.0)

    {station_context, station_throughput_context, capacity_fraction} =
      DownlinkStationContext.build(
        refresh,
        ground_station_id,
        starts_at_s,
        ends_at_s,
        refresh_ground_network_fun,
        operational_feedback_fun
      )

    {contact_success_factor, contact_success_source} =
      ContactSuccess.factor(refresh, ground_station_id, operational_feedback_fun)

    id =
      CandidateActivityFields.activity_id(
        result.scenario_id,
        "downlink",
        ground_station_id,
        index
      )

    source_window_id =
      CandidateActivityFields.window_id(
        result.scenario_id,
        "ground_station_access",
        ground_station_id,
        index
      )

    estimated_throughput_mb = duration_s * downlink_rate_mb_s * capacity_fraction

    {downlink_completion_context, downlink_completion_score_terms} =
      downlink_completion_context(
        refresh,
        result.scenario_id,
        ground_station_id,
        estimated_throughput_mb,
        policy,
        operational_feedback_fun,
        refresh_objectives_fun
      )

    downlink_demand_context =
      DownlinkDemand.context(refresh, ground_station_id, operational_feedback_fun)

    base_contact_value =
      duration_s * CandidateActivityFields.policy_number(policy, "contact_value_weight", 0.1) *
        capacity_fraction

    score_terms =
      %{
        "contact_value" => base_contact_value,
        "contact_success_adjustment" => base_contact_value * (contact_success_factor - 1.0)
      }
      |> Map.merge(downlink_completion_score_terms)

    %{
      "id" => id,
      "type" => "downlink",
      "direction" => "downlink",
      "scenario_id" => encode_value(result.scenario_id),
      "ground_station_id" => encode_value(ground_station_id),
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => duration_s,
      "estimated_throughput_mb" => estimated_throughput_mb,
      "contact_success_factor" => contact_success_factor,
      "contact_success_factor_source" => contact_success_source,
      "throughput_model" =>
        %{
          "model" => "fixed_rate_from_candidate_refresh_policy",
          "downlink_rate_mb_s" => downlink_rate_mb_s,
          "contact_success_factor" => contact_success_factor,
          "confidence_source" => contact_success_source
        }
        |> Map.merge(station_throughput_context)
        |> Map.merge(downlink_completion_context)
        |> Common.compact_map(),
      "schedule_conflict_status" => "not_evaluated",
      "score" => CandidateActivityFields.score(score_terms),
      "score_terms" => score_terms,
      "source_window_id" => source_window_id,
      "source_window" =>
        %{
          "id" => source_window_id,
          "type" => "ground_station_access",
          "max_elevation_deg" => event.metadata.max_elevation_deg,
          "minimum_elevation_deg" => event.metadata.minimum_elevation_deg
        }
        |> Map.merge(CandidateActivityFields.event_timing_metadata(event.metadata)),
      "cadence_import" => %{
        "activity_type" => "contact",
        "external_id" => id,
        "schema_contract" => "proposed_contact.v1"
      }
    }
    |> Map.merge(station_context)
    |> Map.merge(downlink_completion_context)
    |> Map.merge(downlink_demand_context)
    |> Common.compact_map()
  end

  defp downlink_completion_context(
         refresh,
         scenario_id,
         ground_station_id,
         estimated_throughput_mb,
         policy,
         operational_feedback_fun,
         refresh_objectives_fun
       ) do
    case DownlinkDemand.required_mb(
           refresh,
           scenario_id,
           ground_station_id,
           refresh_objectives_fun,
           operational_feedback_fun
         ) do
      {required_downlink_mb, source, sources}
      when is_number(required_downlink_mb) and required_downlink_mb > 0.0 ->
        ratio = min(estimated_throughput_mb / required_downlink_mb, 1.0)
        shortfall_mb = max(required_downlink_mb - estimated_throughput_mb, 0.0)
        weight = CandidateActivityFields.policy_number(policy, "downlink_completion_weight", 50.0)

        objective_context =
          DownlinkCompletionObjectives.context(
            refresh,
            scenario_id,
            ground_station_id,
            refresh_objectives_fun
          )

        {
          %{
            "required_downlink_mb" => required_downlink_mb,
            "candidate_downlink_mb" => estimated_throughput_mb,
            "downlink_completion_ratio" => ratio,
            "selected_downlink_shortfall_mb" => shortfall_mb,
            "downlink_requirement_status" =>
              if(shortfall_mb > 0.0, do: "shortfall", else: "satisfied"),
            "downlink_completion_source" => source,
            "downlink_completion_sources" => sources
          }
          |> Map.merge(objective_context)
          |> Common.compact_map(),
          %{"downlink_completion_value" => ratio * weight}
        }

      _requirement ->
        {%{}, %{}}
    end
  end

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
