defmodule OrbitalDynamics.Communications.ContactFilter do
  @moduledoc """
  Artifact-only ground-network availability filtering for contact candidates.

  The filter suppresses downlink, tracking, and health-check candidates when an
  externally supplied ground station calendar declares an overlapping outage,
  reservation, or zero-capacity interval. It does not reserve provider time,
  mutate schedules, or simulate station operations.
  """

  @schema_contract "contact_filter_report.v1"
  @suppressed_directions ~w(downlink tracking health_check)
  @unavailable_aliases ["outage", "down", "offline"]
  @station_availability_severity %{
    "unavailable" => 5,
    "maintenance" => 5,
    "reserved" => 4,
    "reduced_capacity" => 3,
    "available" => 1
  }
  @capacity_fraction_paths [
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"]
  ]
  @capacity_percent_paths [
    ["capacity_percent"],
    ["station_capacity_percent"]
  ]
  @capacity_value_paths [
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["capacity_percent"]},
    {:percent, ["station_capacity_percent"]}
  ]
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  alias OrbitalDynamics.Policy
  alias OrbitalDynamics.Communications.ContactFilter.ContactNormalization
  alias OrbitalDynamics.Communications.ContactFilter.ProviderCounterofferContext
  alias OrbitalDynamics.Communications.StationCalendar

  @doc """
  Declares the contact filter model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      model: :thin_ground_network_availability_filter,
      validation_level: :artifact_contract,
      suppressed_directions: @suppressed_directions,
      station_unavailable_aliases: @unavailable_aliases,
      station_availability_precedence: @station_availability_severity,
      station_capacity_fraction_paths: @capacity_fraction_paths,
      station_capacity_percent_paths: @capacity_percent_paths,
      station_capacity_value_paths: capacity_value_path_metadata(@capacity_value_paths),
      contact_capacity_fraction_paths: @capacity_fraction_paths,
      contact_capacity_percent_paths: @capacity_percent_paths,
      contact_capacity_value_paths: capacity_value_path_metadata(@capacity_value_paths),
      provider_direction_aliases: ContactNormalization.provider_direction_aliases(),
      provider_result_map_value_keys: @provider_result_map_value_keys,
      provider_counteroffer_fields: ProviderCounterofferContext.fields(),
      contact_stable_identity_fields: ContactNormalization.stable_identity_fields(),
      row_semantics: [
        :invalid_contact_input_review,
        :feedback_unit_interval_input_validation,
        :ground_network_availability_suppression,
        :station_calendar_provider_input,
        :station_calendar_provider_list_input,
        :direction_scoped_station_calendar,
        :station_capacity_value_paths,
        :contact_capacity_value_paths,
        :contact_stable_identity_fields,
        :provider_direction_aliases,
        :provider_result_map_value_keys,
        :provider_counteroffer_review_handoff,
        :provider_counteroffer_fields,
        :station_calendar_entry_identity_preservation,
        :station_reservation_identity_match,
        :station_reservation_owner_match,
        :station_calendar_reservation_expiration_context,
        :station_reservation_match_status_counts,
        :station_reservation_match_status_id_routing,
        :station_calendar_trust_boundary_status_id_routing,
        :contact_filter_suppression_reason_counts,
        :contact_filter_suppression_reason_id_routing,
        :no_schedule_mutation
      ],
      suppression_reasons: [
        "invalid_contact_input",
        "provider_counteroffer_review",
        "ground_station_reserved",
        "ground_station_unavailable",
        "ground_station_capacity_zero"
      ],
      known_limits: [
        :artifact_level_only,
        :externally_supplied_ground_network,
        :no_provider_reservation,
        :no_schedule_mutation,
        :no_link_budget_model
      ]
    }
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  defp capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn {unit, path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp capability_assumptions do
    %{
      "suppressed_directions" => @suppressed_directions,
      "suppression_reasons" => capabilities().suppression_reasons,
      "station_unavailable_aliases" => @unavailable_aliases,
      "station_availability_precedence" => @station_availability_severity,
      "station_capacity_value_paths" => capacity_value_path_assumptions(@capacity_value_paths),
      "contact_capacity_value_paths" => capacity_value_path_assumptions(@capacity_value_paths),
      "provider_direction_aliases" => ContactNormalization.provider_direction_aliases()
    }
  end

  @doc """
  Filters contact candidates using externally supplied ground-network entries,
  a `station_calendar_provider.v1` object, or a list of provider artifacts.

  Returns `{kept_candidates, contact_filter_report}`. Non-downlink/tracking/health-check
  candidates pass through unchanged.
  """
  def filter_candidates(candidates, ground_network, opts \\ [])

  def filter_candidates(candidates, %{} = station_calendar_provider, opts)
      when is_list(candidates) do
    filter_candidates(
      candidates,
      StationCalendar.to_ground_network(station_calendar_provider),
      opts
    )
  end

  def filter_candidates(candidates, ground_network, opts)
      when is_list(candidates) and is_list(ground_network) do
    candidates = Enum.map(candidates, &normalize_contact/1)

    ground_network =
      ground_network
      |> Enum.flat_map(&normalize_ground_network_entry_or_provider/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)

    {invalid_candidate_inputs, valid_candidates} =
      candidates
      |> Enum.with_index(1)
      |> Enum.split_with(fn {candidate, _index} -> invalid_contact_input?(candidate) end)

    valid_candidates = Enum.map(valid_candidates, fn {candidate, _index} -> candidate end)

    {kept, suppressed} =
      Enum.reduce(valid_candidates, {[], []}, fn candidate, {kept, suppressed} ->
        case suppression(candidate, ground_network) do
          nil ->
            {[candidate | kept], suppressed}

          {reason, station_state} ->
            {kept, [suppressed_candidate(candidate, reason, station_state) | suppressed]}
        end
      end)

    kept = Enum.reverse(kept)
    approval_policy = Keyword.get(opts, :approval_policy)
    invalid_rows = invalid_contact_rows(invalid_candidate_inputs)

    suppressed =
      (invalid_rows ++ Enum.reverse(suppressed))
      |> disambiguate_suppressed_candidate_ids()
      |> Enum.map(&maybe_apply_approval_policy(&1, approval_policy))

    duplicate_suppressed_candidate_id_groups =
      duplicate_suppressed_candidate_id_groups(suppressed)

    report =
      %{
        "schema_contract" => @schema_contract,
        "model" => "thin_ground_network_availability_filter",
        "model_limits" => model_limits(),
        "assumptions" =>
          Map.merge(
            %{
              "execution_boundary" =>
                "artifact_only_no_provider_reservation_or_schedule_mutation",
              "operator_authority" => "not_granted_by_filter"
            },
            capability_assumptions()
          ),
        "input_candidate_count" => length(candidates),
        "kept_candidate_count" => length(kept),
        "suppressed_candidate_count" => length(suppressed),
        "invalid_contact_input_count" =>
          Enum.count(suppressed, &(&1["invalid_contact_input"] == true)),
        "invalid_contact_input_ids" =>
          suppressed
          |> Enum.filter(&(&1["invalid_contact_input"] == true))
          |> Enum.map(& &1["id"]),
        "suppression_reason_counts" => suppression_reason_counts(suppressed),
        "suppressed_candidate_ids_by_reason" =>
          suppressed_candidate_ids_by_field(suppressed, "suppressed_reason"),
        "station_reservation_match_status_counts" =>
          station_reservation_match_status_counts(suppressed),
        "suppressed_candidate_ids_by_reservation_match_status" =>
          suppressed_candidate_ids_by_field(suppressed, "station_reservation_match_status"),
        "station_calendar_trust_boundary_status_counts" =>
          station_calendar_trust_boundary_status_counts(suppressed),
        "suppressed_candidate_ids_by_station_calendar_trust_boundary_status" =>
          suppressed_candidate_ids_by_field(suppressed, "station_calendar_trust_boundary_status"),
        "duplicate_suppressed_candidate_id_count" =>
          length(duplicate_suppressed_candidate_id_groups),
        "duplicate_suppressed_candidate_row_count" =>
          duplicate_suppressed_candidate_row_count(duplicate_suppressed_candidate_id_groups),
        "suppressed_candidates" => suppressed
      }
      |> compact_map()
      |> maybe_put_policy(Keyword.get(opts, :policy))

    {kept, report}
  end

  def filter_candidates(_candidates, _ground_network, _opts),
    do: raise(ArgumentError, "candidates and ground network must be lists")

  defp normalize_ground_network_entry_or_provider(%{} = entry) do
    entry = stringify_keys(entry)

    if station_calendar_provider_artifact?(entry) do
      StationCalendar.to_ground_network(entry)
    else
      [entry]
    end
  end

  defp normalize_ground_network_entry_or_provider(_entry), do: []

  defp station_calendar_provider_artifact?(%{
         "schema_contract" => "station_calendar_provider.v1"
       }),
       do: true

  defp station_calendar_provider_artifact?(_entry), do: false

  @doc """
  Builds only the `contact_filter_report.v1`, discarding kept candidates.
  """
  def report(contact_filter_report)

  def report(%{"schema_contract" => @schema_contract} = report) do
    report
  end

  def report(%{schema_contract: @schema_contract} = report) do
    stringify_keys(report)
  end

  def report(_contact_filter_report),
    do: raise(ArgumentError, "contact filter report must be a map")

  def report(candidates, ground_network, opts \\ []) do
    {_kept, report} = filter_candidates(candidates, ground_network, opts)
    report
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp suppression(candidate, ground_network) do
    if suppressible_station_contact?(candidate),
      do: station_contact_suppression(candidate, ground_network)
  end

  defp invalid_contact_input?(candidate) do
    contact_like_input?(candidate) and not valid_contact_filter_input?(candidate)
  end

  defp contact_like_input?(%{"invalid_contact_shape" => true}), do: true

  defp contact_like_input?(%{"type" => type}) when type in @suppressed_directions, do: true

  defp contact_like_input?(%{"type" => "planned_contact", "direction" => direction})
       when direction in @suppressed_directions,
       do: true

  defp contact_like_input?(%{"direction" => direction}) when direction in @suppressed_directions,
    do: true

  defp contact_like_input?(candidate), do: provider_downlink_contact_input?(candidate)

  defp provider_downlink_contact_input?(candidate) do
    Map.get(candidate, "type") in [nil, "contact", "planned_contact"] and
      Map.get(candidate, "direction") in [nil, "downlink"] and
      provider_contact_evidence?(candidate)
  end

  defp provider_contact_evidence?(candidate) do
    Enum.any?(
      [
        Map.get(candidate, "id"),
        Map.get(candidate, "contact_id"),
        Map.get(candidate, "activity_id"),
        Map.get(candidate, "ground_station_id"),
        Map.get(candidate, "station"),
        Map.get(candidate, "ground_station"),
        Map.get(candidate, "starts_at_s"),
        Map.get(candidate, "ends_at_s"),
        Map.get(candidate, "source_window_id"),
        Map.get(candidate, "estimated_throughput_mb"),
        Map.get(candidate, "actual_throughput_mb")
      ],
      fn value -> not is_nil(value) end
    )
  end

  defp valid_contact_filter_input?(candidate) do
    is_nil(contact_id_issue(candidate)) and
      is_nil(contact_identity_issue(candidate)) and
      is_nil(contact_feedback_factor_issue(candidate)) and
      not is_nil(candidate["ground_station_id"]) and
      is_number(candidate["starts_at_s"]) and
      is_number(candidate["ends_at_s"])
  end

  defp invalid_contact_input_reason(candidate) do
    cond do
      Map.get(candidate, "invalid_contact_shape") == true -> "invalid_contact_shape"
      reason = contact_id_issue(candidate) -> reason
      reason = contact_identity_issue(candidate) -> reason
      reason = contact_feedback_factor_issue(candidate) -> reason
      is_nil(candidate["ground_station_id"]) -> "missing_ground_station_id"
      not is_number(candidate["starts_at_s"]) -> "missing_contact_starts_at_s"
      not is_number(candidate["ends_at_s"]) -> "missing_contact_ends_at_s"
      true -> "invalid_contact_input"
    end
  end

  defp contact_feedback_factor_issue(candidate) do
    Enum.find_value(["contact_success_factor", "command_success_factor"], fn field ->
      case candidate_value(candidate, field) do
        nil ->
          nil

        value ->
          case numeric_or_nil(value) do
            number when is_number(number) ->
              if number >= 0.0 and number <= 1.0, do: nil, else: "invalid_#{field}"

            _value ->
              "invalid_#{field}"
          end
      end
    end)
  end

  defp invalid_contact_rows(invalid_candidate_inputs) do
    Enum.map(invalid_candidate_inputs, fn {candidate, index} ->
      reason = invalid_contact_input_reason(candidate)
      candidate_id = candidate_id(candidate) || invalid_contact_row_id(reason, index)
      scenario_id = stable_id_or_nil(candidate["scenario_id"]) || "missing_scenario_id:#{index}"

      %{
        "id" => candidate_id,
        "type" =>
          candidate["type"] || contact_type_from_direction(candidate) || "invalid_contact_input",
        "scenario_id" => scenario_id,
        "spacecraft_id" => contact_spacecraft_id(candidate),
        "ground_station_id" => stable_id_or_nil(candidate["ground_station_id"]),
        "starts_at_s" => candidate["starts_at_s"],
        "ends_at_s" => candidate["ends_at_s"],
        "source_window_id" => stable_id_or_nil(candidate["source_window_id"]),
        "direction" => candidate["direction"] || contact_direction(candidate),
        "station_calendar_entry_id" => contact_station_calendar_entry_id(candidate, %{}),
        "source_station_calendar_entry" => candidate["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => candidate["source_station_calendar_overlaps"],
        "suppressed_reason" => "invalid_contact_input",
        "invalid_contact_input" => true,
        "invalid_contact_input_reason" => reason,
        "required_operator_action" => "review_invalid_contact_filter_input",
        "approval_status" => "operator_review_required",
        "review_status" => "operator_review_required",
        "source_contact_candidate" => candidate
      }
      |> compact_map()
    end)
  end

  defp invalid_contact_row_id("invalid_contact_shape", index), do: "missing_contact_id:#{index}"
  defp invalid_contact_row_id(reason, index), do: "#{reason}:#{index}"

  defp station_contact_suppression(candidate, ground_network) do
    station_state =
      candidate
      |> station_states_for_candidate(ground_network)
      |> highest_severity_station_state()

    cond do
      station_unavailable?(station_state) ->
        {"ground_station_unavailable", station_state}

      provider_counteroffer_review?(station_state) ->
        {"provider_counteroffer_review", station_state}

      station_reserved?(station_state) and
          not station_reservation_matched?(candidate, station_state) ->
        {"ground_station_reserved", station_state}

      station_capacity_fraction(station_state) <= 0.0 ->
        {"ground_station_capacity_zero", station_state}

      true ->
        nil
    end
  end

  defp station_states_for_candidate(candidate, ground_network) do
    ground_network_state =
      station_state(
        ground_network,
        candidate["ground_station_id"],
        candidate["starts_at_s"],
        candidate["ends_at_s"],
        contact_direction(candidate)
      )

    [
      ground_network_state,
      direct_candidate_station_state(candidate)
    ]
    |> Enum.reject(&empty_station_state?/1)
  end

  defp highest_severity_station_state([]), do: %{}

  defp highest_severity_station_state(station_states),
    do: Enum.max_by(station_states, &station_severity/1)

  defp empty_station_state?(station), do: station in [%{}, nil]

  defp direct_candidate_station_state(candidate) do
    station_state =
      Map.take(candidate, [
        "availability",
        "capacity_fraction",
        "ground_station_id",
        "provenance",
        "provider_counteroffer_id",
        "provider_counteroffer_status",
        "provider_counteroffer_negotiation_state",
        "provider_counteroffer_reason_code",
        "provider_counteroffer_cost_delta",
        "provider_counteroffer_lock_deadline_s",
        "provider_counteroffer_starts_at_s",
        "provider_counteroffer_ends_at_s",
        "provider_counteroffer_start_delta_s",
        "provider_counteroffer_end_delta_s",
        "provider_counteroffer_duration_delta_s",
        "reservation_id",
        "reservation_expires_at_s",
        "reservation_match_status",
        "reservation_status",
        "reserved_by",
        "source_station_calendar_entry",
        "source_station_calendar_overlaps",
        "station_availability",
        "station_calendar_ambiguous_entry_count",
        "station_calendar_ambiguous_entry_ids",
        "station_calendar_directions",
        "station_calendar_entry_ambiguous",
        "station_calendar_entry_id",
        "station_calendar_overlap_availabilities",
        "station_calendar_overlap_count",
        "station_calendar_overlap_entry_ids",
        "station_calendar_reservation_expires_at_s",
        "station_calendar_reservation_ids",
        "station_calendar_reservation_overlap_count",
        "station_calendar_reservation_statuses",
        "station_calendar_reserved_by",
        "station_calendar_status",
        "station_calendar_trust_boundary_status",
        "station_capacity_fraction",
        "station_contention_status",
        "station_reservation_id",
        "station_reservation_expires_at_s",
        "station_reservation_match_status",
        "station_reservation_status",
        "station_reserved_by",
        "trust_boundary"
      ])

    if direct_candidate_station_evidence?(candidate) and
         direct_candidate_station_blocking_evidence?(station_state) do
      station_state
    else
      %{}
    end
  end

  defp direct_candidate_station_blocking_evidence?(station_state) do
    station_unavailable?(station_state) or provider_counteroffer_review?(station_state) or
      station_capacity_fraction(station_state) <= 0.0
  end

  defp direct_candidate_station_evidence?(candidate) do
    [
      candidate["availability"],
      candidate["capacity_fraction"],
      candidate["source_station_calendar_entry"],
      candidate["source_station_calendar_overlaps"],
      candidate["station_availability"],
      candidate["station_calendar_entry_id"],
      candidate["station_calendar_status"],
      candidate["station_capacity_fraction"],
      candidate["station_contention_status"]
    ]
    |> Enum.any?(&present_station_evidence?/1)
  end

  defp present_station_evidence?(value), do: value not in [nil, "", [], %{}]

  defp suppressible_station_contact?(%{"type" => type}) when type in @suppressed_directions,
    do: true

  defp suppressible_station_contact?(%{"type" => "planned_contact", "direction" => direction})
       when direction in @suppressed_directions,
       do: true

  defp suppressible_station_contact?(%{
         "direction" => direction,
         "ground_station_id" => station_id
       })
       when direction in @suppressed_directions and not is_nil(station_id),
       do: true

  defp suppressible_station_contact?(candidate) do
    provider_downlink_contact_input?(candidate) and not is_nil(candidate["ground_station_id"])
  end

  defp contact_type_from_direction(%{"direction" => direction})
       when direction in @suppressed_directions,
       do: direction

  defp contact_type_from_direction(candidate) do
    if provider_downlink_contact_input?(candidate), do: "downlink"
  end

  defp reviewable_station_contact?(%{"type" => type}) when type in @suppressed_directions,
    do: true

  defp reviewable_station_contact?(%{"type" => "planned_contact", "direction" => direction})
       when direction in @suppressed_directions,
       do: true

  defp reviewable_station_contact?(%{"direction" => direction, "ground_station_id" => station_id})
       when direction in @suppressed_directions and not is_nil(station_id),
       do: true

  defp reviewable_station_contact?(candidate) do
    provider_downlink_contact_input?(candidate) and not is_nil(candidate["ground_station_id"])
  end

  defp contact_suppression_action(row) do
    cond do
      is_binary(row["required_operator_action"]) ->
        row["required_operator_action"]

      reviewable_station_contact?(row) ->
        "review_suppressed_contact"

      true ->
        "review_suppressed_candidate"
    end
  end

  defp contact_direction(%{"direction" => direction}) when is_binary(direction), do: direction
  defp contact_direction(%{"type" => type}) when type in @suppressed_directions, do: type
  defp contact_direction(row), do: if(provider_downlink_contact_input?(row), do: "downlink")

  defp normalize_contact(contact),
    do: ContactNormalization.normalize(contact, @unavailable_aliases, @suppressed_directions)

  defp normalize_station_calendar_status_fields(row),
    do: ContactNormalization.normalize_station_calendar_status_fields(row, @unavailable_aliases)

  defp contact_spacecraft_id(contact),
    do: ContactNormalization.contact_spacecraft_id(contact)

  defp candidate_id(candidate), do: ContactNormalization.candidate_id(candidate)
  defp contact_id_issue(candidate), do: ContactNormalization.contact_id_issue(candidate)

  defp contact_identity_issue(candidate),
    do: ContactNormalization.contact_identity_issue(candidate)

  defp stable_id?(value), do: ContactNormalization.stable_id?(value)
  defp stable_id_or_nil(value), do: ContactNormalization.stable_id_or_nil(value)

  defp station_state(ground_network, ground_station_id, starts_at_s, ends_at_s, direction) do
    ground_network
    |> Enum.filter(fn station ->
      station_id = ground_network_station_id(station)

      station_id == encode_value(ground_station_id) and
        station_direction_matches?(station, direction) and
        station_window_matches?(station, starts_at_s, ends_at_s)
    end)
    |> unambiguous_highest_severity_station_state()
  end

  defp ground_network_station_id(station) do
    Map.get(station, "ground_station_id") || Map.get(station, "station_id") ||
      Map.get(station, "id")
  end

  defp unambiguous_highest_severity_station_state([]), do: %{}

  defp unambiguous_highest_severity_station_state(stations) do
    highest_severity_stations =
      stations
      |> Enum.group_by(&station_severity/1)
      |> Enum.max_by(fn {severity, _stations} -> severity end)
      |> elem(1)

    case highest_severity_stations do
      [station] ->
        station
        |> put_station_overlap_context(stations)
        |> put_station_reservation_context(stations)
        |> put_station_trust_context(stations)

      ambiguous_stations ->
        ambiguous_stations
        |> ambiguous_station_state(stations)
        |> put_station_trust_context(stations)
    end
  end

  defp ambiguous_station_state([station | _rest] = ambiguous_stations, stations) do
    ambiguous_entry_ids = station_entry_ids(ambiguous_stations)
    overlap_entry_ids = station_entry_ids(stations)

    %{
      "id" => ambiguous_station_entry_id(ambiguous_entry_ids),
      "station_calendar_entry_id" => ambiguous_station_entry_id(ambiguous_entry_ids),
      "ground_station_id" => ground_network_station_id(station),
      "status" => "ambiguous",
      "availability" => station_availability(station),
      "station_calendar_entry_ambiguous" => true,
      "station_calendar_ambiguous_entry_count" => length(ambiguous_stations),
      "station_calendar_ambiguous_entry_ids" => ambiguous_entry_ids,
      "station_calendar_overlap_count" => length(stations),
      "station_calendar_overlap_entry_ids" => overlap_entry_ids,
      "station_calendar_overlap_availabilities" =>
        stations |> Enum.map(&station_availability/1) |> Enum.uniq()
    }
    |> maybe_put("capacity_fraction", unambiguous_capacity_fraction(ambiguous_stations))
    |> put_ambiguous_station_reservation_context(stations)
  end

  defp station_entry_ids(stations) do
    stations
    |> Enum.with_index(1)
    |> Enum.map(fn {station, index} -> station_entry_id(station, index) end)
    |> Enum.sort()
  end

  defp station_entry_id(station, index) do
    Map.get(station, "id") || Map.get(station, "station_calendar_entry_id") ||
      source_station_calendar_entry_id(station) || Map.get(station, "reservation_id") ||
      derived_station_entry_id(station, index)
  end

  defp derived_station_entry_id(station, index) do
    [
      "ground_network",
      ground_network_station_id(station) || "unknown_station",
      station_availability(station),
      Map.get(station, "starts_at_s", "open"),
      Map.get(station, "ends_at_s", "open"),
      index
    ]
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp ambiguous_station_entry_id(entry_ids) do
    entry_ids
    |> then(&["ambiguous_station_calendar" | &1])
    |> Enum.join(":")
  end

  defp put_station_overlap_context(station, [_single_station]), do: station

  defp put_station_overlap_context(station, stations) do
    station
    |> Map.put("station_calendar_overlap_count", length(stations))
    |> Map.put("station_calendar_overlap_entry_ids", station_entry_ids(stations))
    |> Map.put(
      "station_calendar_overlap_availabilities",
      stations
      |> Enum.map(&station_availability/1)
      |> Enum.uniq()
      |> Enum.sort_by(&station_availability_severity/1, :desc)
    )
  end

  defp unambiguous_capacity_fraction(stations) do
    stations
    |> Enum.map(&station_capacity_fraction/1)
    |> Enum.uniq()
    |> case do
      [capacity_fraction] -> capacity_fraction
      _ambiguous_capacity -> nil
    end
  end

  defp station_direction_matches?(station, direction) do
    case station_directions(station) do
      [] -> true
      directions -> normalize_direction(direction) in directions
    end
  end

  defp station_directions(station) do
    [
      Map.get(station, "directions"),
      Map.get(station, "station_calendar_directions"),
      Map.get(station, "direction"),
      get_in(station, ["source_station_calendar_entry", "directions"]),
      get_in(station, ["source_station_calendar_entry", "station_calendar_directions"]),
      get_in(station, ["source_station_calendar_entry", "direction"])
    ]
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp nonempty_station_directions(station) do
    case station_directions(station) do
      [] -> nil
      directions -> directions
    end
  end

  defp normalize_direction(direction), do: ContactNormalization.normalize_direction(direction)

  defp station_window_matches?(station, starts_at_s, ends_at_s) do
    window_overlaps?(
      Map.get(station, "starts_at_s"),
      Map.get(station, "ends_at_s"),
      starts_at_s,
      ends_at_s
    )
  end

  defp window_overlaps?(nil, nil, _contact_start, _contact_end), do: true

  defp window_overlaps?(entry_start, entry_end, contact_start, contact_end)
       when is_number(entry_start) and is_number(entry_end) and is_number(contact_start) and
              is_number(contact_end) do
    contact_end > entry_start and contact_start < entry_end
  end

  defp window_overlaps?(_entry_start, _entry_end, _contact_start, _contact_end), do: true

  defp station_severity(station) do
    cond do
      station_unavailable?(station) -> 4
      station_reserved?(station) -> 3
      provider_counteroffer_review?(station) -> 2
      station_reduced_capacity?(station) -> 2
      true -> 1
    end
  end

  defp station_unavailable?(station) do
    station_availability(station) == "unavailable" or Map.get(station, "available") == false
  end

  defp station_reserved?(station) do
    station_availability(station) == "reserved" or
      Map.get(station, "station_contention_status") == "reserved_overlap"
  end

  defp provider_counteroffer_review?(station) do
    station["required_operator_action"] == "review_provider_counteroffer" or
      present_station_evidence?(
        ProviderCounterofferContext.source_value(station, "provider_counteroffer_id")
      ) or
      present_station_evidence?(
        ProviderCounterofferContext.source_value(station, "provider_counteroffer_status")
      )
  end

  defp station_reservation_matched?(
         %{"station_reservation_match_status" => match_status},
         _station_state
       )
       when match_status in ["matched", "owner_matched"],
       do: true

  defp station_reservation_matched?(
         %{"station_reservation_match_status" => _match_status},
         _station_state
       ),
       do: false

  defp station_reservation_matched?(
         %{"station_contention_status" => "reserved_overlap"},
         _station_state
       ),
       do: false

  defp station_reservation_matched?(candidate, station_state) do
    not Map.get(station_state, "station_calendar_entry_ambiguous", false) and
      (station_reservation_identity_matched?(candidate, station_state) or
         station_reservation_owner_matched?(candidate, station_state))
  end

  defp station_reservation_identity_matched?(candidate, station_state) do
    candidate_reservation_id = contact_reservation_id(candidate)

    station_reservation_ids =
      [
        Map.get(station_state, "reservation_id"),
        Map.get(station_state, "station_reservation_id")
      ] ++ List.wrap(Map.get(station_state, "station_calendar_reservation_ids"))

    not is_nil(candidate_reservation_id) and candidate_reservation_id in station_reservation_ids
  end

  defp station_reservation_owner_matched?(candidate, station_state) do
    candidate_reserved_by = contact_reserved_by(candidate)

    station_reserved_bys =
      [
        Map.get(station_state, "reserved_by"),
        Map.get(station_state, "station_reserved_by")
      ] ++ List.wrap(Map.get(station_state, "station_calendar_reserved_by"))

    candidate_reserved_by not in [nil, ""] and
      to_string(candidate_reserved_by) in (station_reserved_bys
                                           |> Enum.reject(&(&1 in [nil, ""]))
                                           |> Enum.map(&to_string/1))
  end

  defp contact_reservation_id(contact) do
    Map.get(contact, "station_reservation_id") || Map.get(contact, "reservation_id")
  end

  defp contact_reserved_by(contact) do
    Map.get(contact, "station_reserved_by") || Map.get(contact, "reserved_by")
  end

  defp station_reduced_capacity?(station) do
    station_availability(station) == "reduced_capacity" or
      station_capacity_fraction(station) < 1.0
  end

  defp contact_capacity_fraction(candidate) do
    case capacity_value(candidate) do
      value when is_number(value) -> clamp_unit_interval(value)
      value when is_binary(value) -> value |> numeric_or_nil() |> clamp_unit_interval()
      _value -> nil
    end
  end

  defp station_capacity_fraction(station) do
    case capacity_value(station) || Map.get(station, "availability") do
      value when is_number(value) -> value |> max(0.0) |> min(1.0)
      value when is_binary(value) -> numeric_or_nil(value) |> capacity_fraction_or_full()
      _value -> 1.0
    end
  end

  defp station_availability(station) do
    availability =
      station
      |> station_availability_candidates()
      |> Enum.filter(&station_availability_value?/1)
      |> highest_station_availability()

    cond do
      availability in ["unavailable", "maintenance" | @unavailable_aliases] -> "unavailable"
      availability == "reserved" -> "reserved"
      availability == "reduced_capacity" -> "reduced_capacity"
      station_capacity_fraction(station) < 1.0 -> "reduced_capacity"
      true -> "available"
    end
  end

  defp station_availability_candidates(station) do
    [
      station["station_availability"],
      station["availability"],
      station["station_calendar_status"],
      station["status"]
    ] ++
      source_station_calendar_availability_candidates(station["source_station_calendar_entry"]) ++
      source_station_calendar_availability_candidates(station["source_station_calendar_overlaps"])
  end

  defp highest_station_availability([]), do: nil

  defp highest_station_availability(values),
    do: Enum.max_by(values, &station_availability_severity/1)

  defp station_availability_value?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability_value?(value) when value in @unavailable_aliases, do: true
  defp station_availability_value?(_value), do: false

  defp station_availability_severity(value) when value in @unavailable_aliases,
    do: @station_availability_severity["unavailable"]

  defp station_availability_severity(value), do: Map.get(@station_availability_severity, value, 0)

  defp source_station_calendar_availability_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_availability_candidates/1)

  defp source_station_calendar_availability_candidates(%{} = source) do
    [
      source["station_availability"],
      source["availability"],
      source["station_calendar_status"],
      source["status"]
    ]
  end

  defp source_station_calendar_availability_candidates(_source), do: []

  defp put_station_reservation_context(station, stations) do
    reservations = Enum.filter(stations, &station_reserved?/1)

    case reservations do
      [] ->
        station

      [first | _rest] ->
        station
        |> Map.put_new("station_contention_status", "reserved_overlap")
        |> Map.put("reservation_id", Map.get(station, "reservation_id") || reservation_id(first))
        |> maybe_put("reserved_by", Map.get(station, "reserved_by") || first["reserved_by"])
        |> maybe_put(
          "reservation_status",
          Map.get(station, "reservation_status") || first["reservation_status"] || "reserved"
        )
        |> Map.put("station_calendar_reservation_overlap_count", length(reservations))
        |> maybe_put_list("station_calendar_reservation_ids", reservation_ids(reservations))
        |> maybe_put_list(
          "station_calendar_reserved_by",
          reservation_owners(reservations)
        )
        |> maybe_put_list(
          "station_calendar_reservation_statuses",
          reservation_statuses(reservations)
        )
        |> maybe_put("reservation_expires_at_s", reservation_expires_at_s(first))
        |> maybe_put_list(
          "station_calendar_reservation_expires_at_s",
          reservation_expires_at_s_values(reservations)
        )
    end
  end

  defp put_ambiguous_station_reservation_context(station, stations) do
    reservations = Enum.filter(stations, &station_reserved?/1)

    case reservations do
      [] ->
        station

      reservations ->
        station
        |> Map.put_new("station_contention_status", "reserved_overlap")
        |> Map.put("station_calendar_reservation_overlap_count", length(reservations))
        |> maybe_put_list("station_calendar_reservation_ids", reservation_ids(reservations))
        |> maybe_put_list(
          "station_calendar_reserved_by",
          reservation_owners(reservations)
        )
        |> maybe_put_list(
          "station_calendar_reservation_statuses",
          reservation_statuses(reservations)
        )
        |> maybe_put_list(
          "station_calendar_reservation_expires_at_s",
          reservation_expires_at_s_values(reservations)
        )
    end
  end

  defp put_station_trust_context(station, stations) do
    trust_status = station_calendar_trust_boundary_status(stations)
    trust_boundary = station_calendar_trust_boundary(station)
    provenance = station_calendar_provenance(station)
    normalized_station = normalize_station_evidence_numbers(station)
    normalized_stations = Enum.map(stations, &normalize_station_evidence_numbers/1)

    normalized_station
    |> Map.put("station_calendar_trust_boundary_status", trust_status)
    |> maybe_put("trust_boundary", trust_boundary)
    |> maybe_put("provenance", provenance)
    |> Map.put("source_station_calendar_entry", normalized_station)
    |> Map.put("source_station_calendar_overlaps", normalized_stations)
  end

  defp normalize_station_evidence_numbers(station) do
    station
    |> normalize_numeric_evidence_field("starts_at_s")
    |> normalize_numeric_evidence_field("ends_at_s")
    |> normalize_numeric_evidence_field("capacity_pack_capacity_fraction")
    |> normalize_numeric_evidence_field("capacity_fraction")
    |> normalize_numeric_evidence_field("station_capacity_fraction")
    |> normalize_capacity_percent_evidence()
  end

  defp normalize_capacity_percent_evidence(row) do
    case capacity_percent_fraction(row) do
      value when is_number(value) -> Map.put_new(row, "capacity_fraction", value)
      _value -> row
    end
  end

  defp normalize_numeric_evidence_field(row, field) do
    if Map.has_key?(row, field) do
      case numeric_or_nil(Map.get(row, field)) do
        value when is_number(value) -> Map.put(row, field, value)
        _value -> Map.delete(row, field)
      end
    else
      row
    end
  end

  defp station_calendar_trust_boundary_status(stations) do
    if Enum.all?(stations, &(station_calendar_trust_boundary(&1) not in [nil, ""])),
      do: "declared",
      else: "missing"
  end

  defp station_calendar_trust_boundary(station) do
    Map.get(station, "trust_boundary") || get_in(station, ["provenance", "trust_boundary"])
  end

  defp station_calendar_provenance(%{"provenance" => provenance}) when is_map(provenance),
    do: provenance

  defp station_calendar_provenance(_station), do: nil

  defp reservation_ids(reservations) do
    reservations
    |> Enum.flat_map(fn reservation ->
      [reservation_id(reservation)] ++ List.wrap(reservation["station_calendar_reservation_ids"])
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp reservation_id(station), do: station["reservation_id"] || station["id"]

  defp reservation_owners(reservations) do
    reservations
    |> Enum.flat_map(fn reservation ->
      [reservation["reserved_by"]] ++ List.wrap(reservation["station_calendar_reserved_by"])
    end)
  end

  defp reservation_statuses(reservations) do
    reservations
    |> Enum.flat_map(fn reservation ->
      [reservation["reservation_status"]] ++
        List.wrap(reservation["station_calendar_reservation_statuses"])
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> ["reserved"]
      statuses -> statuses
    end
  end

  defp reservation_expires_at_s_values(reservations) do
    reservations
    |> Enum.flat_map(fn reservation ->
      [
        reservation_expires_at_s(reservation),
        reservation["station_calendar_reservation_expires_at_s"]
      ]
    end)
    |> normalize_number_list()
    |> case do
      nil -> []
      values -> values
    end
  end

  defp reservation_expires_at_s(station) do
    [
      station["station_reservation_expires_at_s"],
      station["reservation_expires_at_s"],
      station["reservation_hold_expires_at_s"],
      station["hold_expires_at_s"],
      station["expires_at_s"],
      station["expires_at"],
      get_in(station, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "reservation_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "reservation_hold_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "hold_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "expires_at_s"])
    ]
    |> Enum.find_value(&numeric_or_nil/1)
  end

  defp station_contention_status(station) do
    if station_reserved?(station), do: "reserved_overlap", else: nil
  end

  defp suppressed_candidate(candidate, reason, station_state) do
    %{
      "id" => candidate_id(candidate),
      "type" => candidate["type"] || contact_type_from_direction(candidate),
      "scenario_id" => stable_id_or_nil(candidate["scenario_id"]),
      "spacecraft_id" => contact_spacecraft_id(candidate),
      "starts_at_s" => candidate["starts_at_s"],
      "ends_at_s" => candidate["ends_at_s"],
      "suppressed_reason" => reason,
      "source_window_id" => stable_id_or_nil(candidate["source_window_id"]),
      "ground_station_id" => stable_id_or_nil(candidate["ground_station_id"]),
      "station_calendar_entry_id" => contact_station_calendar_entry_id(candidate, station_state),
      "station_calendar_provider_id" =>
        candidate["station_calendar_provider_id"] ||
          station_state["station_calendar_provider_id"] ||
          get_in(station_state, ["source_station_calendar_entry", "station_calendar_provider_id"]) ||
          get_in(station_state, ["source_station_calendar_entry", "provider_id"]),
      "station_calendar_provider_entry_id" =>
        candidate["station_calendar_provider_entry_id"] ||
          station_state["station_calendar_provider_entry_id"] ||
          get_in(station_state, [
            "source_station_calendar_entry",
            "station_calendar_provider_entry_id"
          ]) ||
          get_in(station_state, ["source_station_calendar_entry", "provider_entry_id"]),
      "station_calendar_directions" =>
        candidate["station_calendar_directions"] || nonempty_station_directions(station_state),
      "station_calendar_status" =>
        candidate["station_calendar_status"] || station_state["status"],
      "station_calendar_precedence_rank" =>
        candidate["station_calendar_precedence_rank"] ||
          station_state["station_calendar_precedence_rank"],
      "station_calendar_precedence_availability" =>
        candidate["station_calendar_precedence_availability"] ||
          station_state["station_calendar_precedence_availability"],
      "station_calendar_overlap_count" =>
        candidate["station_calendar_overlap_count"] ||
          station_state["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" =>
        candidate["station_calendar_overlap_entry_ids"] ||
          station_state["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" =>
        candidate["station_calendar_overlap_availabilities"] ||
          station_state["station_calendar_overlap_availabilities"],
      "station_calendar_entry_ambiguous" =>
        candidate["station_calendar_entry_ambiguous"] ||
          station_state["station_calendar_entry_ambiguous"],
      "station_calendar_ambiguous_entry_count" =>
        candidate["station_calendar_ambiguous_entry_count"] ||
          station_state["station_calendar_ambiguous_entry_count"],
      "station_calendar_ambiguous_entry_ids" =>
        candidate["station_calendar_ambiguous_entry_ids"] ||
          station_state["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_overlap_count" =>
        candidate["station_calendar_reservation_overlap_count"] ||
          station_state["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" =>
        first_nonempty_list([
          candidate["station_calendar_reservation_ids"],
          station_state["station_calendar_reservation_ids"],
          provider_contention_values(candidate, "reservation_ids"),
          provider_contention_values(station_state, "reservation_ids")
        ]),
      "station_calendar_reserved_by" =>
        first_nonempty_list([
          candidate["station_calendar_reserved_by"],
          station_state["station_calendar_reserved_by"],
          provider_contention_values(candidate, "reserved_by"),
          provider_contention_values(station_state, "reserved_by")
        ]),
      "station_calendar_reservation_statuses" =>
        first_nonempty_list([
          candidate["station_calendar_reservation_statuses"],
          station_state["station_calendar_reservation_statuses"],
          provider_contention_values(candidate, "reservation_statuses"),
          provider_contention_values(station_state, "reservation_statuses")
        ]),
      "station_calendar_reservation_expires_at_s" =>
        first_nonempty_number_list([
          candidate["station_calendar_reservation_expires_at_s"],
          station_state["station_calendar_reservation_expires_at_s"],
          provider_contention_values(candidate, "reservation_expires_at_s"),
          provider_contention_values(station_state, "reservation_expires_at_s")
        ]),
      "station_calendar_trust_boundary_status" =>
        candidate["station_calendar_trust_boundary_status"] ||
          station_state["station_calendar_trust_boundary_status"],
      "trust_boundary" => candidate["trust_boundary"] || station_state["trust_boundary"],
      "provenance" => candidate["provenance"] || station_state["provenance"],
      "source_station_calendar_entry" =>
        candidate["source_station_calendar_entry"] ||
          station_state["source_station_calendar_entry"],
      "source_station_calendar_overlaps" =>
        candidate["source_station_calendar_overlaps"] ||
          station_state["source_station_calendar_overlaps"],
      "station_availability" => station_availability(station_state),
      "direction" => candidate["direction"] || contact_direction(candidate),
      "contact_success" => candidate_boolean_value(candidate, "contact_success"),
      "contact_result" =>
        provider_result_artifact_value(candidate_value(candidate, "contact_result")),
      "contact_success_factor" => unit_interval_factor(candidate, "contact_success_factor"),
      "contact_success_factor_source" =>
        candidate_value(candidate, "contact_success_factor_source"),
      "command_success" => candidate_boolean_value(candidate, "command_success"),
      "command_result" =>
        provider_result_artifact_value(candidate_value(candidate, "command_result")),
      "command_success_factor" => unit_interval_factor(candidate, "command_success_factor"),
      "command_success_factor_source" =>
        candidate_value(candidate, "command_success_factor_source"),
      "capacity_fraction" =>
        contact_capacity_fraction(candidate) || station_capacity_fraction(station_state),
      "station_contention_status" =>
        candidate["station_contention_status"] ||
          station_state["station_contention_status"] ||
          station_contention_status(station_state),
      "station_reservation_match_status" =>
        candidate["station_reservation_match_status"] ||
          station_reservation_match_status(candidate, station_state),
      "station_reservation_id" =>
        stable_id_or_nil(candidate["station_reservation_id"]) ||
          stable_id_or_nil(Map.get(station_state, "reservation_id")),
      "station_reserved_by" =>
        candidate["station_reserved_by"] || Map.get(station_state, "reserved_by"),
      "station_reservation_status" =>
        candidate["station_reservation_status"] || Map.get(station_state, "reservation_status"),
      "station_reservation_expires_at_s" =>
        candidate["station_reservation_expires_at_s"] || reservation_expires_at_s(station_state),
      "required_operator_action" =>
        candidate["required_operator_action"] || station_state["required_operator_action"] ||
          suppression_required_operator_action(reason),
      "operator_action_reason" =>
        candidate["operator_action_reason"] || station_state["operator_action_reason"] ||
          suppression_operator_action_reason(reason)
    }
    |> ProviderCounterofferContext.put(candidate, station_state)
    |> put_provider_contention_context()
    |> normalize_station_calendar_id_lists()
    |> normalize_station_calendar_number_lists()
    |> compact_map()
  end

  defp suppression_required_operator_action("provider_counteroffer_review"),
    do: "review_provider_counteroffer"

  defp suppression_required_operator_action(_reason), do: nil

  defp suppression_operator_action_reason("provider_counteroffer_review"),
    do: "provider_counteroffer_requires_review"

  defp suppression_operator_action_reason(_reason), do: nil

  defp put_provider_contention_context(row) do
    row
    |> maybe_put_provider_contention_values("station_calendar_reservation_ids", "reservation_ids")
    |> maybe_put_provider_contention_values("station_calendar_reserved_by", "reserved_by")
    |> maybe_put_provider_contention_values(
      "station_calendar_reservation_statuses",
      "reservation_statuses"
    )
    |> maybe_put_provider_contention_numbers(
      "station_calendar_reservation_expires_at_s",
      "reservation_expires_at_s"
    )
  end

  defp maybe_put_provider_contention_values(row, row_field, source_field) do
    case first_nonempty_list([row[row_field], provider_contention_values(row, source_field)]) do
      nil -> row
      values -> Map.put(row, row_field, values)
    end
  end

  defp maybe_put_provider_contention_numbers(row, row_field, source_field) do
    case first_nonempty_number_list([
           row[row_field],
           provider_contention_values(row, source_field)
         ]) do
      nil -> row
      values -> Map.put(row, row_field, values)
    end
  end

  defp normalize_station_calendar_id_lists(context) do
    Enum.reduce(
      [
        "station_calendar_overlap_entry_ids",
        "station_calendar_ambiguous_entry_ids",
        "station_calendar_reservation_ids"
      ],
      context,
      fn field, acc ->
        case normalize_id_list(Map.get(acc, field)) do
          nil -> Map.delete(acc, field)
          ids -> Map.put(acc, field, ids)
        end
      end
    )
  end

  defp normalize_station_calendar_number_lists(context) do
    Enum.reduce(
      ["station_calendar_reservation_expires_at_s"],
      context,
      fn field, acc ->
        case normalize_number_list(Map.get(acc, field)) do
          nil -> Map.delete(acc, field)
          values -> Map.put(acc, field, values)
        end
      end
    )
  end

  defp normalize_id_list(nil), do: nil

  defp normalize_id_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&id_values/1)
    |> Enum.flat_map(&stable_id_value/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp normalize_id_list(value), do: normalize_id_list([value])

  defp normalize_number_list(nil), do: nil

  defp normalize_number_list(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value), do: normalize_number_list([value])

  defp first_nonempty_list(values) do
    values
    |> Enum.find_value(fn
      values when is_list(values) ->
        if Enum.any?(values, &(&1 not in [nil, ""])), do: values

      value when value not in [nil, ""] ->
        [value]

      _value ->
        nil
    end)
  end

  defp first_nonempty_number_list(values) do
    values
    |> Enum.find_value(fn value ->
      case normalize_number_list(value) do
        nil -> nil
        numbers -> numbers
      end
    end)
  end

  defp provider_contention_values(row, field) do
    [
      get_in(row, ["source_station_calendar_provider_contention", field]),
      get_in(row, [
        "source_station_calendar_entry",
        "source_station_calendar_provider_contention",
        field
      ])
    ]
    |> Enum.concat(provider_contention_overlap_values(row, field))
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp provider_contention_overlap_values(
         %{"source_station_calendar_overlaps" => overlaps},
         field
       )
       when is_list(overlaps) do
    overlaps
    |> Enum.map(fn
      %{} = overlap ->
        provider_contention_overlap_value(overlap, field)

      _overlap ->
        nil
    end)
  end

  defp provider_contention_overlap_values(_row, _field), do: []

  defp provider_contention_overlap_value(overlap, field) do
    contention_value =
      get_in(overlap, [
        "source_station_calendar_entry",
        "source_station_calendar_provider_contention",
        field
      ])

    entry_field =
      case field do
        "reservation_ids" -> "reservation_id"
        "reserved_by" -> "reserved_by"
        "reservation_statuses" -> "reservation_status"
        "reservation_expires_at_s" -> "reservation_expires_at_s"
        _field -> nil
      end

    entry_values =
      overlap
      |> get_in(["source_station_calendar_entry", "source_station_calendar_entries"])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, entry_field))

    [contention_value | entry_values]
  end

  defp id_values(%{} = value) do
    ["id", "station_calendar_entry_id", "station_reservation_id", "reservation_id"]
    |> Enum.flat_map(fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> nested
        nested -> [nested]
      end
    end)
  end

  defp id_values(value), do: [value]

  defp stable_id_value(nil), do: []
  defp stable_id_value(value) when is_boolean(value), do: []

  defp stable_id_value(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_value()

  defp stable_id_value("nil"), do: []

  defp stable_id_value(value) when is_binary(value),
    do: if(stable_id?(value), do: [value], else: [])

  defp stable_id_value(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_value()

  defp stable_id_value(_value), do: []

  defp contact_station_calendar_entry_id(candidate, station_state) do
    stable_id_or_nil(candidate["station_calendar_entry_id"]) ||
      source_station_calendar_entry_id(candidate) ||
      stable_id_or_nil(station_state["station_calendar_entry_id"]) ||
      stable_id_or_nil(station_state["id"]) ||
      source_station_calendar_entry_id(station_state)
  end

  defp source_station_calendar_entry_id(row) do
    stable_id_or_nil(get_in(row, ["source_station_calendar_entry", "station_calendar_entry_id"])) ||
      stable_id_or_nil(get_in(row, ["source_station_calendar_entry", "id"])) ||
      stable_id_or_nil(
        get_in(row, [
          "source_station_calendar_entry",
          "source_station_calendar_entry",
          "station_calendar_entry_id"
        ])
      ) ||
      stable_id_or_nil(
        get_in(row, ["source_station_calendar_entry", "source_station_calendar_entry", "id"])
      )
  end

  defp station_reservation_match_status(candidate, station_state) do
    unambiguous_station_entry =
      not Map.get(station_state, "station_calendar_entry_ambiguous", false)

    cond do
      unambiguous_station_entry and
          station_reservation_identity_matched?(candidate, station_state) ->
        "matched"

      unambiguous_station_entry and station_reservation_owner_matched?(candidate, station_state) ->
        "owner_matched"

      station_reserved?(station_state) ->
        "overlap"

      true ->
        nil
    end
  end

  defp disambiguate_suppressed_candidate_ids(suppressed_candidates) do
    duplicates = duplicate_suppressed_candidate_id_groups(suppressed_candidates)
    duplicate_ids = duplicates |> Enum.map(fn {id, _rows} -> id end) |> MapSet.new()
    duplicate_counts = Map.new(duplicates, fn {id, rows} -> {id, length(rows)} end)

    {rows, _indexes} =
      Enum.map_reduce(suppressed_candidates, %{}, fn row, indexes ->
        row_id = row["id"]
        index = Map.get(indexes, row_id, 0) + 1
        indexes = Map.put(indexes, row_id, index)

        row =
          if MapSet.member?(duplicate_ids, row_id) do
            row
            |> Map.put("id", "#{row_id}:#{index}")
            |> Map.put("base_candidate_id", row_id)
            |> Map.put("duplicate_suppressed_candidate_id_collision", true)
            |> Map.put("duplicate_suppressed_candidate_index", index)
            |> Map.put(
              "duplicate_suppressed_candidate_count",
              Map.fetch!(duplicate_counts, row_id)
            )
          else
            row
          end

        {row, indexes}
      end)

    rows
  end

  defp duplicate_suppressed_candidate_id_groups(suppressed_candidates) do
    suppressed_candidates
    |> Enum.group_by(&Map.get(&1, "base_candidate_id", Map.get(&1, "id")))
    |> Enum.filter(fn {_candidate_id, rows} -> length(rows) > 1 end)
    |> Enum.sort_by(fn {candidate_id, _rows} -> candidate_id end)
  end

  defp duplicate_suppressed_candidate_row_count(duplicate_groups) do
    duplicate_groups
    |> Enum.map(fn {_candidate_id, rows} -> length(rows) end)
    |> Enum.sum()
  end

  defp station_calendar_trust_boundary_status_counts(rows) do
    counts =
      rows
      |> Enum.map(& &1["station_calendar_trust_boundary_status"])
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    if counts == %{}, do: nil, else: counts
  end

  defp suppression_reason_counts(rows) do
    counts =
      rows
      |> Enum.map(& &1["suppressed_reason"])
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    if counts == %{}, do: nil, else: counts
  end

  defp station_reservation_match_status_counts(rows) do
    counts =
      rows
      |> Enum.map(& &1["station_reservation_match_status"])
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    if counts == %{}, do: nil, else: counts
  end

  defp suppressed_candidate_ids_by_field(rows, field) do
    ids_by_field =
      rows
      |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "id"))
      |> Enum.reject(fn {field_value, ids} ->
        is_nil(field_value) or Enum.all?(ids, &is_nil/1)
      end)
      |> Map.new(fn {field_value, ids} ->
        {field_value, ids |> Enum.reject(&is_nil/1) |> Enum.uniq() |> Enum.sort()}
      end)

    if ids_by_field == %{}, do: nil, else: ids_by_field
  end

  defp maybe_put_policy(report, nil), do: report

  defp maybe_put_policy(report, policy) do
    Map.put(report, "policy", stringify_keys(policy))
  end

  defp maybe_apply_approval_policy(row, nil), do: row

  defp maybe_apply_approval_policy(row, approval_policy) do
    requirement = contact_suppression_approval_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "contact_filter", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp contact_suppression_approval_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => row["type"],
      "action" => contact_suppression_action(row),
      "requirement_type" => contact_suppression_requirement_type(row),
      "reason" => row["suppressed_reason"] || "contact filter suppressed candidate",
      "activity_context" =>
        %{
          "direction" => contact_direction(row),
          "ground_station_id" => row["ground_station_id"],
          "station_availability" => row["station_availability"],
          "capacity_fraction" => row["capacity_fraction"],
          "station_contention_status" => row["station_contention_status"],
          "station_calendar_entry_id" => row["station_calendar_entry_id"],
          "station_calendar_status" => row["station_calendar_status"],
          "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
          "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
          "station_calendar_overlap_availabilities" =>
            row["station_calendar_overlap_availabilities"],
          "station_calendar_entry_ambiguous" => row["station_calendar_entry_ambiguous"],
          "station_calendar_ambiguous_entry_count" =>
            row["station_calendar_ambiguous_entry_count"],
          "station_calendar_ambiguous_entry_ids" => row["station_calendar_ambiguous_entry_ids"],
          "station_calendar_reservation_overlap_count" =>
            row["station_calendar_reservation_overlap_count"],
          "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
          "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
          "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
          "station_calendar_reservation_expires_at_s" =>
            row["station_calendar_reservation_expires_at_s"],
          "source_station_calendar_entry" => row["source_station_calendar_entry"],
          "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
          "required_operator_action" => row["required_operator_action"],
          "operator_action_reason" => row["operator_action_reason"],
          "provider_counteroffer_id" => row["provider_counteroffer_id"],
          "provider_counteroffer_status" => row["provider_counteroffer_status"],
          "provider_counteroffer_negotiation_state" =>
            row["provider_counteroffer_negotiation_state"],
          "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
          "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
          "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
          "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
          "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
          "station_reservation_status" => row["station_reservation_status"],
          "station_reservation_id" => row["station_reservation_id"],
          "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
          "station_reserved_by" => row["station_reserved_by"],
          "station_reservation_match_status" => row["station_reservation_match_status"],
          "contact_success" => row["contact_success"],
          "contact_result" => provider_result_artifact_value(row["contact_result"]),
          "contact_success_factor" => row["contact_success_factor"],
          "contact_success_factor_source" => row["contact_success_factor_source"],
          "command_success" => row["command_success"],
          "command_result" => provider_result_artifact_value(row["command_result"]),
          "command_success_factor" => row["command_success_factor"],
          "command_success_factor_source" => row["command_success_factor_source"],
          "source_window_id" => row["source_window_id"],
          "scenario_id" => row["scenario_id"],
          "starts_at_s" => row["starts_at_s"],
          "ends_at_s" => row["ends_at_s"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp contact_suppression_requirement_type(row) do
    if contact_direction(row) == "health_check" or row["type"] == "health_check",
      do: "health_check_review",
      else: "contact_schedule_change"
  end

  defp stringify_keys(value), do: ContactNormalization.stringify_keys(value)

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(values) when is_list(values) do
    Enum.flat_map(values, &provider_result_values/1)
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(@provider_result_map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(result)
       when is_integer(result) or is_float(result) or is_boolean(result) do
    result
    |> to_string()
    |> provider_result_values()
  end

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp unit_interval_factor(row, field) do
    case numeric_or_nil(candidate_value(row, field)) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp candidate_boolean_value(candidate, field) do
    candidate
    |> candidate_value(field)
    |> boolean_value()
  end

  defp boolean_value(value) when is_boolean(value), do: value

  defp boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp candidate_value(candidate, field) do
    case Map.fetch(candidate, field) do
      {:ok, nil} -> get_in(candidate, ["metadata", field])
      {:ok, value} -> value
      :error -> get_in(candidate, ["metadata", field])
    end
  end

  defp numeric_or_nil(value), do: ContactNormalization.numeric_or_nil(value)

  defp capacity_fraction_or_full(value) when is_number(value), do: clamp_unit_interval(value)
  defp capacity_fraction_or_full(_value), do: 1.0

  defp capacity_value(row) do
    @capacity_value_paths
    |> Enum.find_value(fn
      {:fraction, path} ->
        path_value(row, path)

      {:percent, path} ->
        capacity_percent_fraction(path_value(row, path))
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)

  defp capacity_percent_fraction(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp clamp_unit_interval(nil), do: nil

  defp clamp_unit_interval(value) when is_number(value) do
    value
    |> max(0.0)
    |> min(1.0)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_list(map, key, values) do
    case Enum.reject(values, &is_nil/1) do
      [] -> map
      values -> Map.put(map, key, values)
    end
  end

  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
