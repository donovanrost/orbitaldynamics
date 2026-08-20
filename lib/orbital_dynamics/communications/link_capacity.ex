defmodule OrbitalDynamics.Communications.LinkCapacity do
  @moduledoc """
  Artifact-only downlink capacity summaries with a fixed-rate default.

  The module groups downlink contact candidates by ground station, totals raw
  and station-capacity-adjusted throughput, and marks which contacts were
  selected. A contact may opt into a separately schema-validated deterministic
  point link budget; otherwise every fixed-rate lookup remains unchanged. The
  module does not reserve station time or mutate schedules.
  """

  @schema_contract "link_capacity_report.v1"
  @summary_schema_contract "link_capacity_summary.v1"
  @required_downlink_policy_paths [
    ["required_downlink_mb"],
    ["required_downlink_mb_by_ground_station"]
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
  alias OrbitalDynamics.Policy
  alias OrbitalDynamics.Communications.LinkCapacity.ContactFeedback
  alias OrbitalDynamics.Communications.LinkCapacity.ContactIdentity
  alias OrbitalDynamics.Communications.LinkCapacity.ContactNormalization
  alias OrbitalDynamics.Communications.LinkCapacity.DownlinkRequirement
  alias OrbitalDynamics.Communications.LinkCapacity.RelayDataPath
  alias OrbitalDynamics.Communications.LinkCapacity.StationCapacity
  alias OrbitalDynamics.Communications.LinkCapacity.StationAvailability
  alias OrbitalDynamics.Communications.LinkCapacity.StationReservationEvidence
  alias OrbitalDynamics.Communications.LinkCapacity.Summary
  alias OrbitalDynamics.Communications.LinkCapacity.ThroughputEvidence
  alias OrbitalDynamics.Communications.DownlinkLinkBudget

  @doc """
  Declares the fixed-rate link-capacity summary model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      summary_artifact_contract: @summary_schema_contract,
      relay_data_path_summary_artifact_contract: RelayDataPath.schema_contract(),
      downlink_link_budget_artifact_contract: DownlinkLinkBudget.schema_contract(),
      opt_in_link_budget_model: :deterministic_point_one_way_downlink_budget,
      model: :fixed_rate_downlink_capacity_summary,
      validation_level: :artifact_contract,
      station_unavailable_aliases: station_unavailable_aliases(),
      station_availability_precedence: station_availability_precedence(),
      station_capacity_fraction_paths: StationCapacity.fraction_paths(),
      station_capacity_percent_paths: StationCapacity.percent_paths(),
      station_capacity_value_paths: StationCapacity.value_path_metadata(),
      source_station_capacity_fraction_paths: StationCapacity.fraction_paths(),
      source_station_capacity_percent_paths: StationCapacity.percent_paths(),
      source_station_capacity_value_paths: StationCapacity.value_path_metadata(),
      required_downlink_policy_paths: @required_downlink_policy_paths,
      contact_required_downlink_paths: DownlinkRequirement.contact_paths(),
      downlink_completion_source_paths: DownlinkRequirement.source_paths(),
      downlink_completion_sources_paths: DownlinkRequirement.sources_paths(),
      actual_throughput_fields: @actual_throughput_fields,
      actual_throughput_model_paths: @actual_throughput_model_paths,
      actual_data_rate_fields: @actual_data_rate_fields,
      actual_duration_fields: @actual_duration_fields,
      actual_completion_fraction_paths: @actual_completion_fraction_paths,
      provider_direction_aliases: @provider_direction_aliases,
      provider_result_map_value_keys: ContactFeedback.provider_result_map_value_keys(),
      contact_stable_identity_fields: ContactIdentity.stable_fields(),
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
      relay_data_path_statuses: RelayDataPath.statuses(),
      relay_data_path_model_limits: RelayDataPath.model_limits(),
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
        :downlink_link_budget,
        :link_capacity_report,
        :link_capacity_summary,
        :relay_data_path_summary
      ]
    }
  end

  defp capacity_value_path_assumptions, do: StationCapacity.assumptions()

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
    downlink_link_budgets = link_budget_evidence(candidates ++ selected_contacts)

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
        |> Map.merge(link_budget_station_context(station_contacts ++ station_selected_downlinks))
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
      "assumptions" =>
        %{
          "downlink_rate_mb_s" => Map.get(policy, "downlink_rate_mb_s", 1.0),
          "throughput_model" => "fixed_rate_from_campaign_policy",
          "capacity_adjusted_throughput_model" =>
            "estimated_throughput_mb_times_declared_station_capacity_fraction",
          "station_unavailable_aliases" => station_unavailable_aliases(),
          "station_availability_precedence" => station_availability_precedence(),
          "station_capacity_value_paths" => capacity_value_path_assumptions(),
          "source_station_capacity_value_paths" => capacity_value_path_assumptions(),
          "provider_direction_aliases" => @provider_direction_aliases,
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
        |> Map.merge(link_budget_assumptions(downlink_link_budgets))
    }
    |> Map.merge(link_budget_report_context(downlink_link_budgets))
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

  def relay_data_path_summary(routes, opts), do: RelayDataPath.summary(routes, opts)

  @doc "Builds one opt-in deterministic point downlink budget."
  def downlink_link_budget(contact, params), do: DownlinkLinkBudget.build(contact, params)

  defp link_capacity_summary(report) do
    Summary.build(report, %{
      model_limits: model_limits(),
      station_unavailable_aliases: station_unavailable_aliases(),
      station_availability_precedence: station_availability_precedence(),
      capacity_value_path_assumptions: capacity_value_path_assumptions(),
      provider_direction_aliases: @provider_direction_aliases
    })
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp link_budget_evidence(contacts) do
    budgets =
      contacts
      |> Enum.map(&DownlinkLinkBudget.evidence_for_contact/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq_by(& &1["id"])
      |> Enum.sort_by(&{&1["contact_binding"]["contact_id"], &1["id"]})

    budgets
    |> Enum.group_by(& &1["contact_binding"]["contact_id"])
    |> Enum.each(fn {contact_id, contact_budgets} ->
      if length(contact_budgets) > 1 do
        raise ArgumentError,
              "multiple downlink_link_budget revisions supplied for contact #{contact_id}"
      end
    end)

    budgets
  end

  defp link_budget_report_context([]), do: %{}

  defp link_budget_report_context(budgets) do
    %{
      "downlink_link_budget_count" => length(budgets),
      "downlink_link_budget_ids" => Enum.map(budgets, & &1["id"]),
      "downlink_link_budgets" => budgets
    }
  end

  defp link_budget_station_context(contacts) do
    budgets = link_budget_evidence(contacts)

    case budgets do
      [] ->
        %{}

      budgets ->
        %{
          "downlink_link_budget_count" => length(budgets),
          "downlink_link_budget_ids" => Enum.map(budgets, & &1["id"])
        }
    end
  end

  defp link_budget_assumptions([]), do: %{}

  defp link_budget_assumptions(_budgets) do
    %{
      "link_budget_model" =>
        "opt_in_downlink_link_budget.v1_supported_volume_overrides_fixed_rate_estimate_when_supplied"
    }
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

  defp contact_feedback_context(contacts), do: ContactFeedback.context(contacts)

  defp contact_value(contact, key), do: ContactFeedback.value(contact, key)

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

  defp station_reservation_ids(contacts), do: StationReservationEvidence.ids(contacts)

  defp station_reservation_expires_at_s(contacts),
    do: StationReservationEvidence.expires_at_s(contacts)

  defp station_reserved_bys(contacts), do: StationReservationEvidence.reserved_bys(contacts)

  defp station_reservation_statuses(contacts),
    do: StationReservationEvidence.statuses(contacts)

  defp station_reservation_match_statuses(contacts),
    do: StationReservationEvidence.match_statuses(contacts)

  defp normalized_string_values(values),
    do: StationReservationEvidence.normalized_string_values(values)

  defp normalized_number_values(values),
    do: StationReservationEvidence.normalized_number_values(values)

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

  defp contact_capacity_fraction(contact),
    do: ThroughputEvidence.contact_capacity_fraction(contact)

  defp total_estimated_throughput(contacts),
    do: ThroughputEvidence.total_estimated_throughput(contacts)

  defp total_capacity_adjusted_throughput(contacts),
    do: ThroughputEvidence.total_capacity_adjusted_throughput(contacts)

  defp actual_throughput_resolution(selected_downlinks, contact_id_counts),
    do: ThroughputEvidence.actual_throughput_resolution(selected_downlinks, contact_id_counts)

  defp actual_completion_resolution(selected_downlinks, contact_id_counts),
    do: ThroughputEvidence.actual_completion_resolution(selected_downlinks, contact_id_counts)

  defp unresolved_selected_contact_ids(
         selected_downlinks,
         unresolved_ids,
         ground_station_id,
         fun
       ),
       do:
         ThroughputEvidence.unresolved_selected_contact_ids(
           selected_downlinks,
           unresolved_ids,
           ground_station_id,
           fun
         )

  defp actual_throughput_evidence?(contact),
    do: ThroughputEvidence.actual_throughput_evidence?(contact)

  defp actual_completion_evidence?(contact),
    do: ThroughputEvidence.actual_completion_evidence?(contact)

  defp optional_contact_count(ids),
    do: ThroughputEvidence.optional_contact_count(ids)

  defp optional_contact_ids(ids),
    do: ThroughputEvidence.optional_contact_ids(ids)

  defp actual_throughput_mb(contacts),
    do: ThroughputEvidence.actual_throughput_mb(contacts)

  defp actual_data_rate_throughput_derivations(contacts),
    do: ThroughputEvidence.actual_data_rate_throughput_derivations(contacts)

  defp actual_completion_fraction(contacts),
    do: ThroughputEvidence.actual_completion_fraction(contacts)

  defp estimated_throughput_value(contact),
    do: ThroughputEvidence.estimated_throughput_value(contact)

  defp actual_throughput_value(contact),
    do: ThroughputEvidence.actual_throughput_value(contact)

  defp actual_throughput_model_value(contact),
    do: ThroughputEvidence.actual_throughput_model_value(contact)

  defp completed_fraction_value(contact),
    do: ThroughputEvidence.completed_fraction_value(contact)

  defp completed_fraction_values(contact),
    do: ThroughputEvidence.completed_fraction_values(contact)

  defp actual_throughput_contact_ids(contacts),
    do: ThroughputEvidence.actual_throughput_contact_ids(contacts)

  defp actual_completion_contact_ids(contacts),
    do: ThroughputEvidence.actual_completion_contact_ids(contacts)

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

  defp report_required_downlink_mb(policy, contacts),
    do: DownlinkRequirement.report_required_mb(policy, contacts)

  defp station_required_downlink_mb(ground_station_id, policy, contacts),
    do: DownlinkRequirement.station_required_mb(ground_station_id, policy, contacts)

  defp invalid_policy_required_downlink_station_ids(policy),
    do: DownlinkRequirement.invalid_policy_station_ids(policy)

  defp required_downlink_contact_ids(contacts),
    do: DownlinkRequirement.required_contact_ids(contacts)

  defp policy_station_required_downlink_values(policy),
    do: DownlinkRequirement.policy_station_values(policy)

  defp downlink_completion_source(policy, contacts),
    do: DownlinkRequirement.completion_source(policy, contacts)

  defp downlink_completion_source(ground_station_id, policy, contacts),
    do: DownlinkRequirement.completion_source(ground_station_id, policy, contacts)

  defp downlink_completion_sources(policy, contacts),
    do: DownlinkRequirement.completion_sources(policy, contacts)

  defp downlink_completion_sources(ground_station_id, policy, contacts),
    do: DownlinkRequirement.completion_sources(ground_station_id, policy, contacts)

  defp empty_map_to_nil(map) when map == %{}, do: nil
  defp empty_map_to_nil(map), do: map
  defp empty_list_to_nil([]), do: nil
  defp empty_list_to_nil(values), do: values

  defp selected_downlink_shortfall_mb(required_downlink_mb, selected_capacity_adjusted),
    do:
      DownlinkRequirement.selected_shortfall_mb(required_downlink_mb, selected_capacity_adjusted)

  defp downlink_requirement_status(required_downlink_mb, selected_capacity_adjusted),
    do: DownlinkRequirement.status(required_downlink_mb, selected_capacity_adjusted)

  defp actual_downlink_shortfall_mb(required_downlink_mb, actual_throughput_mb),
    do: DownlinkRequirement.actual_shortfall_mb(required_downlink_mb, actual_throughput_mb)

  defp actual_downlink_completion_ratio(required_downlink_mb, actual_throughput_mb),
    do: DownlinkRequirement.actual_completion_ratio(required_downlink_mb, actual_throughput_mb)

  defp actual_downlink_requirement_status(required_downlink_mb, actual_throughput_mb),
    do: DownlinkRequirement.actual_status(required_downlink_mb, actual_throughput_mb)

  defp numeric_value(value), do: ContactNormalization.numeric_value(value)

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

  defp station_availability(value), do: StationAvailability.value(value)

  defp station_unavailable_aliases, do: StationAvailability.unavailable_aliases()

  defp station_availability_precedence, do: StationAvailability.precedence()

  defp contact_id(contact), do: ContactIdentity.contact_id!(contact)

  defp contact_id_or_nil(contact), do: ContactIdentity.contact_id_or_nil(contact)

  defp contact_ground_station_id(contact), do: ContactIdentity.ground_station_id(contact)

  defp invalid_contact_row_id("invalid_contact_shape", index), do: "missing_contact_id:#{index}"
  defp invalid_contact_row_id(reason, index), do: "#{reason}:#{index}"

  defp contact_id_issue(contact), do: ContactIdentity.contact_id_issue(contact)

  defp contact_identity_issue(contact), do: ContactIdentity.contact_identity_issue(contact)

  defp contact_spacecraft_id(contact), do: ContactIdentity.spacecraft_id(contact)

  defp stable_id_or_nil(value), do: ContactIdentity.stable_id_or_nil(value)

  defp normalize_contact(contact) do
    ContactNormalization.normalize(
      contact,
      station_unavailable_aliases(),
      @provider_direction_aliases
    )
  end

  defp normalized_direction_token(value) do
    ContactNormalization.normalized_direction_token(value, @provider_direction_aliases)
  end

  defp stringify_keys(value), do: ContactNormalization.stringify_keys(value)
  defp compact_map(map), do: ContactNormalization.compact_map(map)
end
