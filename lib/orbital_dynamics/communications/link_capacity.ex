defmodule OrbitalDynamics.Communications.LinkCapacity do
  @moduledoc """
  Artifact-only fixed-rate downlink capacity summaries.

  The module groups downlink contact candidates by ground station, totals raw
  and station-capacity-adjusted throughput, and marks which contacts were
  selected. It does not perform link-budget analysis, reserve station time, or
  mutate schedules.
  """

  @schema_contract "link_capacity_report.v1"
  @summary_schema_contract "link_capacity_summary.v1"
  @relay_data_path_summary_schema_contract "relay_data_path_summary.v1"
  @relay_data_path_model_limits [
    "artifact_level_relay_data_path_summary",
    "no_crosslink_visibility_model",
    "no_relay_scheduling",
    "no_custody_acknowledgement_delivery",
    "no_provider_reservation",
    "no_schedule_mutation"
  ]
  @relay_custody_statuses ~w(confirmed pending missing_ack failed unknown)
  @relay_latency_statuses ~w(within_limit exceeds_limit not_evaluated unknown)
  @relay_risk_statuses ~w(nominal review high unknown)
  @unavailable_aliases ["outage", "down", "offline"]
  @station_availability_severity %{
    "unavailable" => 5,
    "maintenance" => 5,
    "reserved" => 4,
    "reduced_capacity" => 3,
    "available" => 1
  }
  @station_capacity_fraction_paths [
    ["availability"],
    ["capacity_pack_capacity_fraction"],
    ["throughput_model", "availability"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "availability"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "availability"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"],
    ["station_capacity_percent"],
    ["capacity_percent"]
  ]
  @required_downlink_policy_paths [
    ["required_downlink_mb"],
    ["required_downlink_mb_by_ground_station"]
  ]
  @contact_required_downlink_paths [
    ["required_downlink_mb"],
    ["metadata", "required_downlink_mb"],
    ["throughput_model", "required_downlink_mb"]
  ]
  @downlink_completion_source_paths [
    ["downlink_completion_source"],
    ["metadata", "downlink_completion_source"],
    ["throughput_model", "downlink_completion_source"],
    ["activity_context", "downlink_completion_source"]
  ]
  @downlink_completion_sources_paths [
    ["downlink_completion_sources"],
    ["metadata", "downlink_completion_sources"],
    ["throughput_model", "downlink_completion_sources"],
    ["activity_context", "downlink_completion_sources"]
  ]
  @actual_throughput_fields ~w(
    actual_throughput_mb
    actual_downlink_mb
    actual_data_volume_mb
    delivered_data_mb
    received_data_mb
  )
  @actual_throughput_model_paths for field <- @actual_throughput_fields,
                                     do: ["throughput_model", field]
  @actual_data_rate_fields ~w(
    actual_data_rate_mb_s
    actual_downlink_rate_mb_s
    delivered_rate_mb_s
    received_rate_mb_s
    actual_data_rate_mbps
    actual_downlink_rate_mbps
    delivered_rate_mbps
    received_rate_mbps
  )
  @actual_duration_fields ~w(
    actual_duration_s
    actual_contact_duration_s
  )
  @actual_completion_fraction_paths [
    ["completed_fraction"],
    ["completion_fraction"],
    ["contact_completion_fraction"],
    ["throughput_model", "completed_fraction"],
    ["throughput_model", "completion_fraction"],
    ["throughput_model", "contact_completion_fraction"]
  ]
  @station_capacity_value_paths [
    {:fraction, ["availability"]},
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["throughput_model", "availability"]},
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "availability"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "availability"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]}
  ]
  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "down_link" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @contact_stable_identity_fields ~w(scenario_id spacecraft_id satellite_id ground_station_id)
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  alias OrbitalDynamics.Policy

  @doc """
  Declares the fixed-rate link-capacity summary model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      summary_artifact_contract: @summary_schema_contract,
      relay_data_path_summary_artifact_contract: @relay_data_path_summary_schema_contract,
      model: :fixed_rate_downlink_capacity_summary,
      validation_level: :artifact_contract,
      station_unavailable_aliases: @unavailable_aliases,
      station_availability_precedence: @station_availability_severity,
      station_capacity_fraction_paths: @station_capacity_fraction_paths,
      station_capacity_percent_paths: @station_capacity_percent_paths,
      station_capacity_value_paths: capacity_value_path_metadata(@station_capacity_value_paths),
      source_station_capacity_fraction_paths: @station_capacity_fraction_paths,
      source_station_capacity_percent_paths: @station_capacity_percent_paths,
      source_station_capacity_value_paths:
        capacity_value_path_metadata(@station_capacity_value_paths),
      required_downlink_policy_paths: @required_downlink_policy_paths,
      contact_required_downlink_paths: @contact_required_downlink_paths,
      downlink_completion_source_paths: @downlink_completion_source_paths,
      downlink_completion_sources_paths: @downlink_completion_sources_paths,
      actual_throughput_fields: @actual_throughput_fields,
      actual_throughput_model_paths: @actual_throughput_model_paths,
      actual_data_rate_fields: @actual_data_rate_fields,
      actual_duration_fields: @actual_duration_fields,
      actual_completion_fraction_paths: @actual_completion_fraction_paths,
      provider_direction_aliases: @provider_direction_aliases,
      provider_result_map_value_keys: @provider_result_map_value_keys,
      contact_stable_identity_fields: @contact_stable_identity_fields,
      row_semantics: [
        :invalid_contact_input_review,
        :feedback_unit_interval_input_validation,
        :contact_stable_identity_fields,
        :ground_station_capacity_summary,
        :link_capacity_triage_summary,
        :link_capacity_summary_station_count,
        :link_capacity_summary_contact_count,
        :link_capacity_summary_effective_contact_count,
        :link_capacity_summary_ignored_contact_count,
        :link_capacity_summary_selected_contact_count,
        :link_capacity_summary_ignored_selected_contact_count,
        :link_capacity_summary_required_downlink_contact_count,
        :link_capacity_summary_actual_throughput_contact_count,
        :link_capacity_summary_actual_completion_contact_count,
        :link_capacity_summary_invalid_contact_input_count,
        :link_capacity_summary_invalid_selected_contact_input_count,
        :link_capacity_summary_invalid_policy_required_downlink_station_count,
        :link_capacity_summary_routing_id_sets,
        :link_capacity_summary_actual_completion_station_routing,
        :link_capacity_summary_unresolved_actual_station_routing,
        :link_capacity_summary_station_reservation_context,
        :link_capacity_summary_station_reservation_owner_status_routing,
        :link_capacity_summary_capacity_adjusted_throughput_routing,
        :link_capacity_summary_station_calendar_provider_routing,
        :station_calendar_reservation_expiration_context,
        :selected_contact_capacity_summary,
        :status_aware_contact_capacity_effects,
        :status_ignored_reason_counts,
        :ignored_contact_reason_counts,
        :ignored_selected_contact_reason_counts,
        :station_capacity_adjusted_throughput,
        :station_capacity_value_paths,
        :source_station_capacity_value_paths,
        :station_calendar_direction_capacity_context,
        :declared_downlink_requirement,
        :per_contact_downlink_requirement,
        :selected_downlink_shortfall,
        :downlink_completion_source_lineage,
        :invalid_policy_required_downlink_station_requirement,
        :realized_selected_downlink_throughput,
        :actual_throughput_aliases,
        :actual_data_rate_duration_aliases,
        :unresolved_realized_selected_downlink_throughput,
        :actual_data_rate_throughput_derivation_evidence,
        :actual_downlink_shortfall,
        :actual_downlink_completion_ratio,
        :realized_selected_downlink_completion_fraction,
        :actual_completion_fraction_aliases,
        :unresolved_realized_selected_downlink_completion_fraction,
        :data_volume_alias_capacity_summary,
        :duration_data_rate_capacity_summary,
        :realized_data_rate_capacity_summary,
        :station_calendar_availability_capacity_context,
        :provider_direction_aliases,
        :provider_result_map_value_keys,
        :station_reservation_identity_capacity_context,
        :link_capacity_summary_row_derived_counts,
        :link_capacity_row_count_list_consistency,
        :artifact_only_relay_data_path_summary,
        :relay_data_path_row_derived_counts,
        :relay_data_path_custody_latency_risk_routing,
        :relay_data_path_generated_route_id_invariant
      ],
      relay_data_path_generated_id_scope: %{
        scope: "relay_data_path_summary.v1.rows.generated_route_id",
        generated_id_field: "route_id",
        explicit_id_fields: ["route_id", "id", "data_path_id"],
        readable_prefix_fields: ["source_spacecraft_id", "ground_downlink_contact_id"],
        fingerprint_fields: [
          "source_spacecraft_id",
          "relay_chain_spacecraft_ids",
          "ground_station_id",
          "ground_downlink_contact_id",
          "latency_s",
          "latency_limit_s",
          "product_ids",
          "collection_ids"
        ],
        semantic_invariants: [
          "source_record_order_must_not_change_generated_route_id",
          "semantic_route_evidence_changes_must_change_generated_route_id",
          "explicit_route_id_takes_precedence_over_generated_route_id"
        ]
      },
      relay_data_path_statuses: %{
        custody: @relay_custody_statuses,
        latency: @relay_latency_statuses,
        risk: @relay_risk_statuses
      },
      relay_data_path_model_limits: @relay_data_path_model_limits,
      known_limits: [
        :artifact_level_only,
        :fixed_rate_summary,
        :no_link_budget_model,
        :limited_realized_selected_throughput_reconciliation,
        :limited_realized_selected_completion_fraction_reconciliation,
        :no_full_realized_contact_reconciliation,
        :no_modulation_or_coding_model,
        :no_provider_reservation,
        :no_schedule_mutation
      ],
      public_facades: [
        :link_capacity_report,
        :link_capacity_summary,
        :relay_data_path_summary
      ]
    }
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  @doc """
  Builds a `link_capacity_report.v1` from contact candidates and selected contacts.
  """
  def report(link_capacity_report)

  def report(%{"schema_contract" => @schema_contract} = report) do
    report
  end

  def report(%{schema_contract: @schema_contract} = report) do
    stringify_keys(report)
  end

  def report(candidates) when is_list(candidates) do
    report(candidates, [], [])
  end

  def report(_link_capacity_report),
    do: raise(ArgumentError, "link capacity report must be a map or contacts must be a list")

  def report(candidates, selected_contacts, opts \\ [])

  def report(candidates, selected_contacts, opts)
      when is_list(candidates) and is_list(selected_contacts) do
    candidates = Enum.map(candidates, &normalize_contact/1)
    selected_contacts = Enum.map(selected_contacts, &normalize_contact/1)

    {invalid_contact_inputs, contacts} =
      candidates
      |> Enum.filter(&downlink_like_input?/1)
      |> Enum.with_index(1)
      |> Enum.split_with(fn {contact, _index} -> invalid_link_capacity_input?(contact) end)

    contacts = Enum.map(contacts, fn {contact, _index} -> contact end)
    effective_contacts = Enum.filter(contacts, &project_contact_capacity?/1)
    ignored_contact_ids = ignored_contact_ids(contacts)

    {invalid_selected_contact_inputs, selected_downlinks} =
      selected_contacts
      |> Enum.filter(&downlink_like_input?/1)
      |> Enum.with_index(1)
      |> Enum.split_with(fn {contact, _index} -> invalid_link_capacity_input?(contact) end)

    selected_downlinks = Enum.map(selected_downlinks, fn {contact, _index} -> contact end)
    effective_selected_downlinks = Enum.filter(selected_downlinks, &project_contact_capacity?/1)
    ignored_selected_contact_ids = ignored_contact_ids(selected_downlinks)
    selected_contact_ids = MapSet.new(Enum.map(effective_selected_downlinks, &contact_id/1))
    contact_id_counts = contact_id_counts(effective_contacts)
    duplicate_contact_ids = duplicate_contact_ids(contact_id_counts)

    ambiguous_selected_contact_ids =
      selected_contact_ids
      |> Enum.filter(&(Map.get(contact_id_counts, &1, 0) > 1))
      |> Enum.sort()

    unmatched_selected_contact_ids =
      selected_contact_ids
      |> Enum.filter(&(Map.get(contact_id_counts, &1, 0) == 0))
      |> Enum.sort()

    selected_unique_contact_ids =
      selected_contact_ids
      |> Enum.filter(&(Map.get(contact_id_counts, &1, 0) == 1))
      |> MapSet.new()

    actual_throughput_resolution =
      actual_throughput_resolution(selected_downlinks, contact_id_counts)

    actual_throughput_contacts =
      Map.fetch!(actual_throughput_resolution, :matched_contacts)

    unmatched_actual_throughput_contact_ids =
      Map.fetch!(actual_throughput_resolution, :unmatched_contact_ids)

    ambiguous_actual_throughput_contact_ids =
      Map.fetch!(actual_throughput_resolution, :ambiguous_contact_ids)

    actual_completion_resolution =
      actual_completion_resolution(selected_downlinks, contact_id_counts)

    actual_completion_contacts =
      Map.fetch!(actual_completion_resolution, :matched_contacts)

    unmatched_actual_completion_contact_ids =
      Map.fetch!(actual_completion_resolution, :unmatched_contact_ids)

    ambiguous_actual_completion_contact_ids =
      Map.fetch!(actual_completion_resolution, :ambiguous_contact_ids)

    source = opts |> Keyword.get(:source, "contact_candidates") |> to_string()
    policy = opts |> Keyword.get(:policy, %{}) |> stringify_keys()
    approval_policy = Keyword.get(opts, :approval_policy)

    selected_capacity_contacts =
      Enum.filter(
        effective_contacts,
        &MapSet.member?(selected_unique_contact_ids, contact_id(&1))
      )

    capacity_adjusted_throughput_mb = total_capacity_adjusted_throughput(effective_contacts)

    selected_capacity_adjusted_throughput_mb =
      total_capacity_adjusted_throughput(selected_capacity_contacts)

    required_downlink_mb = report_required_downlink_mb(policy, effective_contacts)
    required_downlink_contact_ids = required_downlink_contact_ids(effective_contacts)

    invalid_policy_required_downlink_station_ids =
      invalid_policy_required_downlink_station_ids(policy)

    contacts_by_station = Enum.group_by(contacts, &contact_ground_station_id/1)

    selected_downlinks_by_station =
      Enum.group_by(selected_downlinks, &contact_ground_station_id/1)

    policy_station_requirements = policy_station_required_downlink_values(policy)

    rows =
      contacts_by_station
      |> Map.keys()
      |> Kernel.++(Map.keys(selected_downlinks_by_station))
      |> Kernel.++(Map.keys(policy_station_requirements))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.map(fn ground_station_id ->
        station_contacts = Map.get(contacts_by_station, ground_station_id, [])
        station_selected_downlinks = Map.get(selected_downlinks_by_station, ground_station_id, [])
        station_effective_contacts = Enum.filter(station_contacts, &project_contact_capacity?/1)

        station_selected =
          Enum.filter(
            station_effective_contacts,
            &MapSet.member?(selected_unique_contact_ids, contact_id(&1))
          )

        station_actual_throughput_contacts =
          Enum.filter(
            actual_throughput_contacts,
            &(contact_ground_station_id(&1) == ground_station_id)
          )

        station_duplicate_contact_ids =
          station_effective_contacts
          |> Enum.map(&contact_id/1)
          |> Enum.filter(&MapSet.member?(duplicate_contact_ids, &1))
          |> Enum.uniq()
          |> Enum.sort()

        station_ambiguous_selected_contact_ids =
          station_duplicate_contact_ids
          |> Enum.filter(&MapSet.member?(selected_contact_ids, &1))
          |> Enum.sort()

        capacity_fractions =
          station_effective_contacts
          |> Enum.map(&contact_capacity_fraction/1)
          |> Enum.reject(&is_nil/1)

        station_capacity_adjusted_throughput_mb =
          total_capacity_adjusted_throughput(station_effective_contacts)

        station_selected_capacity_adjusted_throughput_mb =
          total_capacity_adjusted_throughput(station_selected)

        station_actual_throughput_mb = actual_throughput_mb(station_actual_throughput_contacts)

        station_actual_completion_contacts =
          Enum.filter(
            actual_completion_contacts,
            &(contact_ground_station_id(&1) == ground_station_id)
          )

        station_unmatched_actual_throughput_contact_ids =
          unresolved_selected_contact_ids(
            selected_downlinks,
            unmatched_actual_throughput_contact_ids,
            ground_station_id,
            &actual_throughput_evidence?/1
          )

        station_ambiguous_actual_throughput_contact_ids =
          unresolved_selected_contact_ids(
            selected_downlinks,
            ambiguous_actual_throughput_contact_ids,
            ground_station_id,
            &actual_throughput_evidence?/1
          )

        station_unmatched_actual_completion_contact_ids =
          unresolved_selected_contact_ids(
            selected_downlinks,
            unmatched_actual_completion_contact_ids,
            ground_station_id,
            &actual_completion_evidence?/1
          )

        station_ambiguous_actual_completion_contact_ids =
          unresolved_selected_contact_ids(
            selected_downlinks,
            ambiguous_actual_completion_contact_ids,
            ground_station_id,
            &actual_completion_evidence?/1
          )

        station_required_downlink_mb =
          station_required_downlink_mb(ground_station_id, policy, station_effective_contacts)

        station_required_downlink_contact_ids =
          required_downlink_contact_ids(station_effective_contacts)

        station_downlink_completion_source =
          downlink_completion_source(ground_station_id, policy, station_effective_contacts)

        station_downlink_completion_sources =
          downlink_completion_sources(ground_station_id, policy, station_effective_contacts)

        %{
          "ground_station_id" => ground_station_id,
          "contact_count" => length(station_contacts),
          "effective_contact_count" => length(station_effective_contacts),
          "ignored_contact_count" =>
            length(station_contacts) - length(station_effective_contacts),
          "ignored_contact_ids" => ignored_contact_ids(station_contacts),
          "ignored_contact_reason_counts" => ignored_contact_reason_counts(station_contacts),
          "selected_contact_count" => length(station_selected),
          "ignored_selected_contact_count" =>
            length(ignored_contact_ids(station_selected_downlinks)),
          "ignored_selected_contact_ids" => ignored_contact_ids(station_selected_downlinks),
          "ignored_selected_contact_reason_counts" =>
            ignored_contact_reason_counts(station_selected_downlinks),
          "estimated_throughput_mb" => total_estimated_throughput(station_effective_contacts),
          "selected_estimated_throughput_mb" => total_estimated_throughput(station_selected),
          "capacity_adjusted_throughput_mb" => station_capacity_adjusted_throughput_mb,
          "selected_capacity_adjusted_throughput_mb" =>
            station_selected_capacity_adjusted_throughput_mb,
          "unused_capacity_adjusted_throughput_mb" =>
            unused_capacity_adjusted_throughput(
              station_capacity_adjusted_throughput_mb,
              station_selected_capacity_adjusted_throughput_mb
            ),
          "selected_capacity_utilization_fraction" =>
            selected_capacity_utilization_fraction(
              station_capacity_adjusted_throughput_mb,
              station_selected_capacity_adjusted_throughput_mb
            ),
          "selection_utilization_status" =>
            selection_utilization_status(
              station_capacity_adjusted_throughput_mb,
              station_selected_capacity_adjusted_throughput_mb
            ),
          "required_downlink_mb" => station_required_downlink_mb,
          "required_downlink_contact_count" => length(station_required_downlink_contact_ids),
          "required_downlink_contact_ids" => station_required_downlink_contact_ids,
          "downlink_completion_source" => station_downlink_completion_source,
          "downlink_completion_sources" => station_downlink_completion_sources,
          "selected_downlink_shortfall_mb" =>
            selected_downlink_shortfall_mb(
              station_required_downlink_mb,
              station_selected_capacity_adjusted_throughput_mb
            ),
          "downlink_requirement_status" =>
            downlink_requirement_status(
              station_required_downlink_mb,
              station_selected_capacity_adjusted_throughput_mb
            ),
          "actual_throughput_mb" => station_actual_throughput_mb,
          "actual_throughput_contact_count" => length(station_actual_throughput_contacts),
          "actual_throughput_contact_ids" =>
            actual_throughput_contact_ids(station_actual_throughput_contacts),
          "actual_data_rate_throughput_derivations" =>
            actual_data_rate_throughput_derivations(station_actual_throughput_contacts),
          "actual_completion_fraction" =>
            actual_completion_fraction(station_actual_completion_contacts),
          "actual_completion_contact_count" => length(station_actual_completion_contacts),
          "actual_completion_contact_ids" =>
            actual_completion_contact_ids(station_actual_completion_contacts),
          "unmatched_actual_throughput_contact_count" =>
            optional_contact_count(station_unmatched_actual_throughput_contact_ids),
          "unmatched_actual_throughput_contact_ids" =>
            optional_contact_ids(station_unmatched_actual_throughput_contact_ids),
          "ambiguous_actual_throughput_contact_count" =>
            optional_contact_count(station_ambiguous_actual_throughput_contact_ids),
          "ambiguous_actual_throughput_contact_ids" =>
            optional_contact_ids(station_ambiguous_actual_throughput_contact_ids),
          "unmatched_actual_completion_contact_count" =>
            optional_contact_count(station_unmatched_actual_completion_contact_ids),
          "unmatched_actual_completion_contact_ids" =>
            optional_contact_ids(station_unmatched_actual_completion_contact_ids),
          "ambiguous_actual_completion_contact_count" =>
            optional_contact_count(station_ambiguous_actual_completion_contact_ids),
          "ambiguous_actual_completion_contact_ids" =>
            optional_contact_ids(station_ambiguous_actual_completion_contact_ids),
          "actual_downlink_shortfall_mb" =>
            actual_downlink_shortfall_mb(
              station_required_downlink_mb,
              station_actual_throughput_mb
            ),
          "actual_downlink_completion_ratio" =>
            actual_downlink_completion_ratio(
              station_required_downlink_mb,
              station_actual_throughput_mb
            ),
          "actual_downlink_requirement_status" =>
            actual_downlink_requirement_status(
              station_required_downlink_mb,
              station_actual_throughput_mb
            ),
          "station_calendar_entry_ids" => station_calendar_entry_ids(station_contacts),
          "station_calendar_provider_ids" => station_calendar_provider_ids(station_contacts),
          "station_calendar_provider_entry_ids" =>
            station_calendar_provider_entry_ids(station_contacts),
          "station_calendar_directions" => station_calendar_directions(station_contacts),
          "station_reservation_ids" => station_reservation_ids(station_contacts),
          "station_reservation_expires_at_s" =>
            station_reservation_expires_at_s(station_contacts),
          "station_reserved_bys" => station_reserved_bys(station_contacts),
          "station_reservation_statuses" => station_reservation_statuses(station_contacts),
          "station_reservation_match_statuses" =>
            station_reservation_match_statuses(station_contacts),
          "station_availability" => station_availability(station_effective_contacts),
          "capacity_fraction_min" => Enum.min(capacity_fractions, fn -> nil end),
          "capacity_fraction_max" => Enum.max(capacity_fractions, fn -> nil end),
          "contact_ids" => Enum.map(station_contacts, &contact_id/1) |> Enum.sort(),
          "selected_contact_ids" => Enum.map(station_selected, &contact_id/1) |> Enum.sort(),
          "duplicate_contact_ids" => station_duplicate_contact_ids,
          "duplicate_contact_candidate_count" =>
            duplicate_contact_candidate_count(station_effective_contacts, duplicate_contact_ids),
          "ambiguous_selected_contact_ids" => station_ambiguous_selected_contact_ids,
          "ambiguous_selected_contact_id_count" => length(station_ambiguous_selected_contact_ids)
        }
        |> Map.merge(contact_feedback_context(station_contacts))
        |> compact_map()
        |> maybe_apply_approval_policy(approval_policy)
      end)
      |> Enum.sort_by(& &1["ground_station_id"])

    %{
      "schema_contract" => @schema_contract,
      "model" => "fixed_rate_downlink_capacity_summary",
      "source" => source,
      "contact_count" => length(contacts),
      "effective_contact_count" => length(effective_contacts),
      "ignored_contact_count" => length(ignored_contact_ids),
      "ignored_contact_ids" => ignored_contact_ids,
      "ignored_contact_reason_counts" => ignored_contact_reason_counts(contacts),
      "selected_contact_count" => length(selected_capacity_contacts),
      "ignored_selected_contact_count" => length(ignored_selected_contact_ids),
      "ignored_selected_contact_ids" => ignored_selected_contact_ids,
      "ignored_selected_contact_reason_counts" =>
        ignored_contact_reason_counts(selected_downlinks),
      "estimated_throughput_mb" => total_estimated_throughput(effective_contacts),
      "selected_estimated_throughput_mb" =>
        total_estimated_throughput(selected_capacity_contacts),
      "capacity_adjusted_throughput_mb" => capacity_adjusted_throughput_mb,
      "selected_capacity_adjusted_throughput_mb" => selected_capacity_adjusted_throughput_mb,
      "unused_capacity_adjusted_throughput_mb" =>
        unused_capacity_adjusted_throughput(
          capacity_adjusted_throughput_mb,
          selected_capacity_adjusted_throughput_mb
        ),
      "selected_capacity_utilization_fraction" =>
        selected_capacity_utilization_fraction(
          capacity_adjusted_throughput_mb,
          selected_capacity_adjusted_throughput_mb
        ),
      "selection_utilization_status" =>
        selection_utilization_status(
          capacity_adjusted_throughput_mb,
          selected_capacity_adjusted_throughput_mb
        ),
      "required_downlink_mb" => required_downlink_mb,
      "required_downlink_contact_count" => length(required_downlink_contact_ids),
      "required_downlink_contact_ids" => required_downlink_contact_ids,
      "downlink_completion_source" => downlink_completion_source(policy, effective_contacts),
      "downlink_completion_sources" =>
        downlink_completion_sources(policy, effective_contacts) || [],
      "selected_downlink_shortfall_mb" =>
        selected_downlink_shortfall_mb(
          required_downlink_mb,
          selected_capacity_adjusted_throughput_mb
        ),
      "downlink_requirement_status" =>
        downlink_requirement_status(
          required_downlink_mb,
          selected_capacity_adjusted_throughput_mb
        ),
      "actual_throughput_mb" => actual_throughput_mb(actual_throughput_contacts),
      "actual_throughput_contact_count" => length(actual_throughput_contacts),
      "actual_throughput_contact_ids" =>
        actual_throughput_contact_ids(actual_throughput_contacts),
      "actual_data_rate_throughput_derivations" =>
        actual_data_rate_throughput_derivations(actual_throughput_contacts),
      "actual_completion_fraction" => actual_completion_fraction(actual_completion_contacts),
      "actual_completion_contact_count" => length(actual_completion_contacts),
      "actual_completion_contact_ids" =>
        actual_completion_contact_ids(actual_completion_contacts),
      "unmatched_actual_throughput_contact_count" =>
        length(unmatched_actual_throughput_contact_ids),
      "unmatched_actual_throughput_contact_ids" => unmatched_actual_throughput_contact_ids,
      "ambiguous_actual_throughput_contact_count" =>
        length(ambiguous_actual_throughput_contact_ids),
      "ambiguous_actual_throughput_contact_ids" => ambiguous_actual_throughput_contact_ids,
      "unmatched_actual_completion_contact_count" =>
        length(unmatched_actual_completion_contact_ids),
      "unmatched_actual_completion_contact_ids" => unmatched_actual_completion_contact_ids,
      "ambiguous_actual_completion_contact_count" =>
        length(ambiguous_actual_completion_contact_ids),
      "ambiguous_actual_completion_contact_ids" => ambiguous_actual_completion_contact_ids,
      "actual_downlink_shortfall_mb" =>
        actual_downlink_shortfall_mb(
          required_downlink_mb,
          actual_throughput_mb(actual_throughput_contacts)
        ),
      "actual_downlink_completion_ratio" =>
        actual_downlink_completion_ratio(
          required_downlink_mb,
          actual_throughput_mb(actual_throughput_contacts)
        ),
      "actual_downlink_requirement_status" =>
        actual_downlink_requirement_status(
          required_downlink_mb,
          actual_throughput_mb(actual_throughput_contacts)
        ),
      "duplicate_contact_id_count" => MapSet.size(duplicate_contact_ids),
      "duplicate_contact_candidate_count" =>
        duplicate_contact_candidate_count(effective_contacts, duplicate_contact_ids),
      "ambiguous_selected_contact_id_count" => length(ambiguous_selected_contact_ids),
      "ambiguous_selected_contact_ids" => ambiguous_selected_contact_ids,
      "unmatched_selected_contact_count" => length(unmatched_selected_contact_ids),
      "unmatched_selected_contact_ids" => unmatched_selected_contact_ids,
      "invalid_contact_input_count" => length(invalid_contact_inputs),
      "invalid_contact_input_ids" => invalid_contact_input_ids(invalid_contact_inputs),
      "invalid_contact_inputs" =>
        invalid_contact_rows(invalid_contact_inputs, "candidate", approval_policy),
      "invalid_selected_contact_input_count" => length(invalid_selected_contact_inputs),
      "invalid_selected_contact_input_ids" =>
        invalid_contact_input_ids(invalid_selected_contact_inputs),
      "invalid_selected_contact_inputs" =>
        invalid_contact_rows(invalid_selected_contact_inputs, "selected", approval_policy),
      "invalid_policy_required_downlink_station_count" =>
        length(invalid_policy_required_downlink_station_ids),
      "invalid_policy_required_downlink_station_ids" =>
        invalid_policy_required_downlink_station_ids,
      "station_reservation_ids" =>
        row_list_values(rows, "station_reservation_ids", :stable_id) || [],
      "station_reservation_expires_at_s" =>
        row_list_values(rows, "station_reservation_expires_at_s", :number) || [],
      "station_reserved_bys" => row_list_values(rows, "station_reserved_bys", :string) || [],
      "station_reservation_statuses" =>
        row_list_values(rows, "station_reservation_statuses", :string) || [],
      "station_reservation_match_status_counts" =>
        row_list_value_counts(rows, "station_reservation_match_statuses"),
      "model_limits" => model_limits(),
      "rows" => rows,
      "assumptions" => %{
        "downlink_rate_mb_s" => Map.get(policy, "downlink_rate_mb_s", 1.0),
        "throughput_model" => "fixed_rate_from_campaign_policy",
        "capacity_adjusted_throughput_model" =>
          "estimated_throughput_mb_times_declared_station_capacity_fraction",
        "capacity_fraction_source" => "station_calendar_or_default_one",
        "downlink_requirement_model" =>
          "explicit policy downlink requirement, station requirement, or per-contact required_downlink_mb compared to selected capacity-adjusted throughput",
        "downlink_completion_source_model" =>
          "explicit policy requirement sources or per-contact downlink completion source lineage are preserved for review",
        "per_contact_downlink_requirement_model" =>
          "effective downlink contacts with required_downlink_mb contribute declared demand when no explicit policy requirement overrides them",
        "selected_contact_identity" =>
          "selected contact IDs must match exactly one candidate row to count selected capacity",
        "actual_throughput_model" =>
          "actual_throughput_mb, actual_data_volume_mb, actual data-rate duration products, or actual-downlink/delivered/received aliases from selected realized downlink contacts are summed only when the selected contact ID matches exactly one effective candidate row",
        "actual_completion_fraction_model" =>
          "completed_fraction or completion aliases from selected realized downlink contacts are averaged only when the selected contact ID matches exactly one effective candidate row",
        "actual_downlink_completion_ratio_model" =>
          "matched selected realized throughput is divided by the declared downlink requirement to expose realized completion against the same requirement used for actual shortfall review",
        "data_rate_throughput_model" =>
          "when explicit MB throughput is absent, data_rate_mb_s or data_rate_mbps aliases multiplied by contact duration produce fixed-rate estimated throughput without link-budget modeling",
        "unresolved_actual_throughput_model" =>
          "selected realized downlink contacts with actual throughput evidence are preserved as unmatched or ambiguous evidence when they cannot be reconciled to exactly one effective candidate row",
        "unresolved_actual_completion_fraction_model" =>
          "selected realized downlink contacts with completion-fraction evidence are preserved as unmatched or ambiguous evidence when they cannot be reconciled to exactly one effective candidate row",
        "invalid_contact_input" =>
          "downlink-like candidate or selected inputs missing identity or station fields are preserved for operator review instead of being silently dropped or raising during capacity grouping",
        "contact_status_model" =>
          "terminal_or_approval_rejected_downlinks_are_audited_with_zero_available_or_selected_capacity_and_reason_counts",
        "reservation_model" => "provider_reservation_identity_context_only",
        "link_budget_model" => "none"
      }
    }
    |> compact_map()
  end

  def report(_candidates, _selected_contacts, _opts),
    do: raise(ArgumentError, "candidates and selected contacts must be lists")

  @doc """
  Builds a compact artifact-only link-capacity triage summary.

  The summary accepts either an existing `link_capacity_report.v1`, an existing
  `link_capacity_summary.v1`, or the candidate/selected contact inputs used to
  build one. It exposes row-derived station and contact ID sets without
  rerunning link analysis, reserving provider time, mutating schedules, or
  approving contacts.
  """
  def summary(link_capacity_report)

  def summary(%{"schema_contract" => @summary_schema_contract} = summary), do: summary

  def summary(%{"schema_contract" => @schema_contract} = report) do
    link_capacity_summary(report)
  end

  def summary(%{schema_contract: @summary_schema_contract} = summary) do
    stringify_keys(summary)
  end

  def summary(%{schema_contract: @schema_contract} = report) do
    report
    |> stringify_keys()
    |> summary()
  end

  def summary(_link_capacity_report),
    do: raise(ArgumentError, "link capacity report is required")

  def summary(candidates, selected_contacts, opts)
      when is_list(candidates) and is_list(selected_contacts) do
    candidates
    |> report(selected_contacts, opts)
    |> summary()
  end

  def summary(_candidates, _selected_contacts, _opts),
    do: raise(ArgumentError, "candidates and selected contacts must be lists")

  @doc """
  Builds an artifact-only relay/store-and-forward data-path summary.

  The summary preserves source spacecraft, relay chain, ground downlink,
  custody, latency, and risk evidence without modeling crosslink visibility,
  reserving provider contacts, delivering custody acknowledgements, or mutating
  schedules.
  """
  def relay_data_path_summary(routes, opts \\ [])

  def relay_data_path_summary(
        %{"schema_contract" => @relay_data_path_summary_schema_contract} = summary,
        _opts
      ) do
    summary
  end

  def relay_data_path_summary(
        %{schema_contract: @relay_data_path_summary_schema_contract} = summary,
        opts
      ) do
    summary
    |> stringify_keys()
    |> relay_data_path_summary(opts)
  end

  def relay_data_path_summary(routes, opts) when is_list(routes) and is_list(opts) do
    source = opts |> Keyword.get(:source, "relay_data_path_inputs") |> to_string()
    default_latency_limit_s = opts |> Keyword.get(:latency_limit_s) |> numeric_value()

    rows =
      routes
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(fn route -> relay_data_path_row(route, default_latency_limit_s) end)
      |> Enum.sort_by(& &1["route_id"])

    %{
      "schema_contract" => @relay_data_path_summary_schema_contract,
      "schema_version" => 1,
      "model" => "artifact_only_relay_data_path_summary",
      "source" => source,
      "route_count" => length(rows),
      "relay_route_count" => Enum.count(rows, &(&1["relay_hop_count"] > 0)),
      "direct_downlink_route_count" => Enum.count(rows, &(&1["relay_hop_count"] == 0)),
      "custody_status_counts" => relay_status_count_map(rows, "custody_status"),
      "latency_status_counts" => relay_status_count_map(rows, "latency_status"),
      "risk_status_counts" => relay_status_count_map(rows, "risk_status"),
      "route_ids" => row_list_values(rows, "route_id", :stable_id) || [],
      "source_spacecraft_ids" => row_list_values(rows, "source_spacecraft_id", :stable_id) || [],
      "relay_spacecraft_ids" =>
        row_list_values(rows, "relay_chain_spacecraft_ids", :stable_id) || [],
      "ground_station_ids" => row_list_values(rows, "ground_station_id", :stable_id) || [],
      "ground_downlink_contact_ids" =>
        row_list_values(rows, "ground_downlink_contact_id", :stable_id) || [],
      "route_ids_by_custody_status" => relay_route_ids_by_field(rows, "custody_status"),
      "route_ids_by_latency_status" => relay_route_ids_by_field(rows, "latency_status"),
      "route_ids_by_risk_status" => relay_route_ids_by_field(rows, "risk_status"),
      "route_ids_by_ground_station_id" => relay_route_ids_by_field(rows, "ground_station_id"),
      "maximum_latency_s" => relay_maximum_number(rows, "latency_s"),
      "maximum_latency_limit_s" => relay_maximum_number(rows, "latency_limit_s"),
      "model_limits" => @relay_data_path_model_limits,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
        "crosslink_visibility_model" => "not_evaluated",
        "custody_acknowledgement_delivery" => "not_performed",
        "provider_reservation" => "not_performed",
        "operator_authority" => "not_granted_by_summary"
      },
      "rows" => rows
    }
    |> compact_map()
  end

  def relay_data_path_summary(_routes, _opts),
    do: raise(ArgumentError, "relay data path routes must be a list")

  defp relay_data_path_row(route, default_latency_limit_s) do
    source_spacecraft_id = relay_source_spacecraft_id(route)
    ground_station_id = relay_ground_station_id(route)
    ground_downlink_contact_id = relay_ground_downlink_contact_id(route)
    relay_chain_spacecraft_ids = relay_chain_spacecraft_ids(route)
    latency_s = relay_latency_s(route)
    latency_limit_s = relay_latency_limit_s(route, default_latency_limit_s)
    custody_status = relay_custody_status(route)
    latency_status = relay_latency_status(route, latency_s, latency_limit_s)
    risk_reasons = relay_risk_reasons(route, custody_status, latency_status)
    risk_status = relay_risk_status(route, custody_status, latency_status)
    product_ids = relay_stable_id_list(route, ["product_ids", "product_id"])
    collection_ids = relay_stable_id_list(route, ["collection_ids", "collection_id"])

    %{
      "route_id" =>
        relay_route_id(
          route,
          source_spacecraft_id,
          relay_chain_spacecraft_ids,
          ground_station_id,
          ground_downlink_contact_id,
          latency_s,
          latency_limit_s,
          product_ids,
          collection_ids
        ),
      "source_spacecraft_id" => source_spacecraft_id,
      "relay_chain_spacecraft_ids" => relay_chain_spacecraft_ids,
      "relay_hop_count" => length(relay_chain_spacecraft_ids),
      "ground_station_id" => ground_station_id,
      "ground_downlink_contact_id" => ground_downlink_contact_id,
      "custody_status" => custody_status,
      "latency_s" => latency_s,
      "latency_limit_s" => latency_limit_s,
      "latency_status" => latency_status,
      "risk_status" => risk_status,
      "risk_reasons" => risk_reasons,
      "product_ids" => product_ids,
      "collection_ids" => collection_ids
    }
    |> compact_map()
  end

  defp relay_route_id(
         route,
         source_spacecraft_id,
         relay_chain_spacecraft_ids,
         ground_station_id,
         ground_downlink_contact_id,
         latency_s,
         latency_limit_s,
         product_ids,
         collection_ids
       ) do
    [
      route["route_id"],
      route["id"],
      route["data_path_id"]
    ]
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> List.first()
    |> case do
      nil ->
        readable =
          [source_spacecraft_id, ground_downlink_contact_id]
          |> Enum.reject(&is_nil/1)
          |> Enum.join(":")

        fingerprint =
          [
            source_spacecraft_id,
            relay_chain_spacecraft_ids,
            ground_station_id,
            ground_downlink_contact_id,
            latency_s,
            latency_limit_s,
            product_ids,
            collection_ids
          ]
          |> :erlang.term_to_binary()
          |> then(&:crypto.hash(:sha256, &1))
          |> Base.encode16(case: :lower)
          |> binary_part(0, 12)

        ["relay_data_path", readable, fingerprint]
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.join(":")

      route_id ->
        route_id
    end
  end

  defp relay_source_spacecraft_id(route) do
    relay_first_stable_id(route, [
      ["source_spacecraft_id"],
      ["spacecraft_id"],
      ["satellite_id"],
      ["source", "spacecraft_id"],
      ["source", "satellite_id"]
    ])
  end

  defp relay_ground_station_id(route) do
    relay_first_stable_id(route, [
      ["ground_station_id"],
      ["station_id"],
      ["ground_downlink", "ground_station_id"],
      ["ground_downlink", "station_id"]
    ])
  end

  defp relay_ground_downlink_contact_id(route) do
    relay_first_stable_id(route, [
      ["ground_downlink_contact_id"],
      ["downlink_contact_id"],
      ["contact_id"],
      ["ground_downlink", "id"],
      ["ground_downlink", "contact_id"]
    ])
  end

  defp relay_chain_spacecraft_ids(route) do
    [
      route["relay_chain_spacecraft_ids"],
      route["relay_spacecraft_ids"],
      route["relay_chain"],
      route["relays"]
    ]
    |> List.flatten()
    |> Enum.map(fn
      %{} = relay ->
        relay_first_stable_id(relay, [["spacecraft_id"], ["satellite_id"], ["id"]])

      value ->
        stable_id_or_nil(value)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp relay_latency_s(route) do
    relay_first_number(route, [
      ["latency_s"],
      ["planned_latency_s"],
      ["delivery_latency_s"],
      ["data_latency_s"],
      ["ground_downlink", "latency_s"]
    ])
  end

  defp relay_latency_limit_s(route, default_latency_limit_s) do
    relay_first_number(route, [
      ["latency_limit_s"],
      ["max_latency_s"],
      ["required_latency_s"],
      ["target_latency_s"]
    ]) || default_latency_limit_s
  end

  defp relay_custody_status(route) do
    route
    |> relay_first_string([["custody_status"], ["custody", "status"], ["status"]])
    |> normalize_relay_status(@relay_custody_statuses, %{
      "acknowledged" => "confirmed",
      "ack" => "confirmed",
      "received" => "confirmed",
      "in_custody" => "pending",
      "pending_ack" => "pending",
      "missing" => "missing_ack",
      "missing_acknowledgement" => "missing_ack",
      "lost" => "failed"
    })
    |> case do
      nil -> "unknown"
      status -> status
    end
  end

  defp relay_latency_status(route, latency_s, latency_limit_s) do
    explicit =
      route
      |> relay_first_string([["latency_status"], ["delivery_latency_status"]])
      |> normalize_relay_status(@relay_latency_statuses, %{
        "ok" => "within_limit",
        "satisfied" => "within_limit",
        "late" => "exceeds_limit",
        "overdue" => "exceeds_limit",
        "not evaluated" => "not_evaluated"
      })

    cond do
      is_binary(explicit) ->
        explicit

      is_number(latency_s) and is_number(latency_limit_s) and latency_s <= latency_limit_s ->
        "within_limit"

      is_number(latency_s) and is_number(latency_limit_s) ->
        "exceeds_limit"

      is_nil(latency_s) ->
        "not_evaluated"

      true ->
        "unknown"
    end
  end

  defp relay_risk_status(route, custody_status, latency_status) do
    explicit =
      route
      |> relay_first_string([["risk_status"], ["risk", "status"]])
      |> normalize_relay_status(@relay_risk_statuses, %{
        "low" => "nominal",
        "ok" => "nominal",
        "medium" => "review",
        "requires_review" => "review",
        "blocked" => "high",
        "failed" => "high"
      })

    cond do
      is_binary(explicit) ->
        explicit

      custody_status == "failed" or latency_status == "exceeds_limit" ->
        "high"

      custody_status in ["pending", "missing_ack", "unknown"] or
          latency_status in ["not_evaluated", "unknown"] ->
        "review"

      true ->
        "nominal"
    end
  end

  defp relay_risk_reasons(route, custody_status, latency_status) do
    declared =
      route
      |> Map.get("risk_reasons", Map.get(route, "reasons", []))
      |> List.wrap()
      |> normalized_string_values()
      |> Kernel.||([])

    derived =
      []
      |> maybe_append_relay_reason(custody_status != "confirmed", "custody_#{custody_status}")
      |> maybe_append_relay_reason(latency_status != "within_limit", "latency_#{latency_status}")

    (declared ++ derived)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp maybe_append_relay_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_relay_reason(reasons, false, _reason), do: reasons

  defp relay_first_stable_id(route, paths) do
    paths
    |> Enum.map(&get_in(route, &1))
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  defp relay_first_number(route, paths) do
    paths
    |> Enum.map(&get_in(route, &1))
    |> Enum.map(&numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  defp relay_first_string(route, paths) do
    paths
    |> Enum.map(&get_in(route, &1))
    |> Enum.map(&string_value/1)
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  defp normalize_relay_status(nil, _allowed, _aliases), do: nil

  defp normalize_relay_status(value, allowed, aliases) do
    normalized =
      value
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s-]+/, "_")

    Map.get(aliases, normalized, normalized)
    |> case do
      status ->
        if status in allowed, do: status, else: "unknown"
    end
  end

  defp relay_stable_id_list(route, fields) do
    fields
    |> Enum.flat_map(fn field -> route |> Map.get(field, []) |> List.wrap() end)
    |> sorted_stable_ids()
  end

  defp relay_route_ids_by_field(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["route_id"])
    |> Enum.reject(fn {value, route_ids} ->
      is_nil(value) or Enum.all?(route_ids, &is_nil(stable_id_or_nil(&1)))
    end)
    |> Map.new(fn {value, route_ids} -> {value, sorted_stable_ids(route_ids)} end)
  end

  defp relay_status_count_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp relay_maximum_number(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> Enum.max(fn -> nil end)
  end

  defp link_capacity_summary(report) do
    report = stringify_keys(report)

    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&normalize_station_calendar_status_fields/1)

    %{
      "schema_contract" => @summary_schema_contract,
      "model" => "artifact_only_link_capacity_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "source" => report["source"],
      "model_limits" => model_limits(),
      "station_count" => length(row_ground_station_ids(rows)),
      "contact_count" => row_scalar_count_sum(rows, "contact_count"),
      "effective_contact_count" => row_scalar_count_sum(rows, "effective_contact_count"),
      "ignored_contact_count" => row_scalar_count_sum(rows, "ignored_contact_count"),
      "selected_contact_count" => row_scalar_count_sum(rows, "selected_contact_count"),
      "ignored_selected_contact_count" =>
        row_scalar_count_sum(rows, "ignored_selected_contact_count"),
      "required_downlink_contact_count" => row_list_count(rows, "required_downlink_contact_ids"),
      "actual_throughput_contact_count" => row_list_count(rows, "actual_throughput_contact_ids"),
      "actual_completion_contact_count" => row_list_count(rows, "actual_completion_contact_ids"),
      "unmatched_actual_throughput_contact_count" =>
        row_list_count(rows, "unmatched_actual_throughput_contact_ids"),
      "ambiguous_actual_throughput_contact_count" =>
        row_list_count(rows, "ambiguous_actual_throughput_contact_ids"),
      "unmatched_actual_completion_contact_count" =>
        row_list_count(rows, "unmatched_actual_completion_contact_ids"),
      "ambiguous_actual_completion_contact_count" =>
        row_list_count(rows, "ambiguous_actual_completion_contact_ids"),
      "invalid_contact_input_count" =>
        report_list_count(report, "invalid_contact_inputs", "invalid_contact_input_ids"),
      "invalid_selected_contact_input_count" =>
        report_list_count(
          report,
          "invalid_selected_contact_inputs",
          "invalid_selected_contact_input_ids"
        ),
      "invalid_policy_required_downlink_station_count" =>
        length(report_string_values(report, "invalid_policy_required_downlink_station_ids")),
      "downlink_requirement_status" => report["downlink_requirement_status"],
      "actual_downlink_requirement_status" => report["actual_downlink_requirement_status"],
      "selection_utilization_status" => report["selection_utilization_status"],
      "selected_downlink_shortfall_mb" => row_numeric_sum(rows, "selected_downlink_shortfall_mb"),
      "actual_downlink_shortfall_mb" => row_numeric_sum(rows, "actual_downlink_shortfall_mb"),
      "capacity_adjusted_throughput_mb" =>
        row_numeric_sum(rows, "capacity_adjusted_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb" =>
        row_numeric_sum(rows, "selected_capacity_adjusted_throughput_mb"),
      "unused_capacity_adjusted_throughput_mb" =>
        row_numeric_sum(rows, "unused_capacity_adjusted_throughput_mb"),
      "ignored_contact_reason_counts" =>
        row_count_map(rows, "ignored_contact_reason_counts") || %{},
      "ignored_selected_contact_reason_counts" =>
        row_count_map(rows, "ignored_selected_contact_reason_counts") || %{},
      "station_reservation_match_status_counts" =>
        row_station_reservation_match_status_counts(rows) || %{},
      "station_calendar_entry_ids" => row_station_calendar_entry_ids(rows),
      "station_calendar_provider_ids" => row_station_calendar_provider_ids(rows),
      "station_calendar_provider_entry_ids" => row_station_calendar_provider_entry_ids(rows),
      "station_reservation_ids" => row_station_reservation_ids(rows) || [],
      "station_reservation_expires_at_s" => row_station_reservation_expires_at_s(rows) || [],
      "station_reserved_bys" => row_station_reserved_bys(rows) || [],
      "station_reservation_statuses" => row_station_reservation_statuses(rows) || [],
      "contact_ids" => row_list_values(rows, "contact_ids", :stable_id),
      "selected_contact_ids" => row_list_values(rows, "selected_contact_ids", :stable_id),
      "ignored_contact_ids" => row_list_values(rows, "ignored_contact_ids", :stable_id) || [],
      "ignored_selected_contact_ids" =>
        row_list_values(rows, "ignored_selected_contact_ids", :stable_id) || [],
      "required_downlink_contact_ids" =>
        row_list_values(rows, "required_downlink_contact_ids", :stable_id) || [],
      "actual_throughput_contact_ids" =>
        row_list_values(rows, "actual_throughput_contact_ids", :stable_id) || [],
      "actual_completion_contact_ids" =>
        row_list_values(rows, "actual_completion_contact_ids", :stable_id) || [],
      "unmatched_actual_throughput_contact_ids" =>
        row_list_values(rows, "unmatched_actual_throughput_contact_ids", :stable_id) || [],
      "ambiguous_actual_throughput_contact_ids" =>
        row_list_values(rows, "ambiguous_actual_throughput_contact_ids", :stable_id) || [],
      "unmatched_actual_completion_contact_ids" =>
        row_list_values(rows, "unmatched_actual_completion_contact_ids", :stable_id) || [],
      "ambiguous_actual_completion_contact_ids" =>
        row_list_values(rows, "ambiguous_actual_completion_contact_ids", :stable_id) || [],
      "ambiguous_selected_contact_ids" =>
        row_list_values(rows, "ambiguous_selected_contact_ids", :stable_id) || [],
      "unmatched_selected_contact_ids" =>
        report |> Map.get("unmatched_selected_contact_ids", []) |> sorted_stable_ids(),
      "invalid_contact_input_ids" =>
        invalid_input_row_contact_ids(
          report,
          "invalid_contact_inputs",
          "invalid_contact_input_ids"
        ),
      "invalid_selected_contact_input_ids" =>
        invalid_input_row_contact_ids(
          report,
          "invalid_selected_contact_inputs",
          "invalid_selected_contact_input_ids"
        ),
      "invalid_policy_required_downlink_station_ids" =>
        report_string_values(report, "invalid_policy_required_downlink_station_ids"),
      "ground_station_ids" => row_ground_station_ids(rows),
      "shortfall_ground_station_ids" =>
        station_ids_by_row_value(rows, "downlink_requirement_status", "shortfall"),
      "actual_shortfall_ground_station_ids" =>
        station_ids_by_row_value(rows, "actual_downlink_requirement_status", "shortfall"),
      "selected_downlink_shortfall_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "selected_downlink_shortfall_mb"),
      "actual_downlink_shortfall_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "actual_downlink_shortfall_mb"),
      "ground_station_ids_by_station_availability" =>
        row_station_ids_by_station_availability(rows),
      "ground_station_ids_by_reservation_match_status" =>
        row_station_ids_by_list_field(rows, "station_reservation_match_statuses"),
      "ground_station_ids_by_reservation_status" =>
        row_station_ids_by_list_field(rows, "station_reservation_statuses"),
      "ground_station_ids_by_reserved_by" =>
        row_station_ids_by_list_field(rows, "station_reserved_bys"),
      "station_calendar_entry_ids_by_ground_station_id" =>
        row_station_calendar_entry_ids_by_station(rows),
      "station_calendar_provider_ids_by_ground_station_id" =>
        row_station_calendar_provider_ids_by_station(rows),
      "station_calendar_provider_entry_ids_by_ground_station_id" =>
        row_station_calendar_provider_entry_ids_by_station(rows),
      "station_reservation_ids_by_ground_station_id" =>
        row_station_reservation_ids_by_station(rows),
      "ignored_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "ignored_contact_ids"),
      "selected_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "selected_contact_ids"),
      "capacity_adjusted_throughput_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "capacity_adjusted_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "selected_capacity_adjusted_throughput_mb"),
      "unused_capacity_adjusted_throughput_mb_by_ground_station_id" =>
        row_numeric_values_by_station(rows, "unused_capacity_adjusted_throughput_mb"),
      "required_downlink_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "required_downlink_contact_ids"),
      "actual_throughput_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "actual_throughput_contact_ids"),
      "actual_completion_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "actual_completion_contact_ids"),
      "unmatched_actual_throughput_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "unmatched_actual_throughput_contact_ids"),
      "ambiguous_actual_throughput_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "ambiguous_actual_throughput_contact_ids"),
      "unmatched_actual_completion_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "unmatched_actual_completion_contact_ids"),
      "ambiguous_actual_completion_contact_ids_by_ground_station_id" =>
        row_ids_by_station(rows, "ambiguous_actual_completion_contact_ids"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "link_capacity_report.v1",
        "operator_authority" => "not_granted_by_summary"
      }
    }
    |> compact_map()
  end

  defp row_ground_station_ids(rows) do
    rows
    |> Enum.map(& &1["ground_station_id"])
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp row_scalar_count_sum(rows, field) do
    Enum.reduce(rows, 0, fn row, total ->
      case Map.get(row, field) do
        count when is_integer(count) and count >= 0 -> total + count
        count when is_float(count) and count >= 0.0 -> total + trunc(count)
        _count -> total
      end
    end)
  end

  defp row_numeric_sum(rows, field) do
    rows
    |> Enum.map(&(Map.get(&1, field) |> numeric_value()))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp row_list_count(rows, field) do
    rows
    |> row_list_values(field, :stable_id)
    |> List.wrap()
    |> length()
  end

  defp report_list_count(report, rows_field, ids_field) do
    case Map.get(report, rows_field) do
      values when is_list(values) -> length(values)
      _values -> length(Map.get(report, ids_field) || [])
    end
  end

  defp invalid_input_row_contact_ids(report, rows_field, ids_field) do
    case Map.get(report, rows_field) do
      rows when is_list(rows) ->
        rows
        |> Enum.filter(&is_map/1)
        |> Enum.map(&Map.get(&1, "contact_id"))
        |> sorted_stable_ids()

      _rows ->
        report
        |> Map.get(ids_field, [])
        |> sorted_stable_ids()
    end
  end

  defp report_string_values(report, field) do
    report
    |> Map.get(field, [])
    |> normalized_string_values()
    |> List.wrap()
  end

  defp station_ids_by_row_value(rows, field, value) do
    rows
    |> Enum.filter(&(Map.get(&1, field) == value))
    |> row_ground_station_ids()
  end

  defp row_station_ids_by_station_availability(rows) do
    rows
    |> Enum.group_by(&station_availability/1, & &1["ground_station_id"])
    |> Enum.reject(fn {availability, station_ids} ->
      is_nil(availability) or Enum.all?(station_ids, &is_nil(stable_id_or_nil(&1)))
    end)
    |> Map.new(fn {availability, station_ids} ->
      {availability, sorted_stable_ids(station_ids)}
    end)
  end

  defp row_station_ids_by_list_field(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      row_values_by_list_field(row, field)
      |> Enum.map(&{&1, row["ground_station_id"]})
    end)
    |> Enum.group_by(fn {field_value, _station_id} -> field_value end, fn {_field_value,
                                                                           station_id} ->
      station_id
    end)
    |> Enum.reject(fn {field_value, station_ids} ->
      is_nil(field_value) or Enum.all?(station_ids, &is_nil(stable_id_or_nil(&1)))
    end)
    |> Map.new(fn {field_value, station_ids} ->
      {field_value, sorted_stable_ids(station_ids)}
    end)
  end

  defp row_values_by_list_field(row, "station_reservation_match_statuses"),
    do: row_station_reservation_match_statuses(row)

  defp row_values_by_list_field(row, "station_reservation_statuses"),
    do: row_station_reservation_statuses([row]) || []

  defp row_values_by_list_field(row, "station_reserved_bys"),
    do: row_station_reserved_bys([row]) || []

  defp row_values_by_list_field(row, field) do
    row
    |> Map.get(field, [])
    |> List.wrap()
  end

  defp row_station_calendar_entry_ids_by_station(rows) do
    rows
    |> Enum.map(fn row ->
      row_ids =
        [
          Map.get(row, "station_calendar_entry_ids"),
          source_station_calendar_values(row["source_station_calendar_entry"], [
            "id",
            "entry_id",
            "station_calendar_entry_id"
          ]),
          source_station_calendar_values(row["source_station_calendar_overlaps"], [
            "id",
            "entry_id",
            "station_calendar_entry_id"
          ])
        ]
        |> List.flatten()
        |> sorted_stable_ids()

      {row["ground_station_id"], row_ids}
    end)
    |> row_ids_by_station_entries()
  end

  defp row_station_calendar_provider_ids_by_station(rows) do
    rows
    |> Enum.map(fn row ->
      row_ids =
        [
          Map.get(row, "station_calendar_provider_ids"),
          source_station_calendar_values(row["source_station_calendar_entry"], [
            "provider_id",
            "station_calendar_provider_id"
          ]),
          source_station_calendar_values(row["source_station_calendar_overlaps"], [
            "provider_id",
            "station_calendar_provider_id"
          ])
        ]
        |> List.flatten()
        |> sorted_stable_ids()

      {row["ground_station_id"], row_ids}
    end)
    |> row_ids_by_station_entries()
  end

  defp row_station_calendar_provider_entry_ids_by_station(rows) do
    rows
    |> Enum.map(fn row ->
      row_ids =
        [
          Map.get(row, "station_calendar_provider_entry_ids"),
          source_station_calendar_values(row["source_station_calendar_entry"], [
            "provider_entry_id",
            "station_calendar_provider_entry_id"
          ]),
          source_station_calendar_values(row["source_station_calendar_overlaps"], [
            "provider_entry_id",
            "station_calendar_provider_entry_id"
          ])
        ]
        |> List.flatten()
        |> sorted_stable_ids()

      {row["ground_station_id"], row_ids}
    end)
    |> row_ids_by_station_entries()
  end

  defp row_station_reservation_ids_by_station(rows) do
    rows
    |> Enum.map(fn row ->
      {row["ground_station_id"], row_station_reservation_ids([row]) || []}
    end)
    |> row_ids_by_station_entries()
  end

  defp row_ids_by_station(rows, field) do
    rows
    |> Enum.map(fn row ->
      contact_ids =
        row
        |> Map.get(field, [])
        |> List.wrap()
        |> Enum.map(&stable_id_or_nil/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      {row["ground_station_id"], contact_ids}
    end)
    |> Enum.reject(fn {ground_station_id, contact_ids} ->
      is_nil(stable_id_or_nil(ground_station_id)) or contact_ids == []
    end)
    |> Map.new(fn {ground_station_id, contact_ids} ->
      {stable_id_or_nil(ground_station_id), contact_ids}
    end)
  end

  defp row_numeric_values_by_station(rows, field) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      station_id = stable_id_or_nil(row["ground_station_id"])
      value = row |> Map.get(field) |> numeric_value()

      if is_nil(station_id) or is_nil(value) do
        totals
      else
        Map.update(totals, station_id, value, &(&1 + value))
      end
    end)
  end

  defp row_ids_by_station_entries(entries) do
    entries
    |> Enum.reject(fn {ground_station_id, row_ids} ->
      is_nil(stable_id_or_nil(ground_station_id)) or row_ids == []
    end)
    |> Enum.reduce(%{}, fn {ground_station_id, row_ids}, ids_by_station ->
      station_id = stable_id_or_nil(ground_station_id)

      Map.update(ids_by_station, station_id, row_ids, fn existing_ids ->
        sorted_stable_ids(existing_ids ++ row_ids)
      end)
    end)
  end

  defp sorted_stable_ids(values) do
    values
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_id_counts(contacts) do
    contacts
    |> Enum.group_by(&contact_id/1)
    |> Map.new(fn {contact_id, grouped_contacts} -> {contact_id, length(grouped_contacts)} end)
  end

  defp duplicate_contact_ids(contact_id_counts) do
    contact_id_counts
    |> Enum.filter(fn {_contact_id, count} -> count > 1 end)
    |> Enum.map(fn {contact_id, _count} -> contact_id end)
    |> MapSet.new()
  end

  defp duplicate_contact_candidate_count(contacts, duplicate_contact_ids) do
    Enum.count(contacts, &MapSet.member?(duplicate_contact_ids, contact_id(&1)))
  end

  defp contact_feedback_context(contacts) do
    %{
      "contact_success" => aggregate_boolean_feedback(contacts, "contact_success"),
      "contact_result" => aggregate_string_feedback(contacts, "contact_result"),
      "contact_success_factor" => aggregate_factor_feedback(contacts, "contact_success_factor"),
      "contact_success_factor_source" =>
        aggregate_factor_source(
          contacts,
          "contact_success_factor",
          "contact_success_factor_source"
        ),
      "command_success" => aggregate_boolean_feedback(contacts, "command_success"),
      "command_result" => aggregate_string_feedback(contacts, "command_result"),
      "command_success_factor" => aggregate_factor_feedback(contacts, "command_success_factor"),
      "command_success_factor_source" =>
        aggregate_factor_source(
          contacts,
          "command_success_factor",
          "command_success_factor_source"
        )
    }
    |> compact_map()
  end

  defp aggregate_boolean_feedback(contacts, key) do
    values =
      contacts
      |> Enum.map(&boolean_feedback_value(&1, key))
      |> Enum.reject(&is_nil/1)

    cond do
      Enum.any?(values, &(&1 == false)) -> false
      Enum.any?(values, &(&1 == true)) -> true
      true -> nil
    end
  end

  defp aggregate_factor_feedback(contacts, key) do
    contacts
    |> Enum.map(&numeric_value(contact_value(&1, key)))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  defp aggregate_factor_source(contacts, factor_key, source_key) do
    contacts
    |> Enum.filter(&is_number(numeric_value(contact_value(&1, factor_key))))
    |> Enum.map(&contact_value(&1, source_key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> case do
      [source] -> source
      [_source | _rest] -> "mixed_feedback_sources"
      [] -> nil
    end
  end

  defp aggregate_string_feedback(contacts, key) do
    contacts
    |> Enum.map(&provider_result_artifact_value(contact_value(&1, key)))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [value] -> value
      [_value | _rest] -> "mixed"
      [] -> nil
    end
  end

  defp provider_result_values(values) when is_list(values) do
    values
    |> Enum.flat_map(&provider_result_values/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(%{} = result) do
    @provider_result_map_value_keys
    |> Enum.flat_map(fn key -> provider_result_values(Map.get(result, key)) end)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> []
      normalized -> [normalized]
    end
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(value) when is_atom(value),
    do: provider_result_values(Atom.to_string(value))

  defp provider_result_values(value), do: provider_result_values(to_string(value))

  defp provider_result_artifact_value(value) do
    case provider_result_values(value) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp contact_value(contact, key) do
    case Map.fetch(contact, key) do
      {:ok, nil} -> get_in(contact, ["metadata", key])
      {:ok, value} -> value
      :error -> get_in(contact, ["metadata", key])
    end
  end

  defp boolean_feedback_value(contact, key) do
    contact
    |> contact_value(key)
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

  defp station_calendar_directions(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        Map.get(contact, "station_calendar_directions"),
        get_in(contact, ["source_station_calendar_entry", "directions"]),
        get_in(contact, ["source_station_calendar_entry", "station_calendar_directions"])
      ]
    end)
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&normalized_direction_token/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      directions -> directions
    end
  end

  defp station_calendar_entry_ids(contacts) do
    station_calendar_ids(contacts, [
      ["station_calendar_entry_id"],
      ["source_station_calendar_entry", "id"],
      ["source_station_calendar_entry", "entry_id"],
      ["source_station_calendar_entry", "station_calendar_entry_id"]
    ])
  end

  defp station_calendar_provider_ids(contacts) do
    station_calendar_ids(contacts, [
      ["station_calendar_provider_id"],
      ["source_station_calendar_entry", "provider_id"],
      ["source_station_calendar_entry", "station_calendar_provider_id"]
    ])
  end

  defp station_calendar_provider_entry_ids(contacts) do
    station_calendar_ids(contacts, [
      ["station_calendar_provider_entry_id"],
      ["source_station_calendar_entry", "provider_entry_id"],
      ["source_station_calendar_entry", "station_calendar_provider_entry_id"]
    ])
  end

  defp station_calendar_ids(contacts, paths) do
    contacts
    |> Enum.flat_map(fn contact ->
      Enum.map(paths, &get_in(contact, &1))
    end)
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp row_list_values(rows, field, :stable_id) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, field)))
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp row_list_values(rows, field, :string) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, field)))
    |> normalized_string_values()
  end

  defp row_list_values(rows, field, :number) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, field)))
    |> normalized_number_values()
  end

  defp row_list_value_counts(rows, field) do
    rows
    |> Enum.flat_map(&(Map.get(&1, field) || []))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> empty_map_to_nil()
  end

  defp row_station_calendar_entry_ids(rows) do
    row_station_calendar_ids(rows, "station_calendar_entry_ids", [
      "id",
      "entry_id",
      "station_calendar_entry_id"
    ])
  end

  defp row_station_calendar_provider_ids(rows) do
    row_station_calendar_ids(rows, "station_calendar_provider_ids", [
      "provider_id",
      "station_calendar_provider_id"
    ])
  end

  defp row_station_calendar_provider_entry_ids(rows) do
    row_station_calendar_ids(rows, "station_calendar_provider_entry_ids", [
      "provider_entry_id",
      "station_calendar_provider_entry_id"
    ])
  end

  defp row_station_calendar_ids(rows, row_field, source_fields) do
    [
      row_list_values(rows, row_field, :stable_id),
      row_source_station_calendar_values(rows, source_fields)
    ]
    |> List.flatten()
    |> sorted_stable_ids()
    |> empty_list_to_nil()
  end

  defp row_station_reservation_ids(rows) do
    [
      row_list_values(rows, "station_reservation_ids", :stable_id),
      station_reservation_ids(rows)
    ]
    |> List.flatten()
    |> sorted_stable_ids()
    |> empty_list_to_nil()
  end

  defp row_station_reservation_expires_at_s(rows) do
    [
      row_list_values(rows, "station_reservation_expires_at_s", :number),
      station_reservation_expires_at_s(rows)
    ]
    |> normalized_number_values()
  end

  defp row_station_reserved_bys(rows) do
    [
      row_list_values(rows, "station_reserved_bys", :string),
      station_reserved_bys(rows)
    ]
    |> normalized_string_values()
  end

  defp row_station_reservation_statuses(rows) do
    [
      row_list_values(rows, "station_reservation_statuses", :string),
      station_reservation_statuses(rows)
    ]
    |> normalized_status_values()
  end

  defp row_station_reservation_match_status_counts(rows) do
    rows
    |> Enum.flat_map(&row_station_reservation_match_statuses/1)
    |> Enum.frequencies()
    |> empty_map_to_nil()
  end

  defp row_station_reservation_match_statuses(row) do
    [
      row["station_reservation_match_status"],
      row["reservation_match_status"],
      row["station_reservation_match_statuses"],
      source_station_calendar_values(row["source_station_calendar_entry"], [
        "station_reservation_match_status",
        "reservation_match_status"
      ]),
      source_station_calendar_values(row["source_station_calendar_overlaps"], [
        "station_reservation_match_status",
        "reservation_match_status"
      ])
    ]
    |> normalized_status_values()
    |> List.wrap()
  end

  defp row_source_station_calendar_values(rows, source_fields) do
    rows
    |> Enum.flat_map(fn row ->
      source_station_calendar_values(row["source_station_calendar_entry"], source_fields) ++
        source_station_calendar_values(row["source_station_calendar_overlaps"], source_fields)
    end)
  end

  defp row_count_map(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      case Map.get(row, field) do
        counts when is_map(counts) -> Map.to_list(counts)
        _counts -> []
      end
    end)
    |> Enum.reduce(%{}, fn
      {key, count}, acc when is_number(count) ->
        Map.update(acc, to_string(key), count, &(&1 + count))

      _entry, acc ->
        acc
    end)
    |> empty_map_to_nil()
  end

  defp station_reservation_ids(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reservation_id"],
        contact["reservation_id"]
      ] ++
        source_station_calendar_reservation_ids(contact["source_station_calendar_entry"]) ++
        source_station_calendar_reservation_ids(contact["source_station_calendar_overlaps"])
    end)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp station_reservation_expires_at_s(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reservation_expires_at_s"],
        contact["reservation_expires_at_s"],
        contact["reservation_hold_expires_at_s"],
        contact["hold_expires_at_s"],
        contact["expires_at_s"],
        contact["expires_at"],
        contact["station_calendar_reservation_expires_at_s"]
      ] ++
        source_station_calendar_number_values(contact["source_station_calendar_entry"], [
          "station_calendar_reservation_expires_at_s",
          "station_reservation_expires_at_s",
          "reservation_expires_at_s",
          "reservation_hold_expires_at_s",
          "hold_expires_at_s",
          "expires_at_s",
          "expires_at"
        ]) ++
        source_station_calendar_number_values(contact["source_station_calendar_overlaps"], [
          "station_calendar_reservation_expires_at_s",
          "station_reservation_expires_at_s",
          "reservation_expires_at_s",
          "reservation_hold_expires_at_s",
          "hold_expires_at_s",
          "expires_at_s",
          "expires_at"
        ])
    end)
    |> normalized_number_values()
  end

  defp station_reserved_bys(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reserved_by"],
        contact["reserved_by"]
      ] ++
        source_station_calendar_values(contact["source_station_calendar_entry"], [
          "station_reserved_by",
          "reserved_by"
        ]) ++
        source_station_calendar_values(contact["source_station_calendar_overlaps"], [
          "station_reserved_by",
          "reserved_by"
        ])
    end)
    |> normalized_string_values()
  end

  defp station_reservation_statuses(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reservation_status"],
        contact["reservation_status"]
      ] ++
        source_station_calendar_values(contact["source_station_calendar_entry"], [
          "station_reservation_status",
          "reservation_status"
        ]) ++
        source_station_calendar_values(contact["source_station_calendar_overlaps"], [
          "station_reservation_status",
          "reservation_status"
        ])
    end)
    |> normalized_status_values()
  end

  defp station_reservation_match_statuses(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reservation_match_status"],
        contact["reservation_match_status"]
      ] ++
        source_station_calendar_values(contact["source_station_calendar_entry"], [
          "station_reservation_match_status",
          "reservation_match_status"
        ]) ++
        source_station_calendar_values(contact["source_station_calendar_overlaps"], [
          "station_reservation_match_status",
          "reservation_match_status"
        ])
    end)
    |> normalized_status_values()
  end

  defp source_station_calendar_reservation_ids(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_reservation_ids/1)

  defp source_station_calendar_reservation_ids(%{} = source) do
    explicit_ids =
      source_station_calendar_values(source, ["station_reservation_id", "reservation_id"])
      |> Enum.reject(&is_nil/1)

    cond do
      explicit_ids != [] ->
        explicit_ids

      reserved_station_calendar_source?(source) ->
        source_station_calendar_values(source, [
          "id",
          "entry_id",
          "station_calendar_entry_id"
        ])

      true ->
        []
    end
  end

  defp source_station_calendar_reservation_ids(_source), do: []

  defp source_station_calendar_values(sources, fields) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_values(&1, fields))

  defp source_station_calendar_values(%{} = source, fields),
    do: Enum.map(fields, &Map.get(source, &1))

  defp source_station_calendar_values(_source, _fields), do: []

  defp source_station_calendar_number_values(sources, fields) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_number_values(&1, fields))

  defp source_station_calendar_number_values(%{} = source, fields) do
    fields
    |> Enum.flat_map(fn field -> List.wrap(Map.get(source, field)) end)
  end

  defp source_station_calendar_number_values(_source, _fields), do: []

  defp reserved_station_calendar_source?(source) do
    source
    |> source_station_calendar_availability_candidates()
    |> Enum.any?(&(&1 == "reserved"))
  end

  defp normalized_string_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&string_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp normalized_number_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp normalized_status_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&normalized_status_token/1)
    |> Enum.map(&string_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp string_value(value) when value in [nil, ""], do: nil

  defp string_value(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp string_value(value) when is_atom(value), do: value |> Atom.to_string() |> string_value()
  defp string_value(value) when is_integer(value), do: Integer.to_string(value)
  defp string_value(value), do: value |> to_string() |> string_value()

  defp ignored_contact_ids(contacts) do
    contacts
    |> Enum.reject(&project_contact_capacity?/1)
    |> Enum.map(&contact_id/1)
    |> Enum.sort()
  end

  defp ignored_contact_reason_counts(contacts) do
    contacts
    |> Enum.reject(&project_contact_capacity?/1)
    |> Enum.map(&ignored_contact_reason/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp project_contact_capacity?(contact) do
    status = contact_status(contact)
    approval_status = contact_approval_status(contact)

    status not in terminal_contact_statuses() and approval_status != "rejected"
  end

  defp ignored_contact_reason(contact) do
    status = contact_status(contact)
    approval_status = contact_approval_status(contact)

    cond do
      approval_status == "rejected" -> "approval_status_rejected"
      status in terminal_contact_statuses() -> "activity_status_#{status}"
      true -> nil
    end
  end

  defp terminal_contact_statuses,
    do: ~w(canceled cancelled completed executed failed missed partial rejected)

  defp contact_status(contact) do
    Map.get(contact, "status") || get_in(contact, ["metadata", "status"]) || "planned"
  end

  defp contact_approval_status(contact) do
    Map.get(contact, "approval_status") || get_in(contact, ["metadata", "approval_status"])
  end

  defp downlink_like_input?(contact) do
    Map.get(contact, "invalid_contact_shape") == true or
      Map.get(contact, "type") == "downlink" or
      (Map.get(contact, "direction") == "downlink" and
         Map.get(contact, "type") in [nil, "contact", "planned_contact"]) or
      throughput_contact_input?(contact)
  end

  defp throughput_contact_input?(contact) do
    downlink_inference_allowed? =
      Map.get(contact, "type") in [nil, "contact", "planned_contact"] and
        Map.get(contact, "direction") in [nil, "downlink"]

    downlink_inference_allowed? and
      (Enum.any?(
         [
           estimated_throughput_value(contact),
           actual_throughput_value(contact),
           actual_throughput_model_value(contact),
           completed_fraction_value(contact)
         ],
         &is_number/1
       ) or declared_unit_interval_feedback?(contact))
  end

  defp declared_unit_interval_feedback?(contact) do
    contact_value(contact, "contact_success_factor") != nil or
      contact_value(contact, "command_success_factor") != nil or
      completed_fraction_values(contact) != []
  end

  defp invalid_link_capacity_input?(contact), do: not valid_link_capacity_input?(contact)

  defp valid_link_capacity_input?(contact) do
    is_nil(contact_id_issue(contact)) and
      is_nil(contact_identity_issue(contact)) and
      is_nil(contact_feedback_factor_issue(contact)) and
      is_nil(completed_fraction_issue(contact)) and
      not is_nil(contact_ground_station_id(contact))
  end

  defp invalid_contact_input_reason(contact) do
    cond do
      Map.get(contact, "invalid_contact_shape") == true -> "invalid_contact_shape"
      reason = contact_id_issue(contact) -> reason
      reason = contact_identity_issue(contact) -> reason
      reason = contact_feedback_factor_issue(contact) -> reason
      reason = completed_fraction_issue(contact) -> reason
      is_nil(contact_ground_station_id(contact)) -> "missing_ground_station_id"
      true -> "invalid_contact_input"
    end
  end

  defp contact_feedback_factor_issue(contact) do
    Enum.find_value(["contact_success_factor", "command_success_factor"], fn field ->
      case contact_value(contact, field) do
        nil ->
          nil

        value ->
          case numeric_value(value) do
            number when is_number(number) ->
              if number >= 0.0 and number <= 1.0, do: nil, else: "invalid_#{field}"

            _value ->
              "invalid_#{field}"
          end
      end
    end)
  end

  defp completed_fraction_issue(contact) do
    Enum.find_value(completed_fraction_values(contact), fn {field, value} ->
      case numeric_value(value) do
        number when is_number(number) ->
          if number >= 0.0 and number <= 1.0, do: nil, else: "invalid_#{field}"

        _value ->
          "invalid_#{field}"
      end
    end)
  end

  defp invalid_contact_input_ids(invalid_contact_inputs) do
    invalid_contact_inputs
    |> Enum.map(fn {contact, index} ->
      reason = invalid_contact_input_reason(contact)

      contact_id_or_nil(contact) || invalid_contact_row_id(reason, index)
    end)
    |> Enum.sort()
  end

  defp invalid_contact_rows(invalid_contact_inputs, input_role, approval_policy) do
    invalid_contact_inputs
    |> Enum.map(fn {contact, index} ->
      reason = invalid_contact_input_reason(contact)
      contact_id = contact_id_or_nil(contact) || invalid_contact_row_id(reason, index)

      %{
        "id" => "link_capacity:invalid_contact_input:#{input_role}:#{contact_id}",
        "contact_id" => contact_id,
        "contact_ids" => [contact_id],
        "input_role" => input_role,
        "type" => contact["type"],
        "scenario_id" => stable_id_or_nil(contact["scenario_id"]),
        "spacecraft_id" => contact_spacecraft_id(contact),
        "ground_station_id" => contact_ground_station_id(contact),
        "direction" => contact["direction"] || "downlink",
        "starts_at_s" => contact["starts_at_s"],
        "ends_at_s" => contact["ends_at_s"],
        "required_operator_action" => "review_invalid_link_capacity_input",
        "approval_status" => "operator_review_required",
        "review_status" => "operator_review_required",
        "invalid_contact_input" => true,
        "invalid_contact_input_reason" => reason,
        "source_contact_candidate" => contact
      }
      |> compact_map()
      |> maybe_apply_invalid_input_approval_policy(approval_policy)
    end)
    |> Enum.sort_by(&{&1["input_role"], &1["contact_id"]})
  end

  defp contact_capacity_fraction(contact) do
    if contact_station_availability(contact) == "unavailable" do
      0.0
    else
      contact
      |> capacity_fraction_value()
      |> clamp_unit_interval()
    end
  end

  defp capacity_fraction_value(contact) do
    (capacity_fraction_from_paths(contact, @station_capacity_value_paths) ||
       source_station_capacity_fraction(contact["source_station_calendar_entry"]) ||
       source_station_capacity_fraction(contact["source_station_calendar_overlaps"]))
    |> case do
      value when is_number(value) -> value
      _value -> 1.0
    end
  end

  defp source_station_capacity_fraction(sources) when is_list(sources) do
    sources
    |> Enum.map(&source_station_capacity_fraction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> case do
      [capacity_fraction] -> capacity_fraction
      _ambiguous_or_missing -> nil
    end
  end

  defp source_station_capacity_fraction(%{} = source),
    do: capacity_fraction_from_paths(source, @station_capacity_value_paths)

  defp source_station_capacity_fraction(_source), do: nil

  defp capacity_fraction_from_paths(value, paths) do
    paths
    |> Enum.find_value(fn
      {:fraction, path} ->
        value |> path_value(path) |> numeric_value()

      {:percent, path} ->
        case numeric_value(path_value(value, path)) do
          value when is_number(value) -> value / 100.0
          _value -> nil
        end
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp total_estimated_throughput(contacts) do
    contacts
    |> Enum.map(&(estimated_throughput_value(&1) || 0.0))
    |> Enum.sum()
  end

  defp total_capacity_adjusted_throughput(contacts) do
    contacts
    |> Enum.map(fn contact ->
      (estimated_throughput_value(contact) || 0.0) * contact_capacity_fraction(contact)
    end)
    |> Enum.sum()
  end

  defp actual_throughput_resolution(selected_downlinks, contact_id_counts) do
    selected_downlinks
    |> Enum.filter(
      &(is_number(actual_throughput_value(&1)) or is_number(actual_throughput_model_value(&1)))
    )
    |> Enum.group_by(&contact_id/1)
    |> Enum.reduce(
      %{matched_contacts: [], unmatched_contact_ids: [], ambiguous_contact_ids: []},
      fn {contact_id, contacts}, acc ->
        case {Map.get(contact_id_counts, contact_id, 0), contacts} do
          {0, _contacts} ->
            Map.update!(acc, :unmatched_contact_ids, &[contact_id | &1])

          {1, [contact]} ->
            Map.update!(acc, :matched_contacts, &[contact | &1])

          {_candidate_count, _contacts} ->
            Map.update!(acc, :ambiguous_contact_ids, &[contact_id | &1])
        end
      end
    )
    |> Map.new(fn
      {:matched_contacts, contacts} -> {:matched_contacts, Enum.sort_by(contacts, &contact_id/1)}
      {key, ids} -> {key, ids |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp actual_completion_resolution(selected_downlinks, contact_id_counts) do
    selected_downlinks
    |> Enum.filter(&is_number(completed_fraction_value(&1)))
    |> Enum.group_by(&contact_id/1)
    |> Enum.reduce(
      %{matched_contacts: [], unmatched_contact_ids: [], ambiguous_contact_ids: []},
      fn {contact_id, contacts}, acc ->
        case {Map.get(contact_id_counts, contact_id, 0), contacts} do
          {0, _contacts} ->
            Map.update!(acc, :unmatched_contact_ids, &[contact_id | &1])

          {1, [contact]} ->
            Map.update!(acc, :matched_contacts, &[contact | &1])

          {_candidate_count, _contacts} ->
            Map.update!(acc, :ambiguous_contact_ids, &[contact_id | &1])
        end
      end
    )
    |> Map.new(fn
      {:matched_contacts, contacts} -> {:matched_contacts, Enum.sort_by(contacts, &contact_id/1)}
      {key, ids} -> {key, ids |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp unresolved_selected_contact_ids(selected_downlinks, unresolved_ids, ground_station_id, fun) do
    unresolved_id_set = MapSet.new(unresolved_ids)

    selected_downlinks
    |> Enum.filter(&(contact_ground_station_id(&1) == ground_station_id))
    |> Enum.filter(fun)
    |> Enum.map(&contact_id/1)
    |> Enum.filter(&MapSet.member?(unresolved_id_set, &1))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp actual_throughput_evidence?(contact) do
    is_number(actual_throughput_value(contact)) or
      is_number(actual_throughput_model_value(contact))
  end

  defp actual_completion_evidence?(contact), do: is_number(completed_fraction_value(contact))

  defp optional_contact_count([]), do: nil
  defp optional_contact_count(ids), do: length(ids)

  defp optional_contact_ids([]), do: nil
  defp optional_contact_ids(ids), do: ids

  defp actual_throughput_mb([]), do: nil

  defp actual_throughput_mb(contacts) do
    contacts
    |> Enum.map(&(actual_throughput_value(&1) || actual_throughput_model_value(&1)))
    |> Enum.sum()
  end

  defp actual_data_rate_throughput_derivations(contacts) do
    contacts
    |> Enum.map(fn contact ->
      case actual_data_rate_throughput_derivation(contact) do
        %{} = derivation -> Map.put(derivation, "contact_id", contact_id(contact))
        _derivation -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1["contact_id"])
    |> case do
      [] -> nil
      derivations -> derivations
    end
  end

  defp actual_completion_fraction([]), do: nil

  defp actual_completion_fraction(contacts) do
    values =
      contacts
      |> Enum.map(&completed_fraction_value/1)
      |> Enum.reject(&is_nil/1)

    case values do
      [] -> nil
      values -> Enum.sum(values) / length(values)
    end
  end

  defp estimated_throughput_value(contact) do
    first_number(contact, [
      "estimated_throughput_mb",
      "estimated_downlink_mb",
      "planned_throughput_mb",
      "planned_data_volume_mb",
      "estimated_data_volume_mb",
      "data_volume_mb"
    ]) ||
      first_number(get_in(contact, ["throughput_model"]) || %{}, [
        "estimated_throughput_mb",
        "estimated_downlink_mb",
        "planned_throughput_mb",
        "planned_data_volume_mb",
        "estimated_data_volume_mb",
        "data_volume_mb"
      ]) ||
      data_rate_derived_throughput_mb(contact)
  end

  defp actual_throughput_value(contact) do
    explicit_actual_throughput_value(contact) ||
      actual_data_rate_derived_throughput_mb(contact)
  end

  defp explicit_actual_throughput_value(contact) do
    first_number(contact, [
      "actual_throughput_mb",
      "actual_downlink_mb",
      "actual_data_volume_mb",
      "delivered_data_mb",
      "received_data_mb"
    ])
  end

  defp actual_throughput_model_value(contact) do
    explicit_actual_throughput_model_value(contact) ||
      actual_data_rate_derived_throughput_mb(get_in(contact, ["throughput_model"]) || %{})
  end

  defp explicit_actual_throughput_model_value(contact) do
    first_number(get_in(contact, ["throughput_model"]) || %{}, [
      "actual_throughput_mb",
      "actual_downlink_mb",
      "actual_data_volume_mb",
      "delivered_data_mb",
      "received_data_mb"
    ])
  end

  defp data_rate_derived_throughput_mb(contact) do
    duration_s = contact_duration_s(contact)

    cond do
      not is_number(duration_s) or duration_s <= 0.0 ->
        nil

      rate_mb_s = data_rate_mb_s(contact) ->
        max(rate_mb_s, 0.0) * duration_s

      rate_mbps = data_rate_mbps(contact) ->
        max(rate_mbps, 0.0) * duration_s / 8.0

      true ->
        nil
    end
  end

  defp actual_data_rate_derived_throughput_mb(contact) do
    case actual_data_rate_throughput_derivation_from_contact(contact) do
      %{"actual_throughput_mb" => actual_throughput_mb} when is_number(actual_throughput_mb) ->
        actual_throughput_mb

      _derivation ->
        nil
    end
  end

  defp actual_data_rate_throughput_derivation(contact) do
    cond do
      is_number(explicit_actual_throughput_value(contact)) ->
        nil

      derivation = actual_data_rate_throughput_derivation_from_contact(contact) ->
        derivation

      is_number(explicit_actual_throughput_model_value(contact)) ->
        nil

      true ->
        actual_data_rate_throughput_derivation_from_contact(
          get_in(contact, ["throughput_model"]) || %{}
        )
    end
  end

  defp actual_data_rate_throughput_derivation_from_contact(contact) do
    duration_s = actual_duration_s(contact)

    cond do
      not is_number(duration_s) or duration_s <= 0.0 ->
        nil

      rate_mb_s = actual_data_rate_mb_s(contact) ->
        normalized_rate_mb_s = max(rate_mb_s, 0.0)

        %{
          "derivation" => "actual_data_rate_mb_s * duration_s",
          "rate_unit" => "MB/s",
          "actual_data_rate_mb_s" => normalized_rate_mb_s,
          "duration_s" => duration_s,
          "actual_throughput_mb" => normalized_rate_mb_s * duration_s
        }

      rate_mbps = actual_data_rate_mbps(contact) ->
        normalized_rate_mbps = max(rate_mbps, 0.0)

        %{
          "derivation" => "actual_data_rate_mbps * duration_s / 8",
          "rate_unit" => "Mbps",
          "actual_data_rate_mbps" => normalized_rate_mbps,
          "duration_s" => duration_s,
          "actual_throughput_mb" => normalized_rate_mbps * duration_s / 8.0
        }

      true ->
        nil
    end
  end

  defp data_rate_mb_s(contact) do
    first_number(contact, [
      "data_rate_mb_s",
      "downlink_rate_mb_s",
      "throughput_mb_s",
      "estimated_throughput_mb_s"
    ]) ||
      first_number(get_in(contact, ["throughput_model"]) || %{}, [
        "data_rate_mb_s",
        "downlink_rate_mb_s",
        "throughput_mb_s",
        "estimated_throughput_mb_s"
      ])
  end

  defp data_rate_mbps(contact) do
    first_number(contact, [
      "data_rate_mbps",
      "downlink_rate_mbps",
      "bitrate_mbps",
      "estimated_bitrate_mbps"
    ]) ||
      first_number(get_in(contact, ["throughput_model"]) || %{}, [
        "data_rate_mbps",
        "downlink_rate_mbps",
        "bitrate_mbps",
        "estimated_bitrate_mbps"
      ])
  end

  defp actual_data_rate_mb_s(contact) do
    first_number(contact, [
      "actual_data_rate_mb_s",
      "actual_downlink_rate_mb_s",
      "delivered_rate_mb_s",
      "received_rate_mb_s"
    ])
  end

  defp actual_data_rate_mbps(contact) do
    first_number(contact, [
      "actual_data_rate_mbps",
      "actual_downlink_rate_mbps",
      "delivered_rate_mbps",
      "received_rate_mbps"
    ])
  end

  defp contact_duration_s(contact) do
    first_number(contact, ["duration_s", "contact_duration_s", "scheduled_duration_s"]) ||
      first_number(get_in(contact, ["throughput_model"]) || %{}, [
        "duration_s",
        "contact_duration_s",
        "scheduled_duration_s"
      ]) ||
      interval_duration_s(contact)
  end

  defp actual_duration_s(contact) do
    first_number(contact, ["actual_duration_s", "actual_contact_duration_s"]) ||
      contact_duration_s(contact)
  end

  defp interval_duration_s(contact) do
    starts_at_s = numeric_value(Map.get(contact, "starts_at_s"))
    ends_at_s = numeric_value(Map.get(contact, "ends_at_s"))

    if is_number(starts_at_s) and is_number(ends_at_s) do
      ends_at_s - starts_at_s
    end
  end

  defp completed_fraction_value(contact) do
    case completed_fraction_values(contact) do
      [] ->
        nil

      values ->
        values
        |> Enum.find_value(fn {_field, value} ->
          case numeric_value(value) do
            number when is_number(number) and number >= 0.0 and number <= 1.0 -> number
            _value -> nil
          end
        end)
    end
  end

  defp completed_fraction_values(contact) do
    top_level =
      declared_values(contact, [
        "completed_fraction",
        "completion_fraction",
        "contact_completion_fraction"
      ])

    throughput_model =
      contact
      |> get_in(["throughput_model"])
      |> case do
        %{} = throughput_model ->
          declared_values(throughput_model, [
            "completed_fraction",
            "completion_fraction",
            "contact_completion_fraction"
          ])

        _value ->
          []
      end

    top_level ++ throughput_model
  end

  defp declared_values(map, keys) when is_map(map) do
    Enum.flat_map(keys, fn key ->
      case Map.fetch(map, key) do
        {:ok, nil} -> []
        {:ok, value} -> [{key, value}]
        :error -> []
      end
    end)
  end

  defp first_number(map, keys) do
    Enum.find_value(keys, fn key ->
      value = Map.get(map, key)
      numeric_value(value)
    end)
  end

  defp actual_throughput_contact_ids(contacts) do
    contacts
    |> Enum.map(&contact_id/1)
    |> Enum.sort()
  end

  defp actual_completion_contact_ids(contacts), do: actual_throughput_contact_ids(contacts)

  defp unused_capacity_adjusted_throughput(capacity_adjusted, selected_capacity_adjusted)
       when is_number(capacity_adjusted) and is_number(selected_capacity_adjusted) do
    max(capacity_adjusted - selected_capacity_adjusted, 0.0)
  end

  defp selected_capacity_utilization_fraction(capacity_adjusted, selected_capacity_adjusted)
       when is_number(capacity_adjusted) and capacity_adjusted > 0 and
              is_number(selected_capacity_adjusted) do
    selected_capacity_adjusted / capacity_adjusted
  end

  defp selected_capacity_utilization_fraction(_capacity_adjusted, _selected_capacity_adjusted),
    do: 0.0

  defp clamp_unit_interval(value), do: value |> max(0.0) |> min(1.0)

  defp selection_utilization_status(capacity_adjusted, _selected_capacity_adjusted)
       when not is_number(capacity_adjusted) or capacity_adjusted <= 0,
       do: "no_downlink_capacity"

  defp selection_utilization_status(capacity_adjusted, selected_capacity_adjusted)
       when is_number(selected_capacity_adjusted) and selected_capacity_adjusted <= 0 and
              capacity_adjusted > 0,
       do: "unselected_capacity"

  defp selection_utilization_status(capacity_adjusted, selected_capacity_adjusted)
       when selected_capacity_adjusted < capacity_adjusted,
       do: "partial_capacity_selected"

  defp selection_utilization_status(_capacity_adjusted, _selected_capacity_adjusted),
    do: "fully_selected"

  defp report_required_downlink_mb(policy, contacts) do
    numeric_value(Map.get(policy, "required_downlink_mb")) ||
      policy
      |> Map.get("required_downlink_mb_by_ground_station", %{})
      |> station_required_downlink_values()
      |> Map.values()
      |> Enum.sum()
      |> positive_or_nil() ||
      total_required_downlink_mb(contacts)
  end

  defp station_required_downlink_mb(ground_station_id, policy, contacts) do
    policy
    |> policy_station_required_downlink_values()
    |> Map.get(ground_station_id) ||
      total_required_downlink_mb(contacts)
  end

  defp policy_station_required_downlink_values(policy) do
    policy
    |> Map.get("required_downlink_mb_by_ground_station", %{})
    |> station_required_downlink_values()
  end

  defp station_required_downlink_values(%{} = values) do
    values
    |> Enum.map(fn {station_id, value} ->
      {stable_id_or_nil(station_id), numeric_value(value)}
    end)
    |> Enum.reject(fn {station_id, value} -> is_nil(station_id) or is_nil(value) end)
    |> Map.new()
  end

  defp station_required_downlink_values(_values), do: %{}

  defp invalid_policy_required_downlink_station_ids(policy) do
    policy
    |> Map.get("required_downlink_mb_by_ground_station", %{})
    |> invalid_station_required_downlink_ids()
  end

  defp invalid_station_required_downlink_ids(%{} = values) do
    values
    |> Enum.filter(fn {station_id, value} ->
      is_nil(stable_id_or_nil(station_id)) and positive_number?(numeric_value(value))
    end)
    |> Enum.map(fn {station_id, _value} -> policy_station_id_to_string(station_id) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp invalid_station_required_downlink_ids(_values), do: []

  defp positive_number?(value), do: is_number(value) and value > 0

  defp policy_station_id_to_string(station_id) when is_binary(station_id), do: station_id

  defp policy_station_id_to_string(station_id)
       when is_atom(station_id) and not is_nil(station_id),
       do: Atom.to_string(station_id)

  defp policy_station_id_to_string(station_id) when is_integer(station_id),
    do: Integer.to_string(station_id)

  defp policy_station_id_to_string(station_id) when is_float(station_id),
    do: Float.to_string(station_id)

  defp policy_station_id_to_string(station_id), do: inspect(station_id)

  defp total_required_downlink_mb(contacts) do
    contacts
    |> Enum.map(&contact_required_downlink_mb/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
    |> positive_or_nil()
  end

  defp required_downlink_contact_ids(contacts) do
    contacts
    |> Enum.filter(fn contact ->
      case contact_required_downlink_mb(contact) do
        value when is_number(value) and value > 0.0 -> true
        _value -> false
      end
    end)
    |> Enum.map(&contact_id/1)
    |> Enum.sort()
  end

  defp downlink_completion_source(policy, contacts) do
    cond do
      positive_number?(numeric_value(Map.get(policy, "required_downlink_mb"))) ->
        "link_capacity.policy.required_downlink_mb"

      map_size(policy_station_required_downlink_values(policy)) > 0 ->
        "link_capacity.policy.required_downlink_mb_by_ground_station"

      total_required_downlink_mb(contacts) ->
        "link_capacity.contact.required_downlink_mb"

      true ->
        nil
    end
  end

  defp downlink_completion_source(ground_station_id, policy, contacts) do
    cond do
      Map.has_key?(policy_station_required_downlink_values(policy), ground_station_id) ->
        "link_capacity.policy.required_downlink_mb_by_ground_station"

      total_required_downlink_mb(contacts) ->
        "link_capacity.contact.required_downlink_mb"

      true ->
        nil
    end
  end

  defp downlink_completion_sources(policy, contacts) do
    cond do
      positive_number?(numeric_value(Map.get(policy, "required_downlink_mb"))) ->
        ["link_capacity.policy.required_downlink_mb"]

      policy_station_required_downlink_values(policy) != %{} ->
        policy
        |> policy_station_required_downlink_values()
        |> Map.keys()
        |> Enum.sort()
        |> Enum.map(&"link_capacity.policy.required_downlink_mb_by_ground_station:#{&1}")

      true ->
        contact_downlink_completion_sources(contacts)
    end
  end

  defp downlink_completion_sources(ground_station_id, policy, contacts) do
    if Map.has_key?(policy_station_required_downlink_values(policy), ground_station_id) do
      ["link_capacity.policy.required_downlink_mb_by_ground_station:#{ground_station_id}"]
    else
      contact_downlink_completion_sources(contacts)
    end
  end

  defp contact_downlink_completion_sources(contacts) when is_list(contacts) do
    contacts
    |> Enum.filter(fn contact ->
      case contact_required_downlink_mb(contact) do
        value when is_number(value) and value > 0.0 -> true
        _value -> false
      end
    end)
    |> Enum.flat_map(&contact_downlink_completion_sources/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp contact_downlink_completion_sources(contact) when is_map(contact) do
    first_string_list(path_values(contact, @downlink_completion_sources_paths)) ||
      first_string_list(Enum.map(path_values(contact, @downlink_completion_source_paths), &[&1])) ||
      ["link_capacity.contact.required_downlink_mb:#{contact_id(contact)}"]
  end

  defp first_string_list(values) do
    Enum.find_value(values, fn
      values when is_list(values) ->
        values =
          values
          |> Enum.map(fn
            value when is_binary(value) -> value
            value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
            value when is_integer(value) -> Integer.to_string(value)
            _value -> nil
          end)
          |> Enum.reject(&(&1 == ""))
          |> Enum.reject(&is_nil/1)

        if values == [], do: nil, else: values

      _value ->
        nil
    end)
  end

  defp empty_list_to_nil([]), do: nil
  defp empty_list_to_nil(values), do: values

  defp empty_map_to_nil(map) when map == %{}, do: nil
  defp empty_map_to_nil(map), do: map

  defp contact_required_downlink_mb(contact) do
    contact
    |> path_values(@contact_required_downlink_paths)
    |> Enum.find_value(&numeric_value/1)
  end

  defp path_values(value, paths), do: Enum.map(paths, &path_value(value, &1))

  defp selected_downlink_shortfall_mb(nil, _selected_capacity_adjusted), do: nil

  defp selected_downlink_shortfall_mb(required_downlink_mb, selected_capacity_adjusted)
       when is_number(required_downlink_mb) and is_number(selected_capacity_adjusted) do
    max(required_downlink_mb - selected_capacity_adjusted, 0.0)
  end

  defp selected_downlink_shortfall_mb(_required_downlink_mb, _selected_capacity_adjusted),
    do: nil

  defp downlink_requirement_status(nil, _selected_capacity_adjusted), do: nil

  defp downlink_requirement_status(required_downlink_mb, selected_capacity_adjusted)
       when is_number(required_downlink_mb) and is_number(selected_capacity_adjusted) and
              selected_capacity_adjusted >= required_downlink_mb,
       do: "satisfied"

  defp downlink_requirement_status(required_downlink_mb, selected_capacity_adjusted)
       when is_number(required_downlink_mb) and is_number(selected_capacity_adjusted) and
              selected_capacity_adjusted < required_downlink_mb,
       do: "shortfall"

  defp downlink_requirement_status(_required_downlink_mb, _selected_capacity_adjusted), do: nil

  defp actual_downlink_shortfall_mb(_required_downlink_mb, nil), do: nil

  defp actual_downlink_shortfall_mb(required_downlink_mb, actual_throughput_mb),
    do: selected_downlink_shortfall_mb(required_downlink_mb, actual_throughput_mb)

  defp actual_downlink_completion_ratio(required_downlink_mb, actual_throughput_mb)
       when is_number(required_downlink_mb) and required_downlink_mb > 0.0 and
              is_number(actual_throughput_mb) do
    actual_throughput_mb
    |> Kernel./(required_downlink_mb)
    |> clamp_unit_interval()
  end

  defp actual_downlink_completion_ratio(_required_downlink_mb, _actual_throughput_mb), do: nil

  defp actual_downlink_requirement_status(_required_downlink_mb, nil), do: nil

  defp actual_downlink_requirement_status(required_downlink_mb, actual_throughput_mb),
    do: downlink_requirement_status(required_downlink_mb, actual_throughput_mb)

  defp positive_or_nil(value) when is_number(value) and value > 0.0, do: value
  defp positive_or_nil(_value), do: nil

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _parse_error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp maybe_apply_approval_policy(row, nil), do: row

  defp maybe_apply_approval_policy(row, approval_policy) do
    requirement = link_capacity_approval_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "link_capacity", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp maybe_apply_invalid_input_approval_policy(row, nil), do: row

  defp maybe_apply_invalid_input_approval_policy(row, approval_policy) do
    requirement = invalid_input_approval_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "link_capacity_invalid_input", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp invalid_input_approval_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => "link_capacity",
      "action" => "review_invalid_link_capacity_input",
      "requirement_type" => "contact_schedule_change",
      "reason" =>
        "link-capacity #{row["input_role"] || "contact"} input requires review: #{row["invalid_contact_input_reason"]}",
      "activity_context" =>
        %{
          "contact_id" => row["contact_id"],
          "contact_ids" => row["contact_ids"],
          "input_role" => row["input_role"],
          "direction" => row["direction"],
          "ground_station_id" => row["ground_station_id"],
          "starts_at_s" => row["starts_at_s"],
          "ends_at_s" => row["ends_at_s"],
          "required_operator_action" => row["required_operator_action"],
          "invalid_contact_input" => row["invalid_contact_input"],
          "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
          "source_contact_candidate" => row["source_contact_candidate"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp link_capacity_approval_requirement(row) do
    %{
      "activity_id" => "link_capacity:#{row["ground_station_id"]}",
      "activity_type" => "link_capacity_summary",
      "action" => "review_link_capacity_summary",
      "requirement_type" => "contact_schedule_change",
      "reason" => "review #{row["ground_station_id"]} downlink capacity summary",
      "activity_context" =>
        %{
          "ground_station_id" => row["ground_station_id"],
          "station_availability" => station_availability(row),
          "station_calendar_entry_ids" => row["station_calendar_entry_ids"],
          "station_calendar_provider_ids" => row["station_calendar_provider_ids"],
          "station_calendar_provider_entry_ids" => row["station_calendar_provider_entry_ids"],
          "station_calendar_directions" => row["station_calendar_directions"],
          "station_reservation_ids" => row["station_reservation_ids"],
          "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
          "station_reserved_bys" => row["station_reserved_bys"],
          "station_reservation_statuses" => row["station_reservation_statuses"],
          "station_reservation_match_statuses" => row["station_reservation_match_statuses"],
          "capacity_fraction" => row["capacity_fraction_min"],
          "capacity_fraction_min" => row["capacity_fraction_min"],
          "capacity_fraction_max" => row["capacity_fraction_max"],
          "contact_count" => row["contact_count"],
          "effective_contact_count" => row["effective_contact_count"],
          "ignored_contact_count" => row["ignored_contact_count"],
          "ignored_contact_ids" => row["ignored_contact_ids"],
          "selected_contact_count" => row["selected_contact_count"],
          "ignored_selected_contact_count" => row["ignored_selected_contact_count"],
          "ignored_selected_contact_ids" => row["ignored_selected_contact_ids"],
          "contact_ids" => row["contact_ids"],
          "selected_contact_ids" => row["selected_contact_ids"],
          "duplicate_contact_ids" => row["duplicate_contact_ids"],
          "duplicate_contact_candidate_count" => row["duplicate_contact_candidate_count"],
          "ambiguous_selected_contact_ids" => row["ambiguous_selected_contact_ids"],
          "ambiguous_selected_contact_id_count" => row["ambiguous_selected_contact_id_count"],
          "estimated_throughput_mb" => row["estimated_throughput_mb"],
          "capacity_adjusted_throughput_mb" => row["capacity_adjusted_throughput_mb"],
          "selected_capacity_adjusted_throughput_mb" =>
            row["selected_capacity_adjusted_throughput_mb"],
          "unused_capacity_adjusted_throughput_mb" =>
            row["unused_capacity_adjusted_throughput_mb"],
          "selected_capacity_utilization_fraction" =>
            row["selected_capacity_utilization_fraction"],
          "selection_utilization_status" => row["selection_utilization_status"],
          "required_downlink_mb" => row["required_downlink_mb"],
          "required_downlink_contact_count" => row["required_downlink_contact_count"],
          "required_downlink_contact_ids" => row["required_downlink_contact_ids"],
          "downlink_completion_source" => row["downlink_completion_source"],
          "downlink_completion_sources" => row["downlink_completion_sources"],
          "selected_downlink_shortfall_mb" => row["selected_downlink_shortfall_mb"],
          "downlink_requirement_status" => row["downlink_requirement_status"],
          "actual_throughput_mb" => row["actual_throughput_mb"],
          "actual_throughput_contact_count" => row["actual_throughput_contact_count"],
          "actual_throughput_contact_ids" => row["actual_throughput_contact_ids"],
          "actual_completion_fraction" => row["actual_completion_fraction"],
          "actual_completion_contact_count" => row["actual_completion_contact_count"],
          "actual_completion_contact_ids" => row["actual_completion_contact_ids"],
          "actual_downlink_completion_ratio" => row["actual_downlink_completion_ratio"],
          "actual_downlink_shortfall_mb" => row["actual_downlink_shortfall_mb"],
          "actual_downlink_requirement_status" => row["actual_downlink_requirement_status"],
          "contact_success" => row["contact_success"],
          "contact_result" => row["contact_result"],
          "contact_success_factor" => row["contact_success_factor"],
          "contact_success_factor_source" => row["contact_success_factor_source"],
          "command_success" => row["command_success"],
          "command_result" => row["command_result"],
          "command_success_factor" => row["command_success_factor"],
          "command_success_factor_source" => row["command_success_factor_source"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp station_availability(contacts) when is_list(contacts) do
    contacts
    |> Enum.map(&contact_station_availability/1)
    |> Enum.reject(&is_nil/1)
    |> highest_station_availability()
  end

  defp station_availability(%{} = row) do
    availability =
      row
      |> station_availability_candidates()
      |> Enum.map(&normalized_status_token/1)
      |> Enum.filter(&station_availability_value?/1)
      |> highest_station_availability()

    cond do
      availability in ["unavailable", "maintenance"] ->
        "unavailable"

      availability == "reserved" ->
        "reserved"

      availability == "reduced_capacity" ->
        "reduced_capacity"

      is_number(row["capacity_fraction_min"]) and row["capacity_fraction_min"] < 1.0 ->
        "reduced_capacity"

      true ->
        nil
    end
  end

  defp station_availability(_row), do: nil

  defp contact_station_availability(contact) do
    availability =
      contact
      |> station_availability_candidates()
      |> Enum.filter(&station_availability_value?/1)
      |> highest_station_availability()

    cond do
      availability in ["unavailable", "maintenance" | @unavailable_aliases] -> "unavailable"
      availability == "reserved" -> "reserved"
      availability == "reduced_capacity" -> "reduced_capacity"
      capacity_fraction_value(contact) < 1.0 -> "reduced_capacity"
      true -> nil
    end
  end

  defp station_availability_candidates(contact) do
    [
      contact["station_availability"],
      contact["availability"],
      contact["station_calendar_status"],
      contact["status"]
    ] ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_entry"]) ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_overlaps"])
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

  defp contact_id(contact) do
    case contact_id_or_nil(contact) do
      value when is_binary(value) and value != "" -> value
      _value -> raise ArgumentError, "contact id is required"
    end
  end

  defp contact_id_or_nil(contact) do
    case Map.get(contact, "id") || Map.get(contact, "contact_id") ||
           Map.get(contact, "activity_id") do
      value when is_binary(value) and value != "" -> stable_id_or_nil(value)
      value when is_atom(value) and not is_nil(value) -> stable_id_or_nil(value)
      value when is_integer(value) -> stable_id_or_nil(value)
      _value -> nil
    end
  end

  defp contact_ground_station_id(contact), do: stable_id_or_nil(contact["ground_station_id"])

  defp invalid_contact_row_id("invalid_contact_shape", index), do: "missing_contact_id:#{index}"
  defp invalid_contact_row_id(reason, index), do: "#{reason}:#{index}"

  defp contact_id_issue(contact) do
    raw_id =
      Map.get(contact, "id") || Map.get(contact, "contact_id") ||
        Map.get(contact, "activity_id")

    cond do
      raw_id in [nil, ""] -> "missing_contact_id"
      stable_id?(raw_id) -> nil
      true -> "invalid_contact_id"
    end
  end

  defp contact_identity_issue(contact) do
    Enum.find_value(@contact_stable_identity_fields, fn field ->
      value = Map.get(contact, field)

      cond do
        value in [nil, ""] -> nil
        stable_id?(value) -> nil
        true -> "invalid_#{field}"
      end
    end)
  end

  defp contact_spacecraft_id(contact) do
    spacecraft_identity_value(contact["spacecraft_id"]) ||
      spacecraft_identity_value(contact["satellite_id"]) ||
      spacecraft_identity_value(contact["spacecraft"]) ||
      spacecraft_identity_value(contact["satellite"])
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: stable_id_or_nil(value)

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil("nil"), do: nil
  defp stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  defp stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(_value), do: nil

  defp normalize_contact(%{} = contact) do
    contact
    |> stringify_keys()
    |> normalize_station_id()
    |> normalize_contact_time("starts_at_s", "start_s")
    |> normalize_contact_time("ends_at_s", "end_s")
    |> normalize_station_calendar_status_fields()
    |> normalize_activity_type_alias()
    |> normalize_direction_field("direction")
    |> normalize_direction_list_field("station_calendar_directions")
    |> normalize_throughput_model()
  end

  defp normalize_contact(contact) do
    %{
      "invalid_contact_shape" => true,
      "raw_input" => inspect(contact)
    }
  end

  defp normalize_station_id(%{"ground_station_id" => station_id} = contact)
       when not is_nil(station_id),
       do: contact

  defp normalize_station_id(%{"station_id" => station_id} = contact) when not is_nil(station_id),
    do: Map.put(contact, "ground_station_id", station_id)

  defp normalize_station_id(contact) do
    case nested_station_id(contact) do
      nil -> contact
      station_id -> Map.put(contact, "ground_station_id", station_id)
    end
  end

  defp nested_station_id(contact) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(contact, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp normalize_station_calendar_status_fields(row) do
    row
    |> normalize_status_field("availability")
    |> normalize_status_field("status")
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("reservation_status")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("reservation_match_status")
    |> normalize_status_field("station_reservation_match_status")
    |> normalize_status_list_field("station_calendar_overlap_availabilities")
    |> normalize_status_list_field("station_calendar_reservation_statuses")
    |> normalize_direction_list_field("directions")
    |> normalize_direction_list_field("station_calendar_directions")
    |> normalize_source_station_calendar_field("source_station_calendar_entry")
    |> normalize_source_station_calendar_field("source_station_calendar_overlaps")
  end

  defp normalize_status_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, value} when value in [nil, ""] ->
        row

      {:ok, value} ->
        Map.put(row, field, normalized_status_token(value))

      :error ->
        row
    end
  end

  defp normalize_status_list_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, values} when is_list(values) ->
        values =
          values
          |> Enum.map(&normalized_status_token/1)
          |> Enum.reject(&(&1 in [nil, ""]))

        Map.put(row, field, values)

      {:ok, value} when value not in [nil, ""] ->
        Map.put(row, field, [normalized_status_token(value)])

      _missing_or_empty ->
        row
    end
  end

  defp normalize_source_station_calendar_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, values} when is_list(values) ->
        Map.put(row, field, Enum.map(values, &normalize_source_station_calendar/1))

      {:ok, value} ->
        Map.put(row, field, normalize_source_station_calendar(value))

      :error ->
        row
    end
  end

  defp normalize_source_station_calendar(%{} = source),
    do: normalize_station_calendar_status_fields(source)

  defp normalize_source_station_calendar(value), do: value

  defp normalize_direction_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, value} when value in [nil, ""] ->
        row

      {:ok, value} ->
        case normalized_direction_token(value) do
          nil -> row
          direction -> Map.put(row, field, direction)
        end

      :error ->
        row
    end
  end

  defp normalize_direction_list_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, values} when is_list(values) ->
        directions =
          values
          |> Enum.map(&normalized_direction_token/1)
          |> Enum.reject(&is_nil/1)

        Map.put(row, field, directions)

      {:ok, value} when value not in [nil, ""] ->
        case normalized_direction_token(value) do
          nil -> row
          direction -> Map.put(row, field, [direction])
        end

      _missing_or_empty ->
        row
    end
  end

  defp normalized_status_token(nil), do: nil

  defp normalized_status_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> canonical_status_token()
  end

  defp normalized_status_token(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalized_status_token()
  end

  defp normalized_status_token(value), do: value

  defp canonical_status_token(value) when value in @unavailable_aliases, do: "unavailable"
  defp canonical_status_token(value), do: value

  defp normalized_direction_token(value) when value in [nil, ""], do: nil

  defp normalized_direction_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "uplink" -> "uplink"
      "downlink" -> "downlink"
      "tracking" -> "tracking"
      "health_check" -> "health_check"
      "nil" -> nil
      "" -> nil
      direction -> Map.get(@provider_direction_aliases, direction, direction)
    end
  end

  defp normalize_contact_time(contact, canonical_key, alternate_key) do
    case numeric_value(Map.get(contact, canonical_key)) ||
           numeric_value(Map.get(contact, alternate_key)) do
      value when is_number(value) -> Map.put(contact, canonical_key, value)
      _value -> contact
    end
  end

  defp normalize_activity_type_alias(%{"type" => type} = contact) when not is_nil(type),
    do: contact

  defp normalize_activity_type_alias(%{"activity_type" => type} = contact)
       when is_binary(type) and type != "",
       do: Map.put(contact, "type", type)

  defp normalize_activity_type_alias(contact), do: contact

  defp normalize_throughput_model(contact) do
    case Map.get(contact, "throughput_model") do
      %{} = model -> Map.put(contact, "throughput_model", stringify_keys(model))
      _model -> contact
    end
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
