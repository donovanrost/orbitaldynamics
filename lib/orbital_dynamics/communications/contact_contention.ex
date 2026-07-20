defmodule OrbitalDynamics.Communications.ContactContention do
  @moduledoc """
  Artifact-only contact-resource contention reports.

  The module detects overlapping contact windows for the same ground station
  and for the same spacecraft across multiple stations, annotates affected
  contacts, and emits deterministic advisory resolution recommendations. It
  does not reserve station time, suppress candidates, or mutate external
  schedules.
  """

  @contention_contract "contact_contention_report.v1"
  @resolution_contract "contact_contention_resolution_report.v1"
  @resolution_summary_contract "contact_contention_resolution_summary.v1"
  @contact_types ~w(downlink planned_contact tracking command health_check)
  @contact_directions ~w(downlink uplink command tracking health_check)
  @command_contact_directions ~w(command uplink)
  @station_reservation_priority_match_statuses ~w(matched owned owner_matched)
  @station_reservation_priority_statuses ~w(approved confirmed reserved held)
  @resolution_selection_rules ~w(
    highest_score_earliest_start
    earliest_start_highest_score
    highest_priority_highest_score
    highest_priority_earliest_start
  )
  @resolution_tie_breakers ~w(
    starts_at_s
    ends_at_s
    score
    priority
    policy_contact_priority
    command_contact_priority
    station_reservation_priority
    id
    contact_id
  )
  @default_resolution_priority_fields ~w(
    contention_priority
    contact_priority
    activity_priority
    target_priority
    priority
    station_reservation_priority
    command_contact_priority
  )
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
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  alias OrbitalDynamics.Communications.ContactContention.{
    ApprovalPolicy,
    CapacityDemand,
    ContactNormalization,
    ContactIdentity,
    FeedbackContext,
    PriorityOverrides,
    ResolutionSummary,
    StationCalendarContext,
    TimingMetrics
  }

  @doc """
  Declares the contact contention model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @contention_contract,
      resolution_artifact_contract: @resolution_contract,
      resolution_summary_artifact_contract: @resolution_summary_contract,
      model: :single_station_interval_overlap,
      validation_level: :artifact_contract,
      contact_types: @contact_types,
      contact_directions: @contact_directions,
      row_review_statuses: ["operator_review_required"],
      station_unavailable_aliases: StationCalendarContext.unavailable_aliases(),
      station_availability_precedence: StationCalendarContext.availability_precedence(),
      station_capacity_fraction_paths: StationCalendarContext.capacity_fraction_paths(),
      station_capacity_percent_paths: StationCalendarContext.capacity_percent_paths(),
      station_capacity_value_paths: StationCalendarContext.capacity_value_path_metadata(),
      source_station_capacity_fraction_paths: StationCalendarContext.capacity_fraction_paths(),
      source_station_capacity_percent_paths: StationCalendarContext.capacity_percent_paths(),
      source_station_capacity_value_paths: StationCalendarContext.capacity_value_path_metadata(),
      required_capacity_fraction_paths: CapacityDemand.required_capacity_fraction_paths(),
      required_capacity_percent_paths: CapacityDemand.required_capacity_percent_paths(),
      required_capacity_value_paths:
        capacity_value_path_metadata(CapacityDemand.required_capacity_value_paths()),
      required_capacity_fraction_source_values:
        CapacityDemand.required_capacity_fraction_source_values(),
      station_reservation_priority_match_statuses: @station_reservation_priority_match_statuses,
      station_reservation_priority_statuses: @station_reservation_priority_statuses,
      resolution_selection_rules: @resolution_selection_rules,
      resolution_tie_breakers: @resolution_tie_breakers,
      default_resolution_priority_fields: @default_resolution_priority_fields,
      resolution_priority_override_aliases: PriorityOverrides.aliases(),
      provider_direction_aliases: @provider_direction_aliases,
      provider_result_map_value_keys: @provider_result_map_value_keys,
      contact_stable_identity_fields: ContactIdentity.stable_identity_fields(),
      command_contact_directions: @command_contact_directions,
      public_facades: [
        :annotate_contact_contention,
        :contact_contention_report,
        :contact_contention_resolution_report,
        :contact_contention_resolution_summary
      ],
      row_semantics: [
        :invalid_contact_input_review,
        :same_station_overlap_group,
        :same_spacecraft_overlap_group,
        :contention_overlap_metrics,
        :schedule_conflict_annotation,
        :deterministic_resolution_recommendation,
        :priority_aware_resolution_recommendation,
        :policy_contact_priority_resolution,
        :command_contact_priority_resolution,
        :station_reservation_priority_resolution,
        :realized_data_rate_throughput_preservation,
        :actual_data_rate_throughput_derivation_evidence,
        :numeric_string_time_normalization,
        :station_calendar_provider_context,
        :station_calendar_availability_status_normalization,
        :station_calendar_capacity_fraction_context,
        :station_calendar_capacity_percent_aliases,
        :station_capacity_value_paths,
        :source_station_capacity_value_paths,
        :required_capacity_value_paths,
        :required_capacity_fraction_source_values,
        :station_calendar_direction_context,
        :contact_stable_identity_fields,
        :command_contact_directions,
        :provider_direction_aliases,
        :provider_result_map_value_keys,
        :contact_contention_resolution_summary,
        :contact_contention_resolution_conflict_group_count,
        :contact_contention_resolution_recommendation_count,
        :contact_contention_resolution_review_recommendation_count,
        :contact_contention_resolution_capacity_pack_demand_summary,
        :contact_contention_resolution_capacity_pack_status_routing,
        :contact_contention_resolution_capacity_pack_source_routing,
        :contact_contention_resolution_resource_scope_counts,
        :contact_contention_resolution_resource_scope_routing,
        :contact_contention_resolution_selection_reason_counts,
        :contact_contention_resolution_selection_reason_routing,
        :contact_contention_resolution_action_counts,
        :contact_contention_resolution_action_routing,
        :contact_contention_resolution_group_routing,
        :contact_contention_resolution_routing_id_sets,
        :contact_contention_resolution_summary_row_derived_counts,
        :operator_review_required
      ],
      known_limits: [
        :artifact_level_only,
        :no_provider_reservation,
        :no_candidate_suppression,
        :no_schedule_mutation,
        :no_link_budget_model
      ]
    }
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  defp capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp capability_assumptions do
    capabilities = capabilities()

    %{
      "contact_types" => capabilities.contact_types,
      "contact_directions" => capabilities.contact_directions,
      "row_review_statuses" => capabilities.row_review_statuses,
      "station_unavailable_aliases" => capabilities.station_unavailable_aliases,
      "station_availability_precedence" => capabilities.station_availability_precedence,
      "station_capacity_value_paths" =>
        capacity_value_path_assumptions(capabilities.station_capacity_value_paths),
      "source_station_capacity_value_paths" =>
        capacity_value_path_assumptions(capabilities.source_station_capacity_value_paths),
      "required_capacity_value_paths" =>
        capacity_value_path_assumptions(capabilities.required_capacity_value_paths),
      "required_capacity_fraction_source_values" =>
        capabilities.required_capacity_fraction_source_values,
      "station_reservation_priority_match_statuses" =>
        capabilities.station_reservation_priority_match_statuses,
      "station_reservation_priority_statuses" =>
        capabilities.station_reservation_priority_statuses,
      "resolution_selection_rules" => capabilities.resolution_selection_rules,
      "resolution_tie_breakers" => capabilities.resolution_tie_breakers,
      "default_resolution_priority_fields" => capabilities.default_resolution_priority_fields,
      "resolution_priority_override_aliases" => capabilities.resolution_priority_override_aliases,
      "provider_direction_aliases" => capabilities.provider_direction_aliases,
      "provider_result_map_value_keys" => capabilities.provider_result_map_value_keys,
      "contact_stable_identity_fields" => capabilities.contact_stable_identity_fields,
      "command_contact_directions" => capabilities.command_contact_directions
    }
  end

  @doc """
  Annotates contact candidates and returns `{annotated_contacts, report}`.
  """
  def annotate_contacts(contacts, opts \\ [])

  def annotate_contacts(contacts, opts) when is_list(contacts) do
    contacts = Enum.map(contacts, &normalize_contact/1)

    contact_inputs = Enum.filter(contacts, &contact_like_input?/1)

    {invalid_contact_inputs, valid_contacts} =
      contact_inputs
      |> Enum.with_index(1)
      |> Enum.split_with(fn {contact, _index} -> invalid_contact_input?(contact) end)

    valid_contacts = Enum.map(valid_contacts, fn {contact, _index} -> contact end)
    groups = contact_contention_groups(valid_contacts)

    group_ids_by_contact_id =
      groups
      |> Enum.flat_map(fn group ->
        Enum.map(group["contact_ids"], &{&1, group["id"]})
      end)
      |> Enum.group_by(fn {contact_id, _group_id} -> contact_id end, fn {_contact_id, group_id} ->
        group_id
      end)
      |> Map.new(fn {contact_id, group_ids} -> {contact_id, Enum.uniq(group_ids)} end)

    annotated =
      Enum.map(contacts, fn contact ->
        contact_id = contact_id_or_nil(contact)

        case Map.get(group_ids_by_contact_id, contact_id) do
          nil ->
            contact

          group_ids ->
            contact
            |> Map.put("schedule_conflict_status", "contention_detected")
            |> Map.put("contention_group_ids", Enum.sort(group_ids))
        end
      end)

    {annotated, contention_report(contact_inputs, groups, invalid_contact_inputs, opts)}
  end

  def annotate_contacts(_contacts, _opts),
    do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a standalone `contact_contention_report.v1`.
  """
  def report(contact_contention_report)

  def report(%{"schema_contract" => @contention_contract} = report) do
    report
  end

  def report(%{schema_contract: @contention_contract} = report) do
    stringify_keys(report)
  end

  def report(contacts) when is_list(contacts) do
    report(contacts, [])
  end

  def report(_contact_contention_report),
    do:
      raise(
        ArgumentError,
        "contact contention report must be a contact_contention_report.v1 map or contacts must be a list"
      )

  def report(contacts, opts) when is_list(contacts) do
    {_annotated, report} = annotate_contacts(contacts, opts)
    report
  end

  def report(_contacts, _opts), do: raise(ArgumentError, "contacts must be a list")

  @doc """
  Builds a deterministic advisory resolution report for contention groups.
  """
  def resolution_report(contact_contention_resolution_report)

  def resolution_report(%{"schema_contract" => @resolution_contract} = report) do
    report
  end

  def resolution_report(%{schema_contract: @resolution_contract} = report) do
    stringify_keys(report)
  end

  def resolution_report(_contact_contention_resolution_report),
    do:
      raise(
        ArgumentError,
        "contact contention resolution report must be a contact_contention_resolution_report.v1 map"
      )

  def resolution_report(contacts, contention_report, opts \\ [])

  def resolution_report(contacts, contention_report, opts)
      when is_list(contacts) and is_map(contention_report) do
    contacts = Enum.map(contacts, &normalize_contact/1)
    report = stringify_keys(contention_report)
    groups = Map.get(report, "conflict_groups", [])
    policy = resolution_policy(opts)
    approval_policy = Keyword.get(opts, :approval_policy)

    recommendations =
      groups
      |> Enum.map(&contact_contention_recommendation(&1, contacts, policy))
      |> Enum.map(&ApprovalPolicy.apply_recommendation(&1, approval_policy))
      |> Enum.sort_by(
        &{
          &1["resource_scope"] || "ground_station",
          &1["ground_station_id"],
          &1["spacecraft_id"] || "",
          &1["starts_at_s"],
          &1["group_id"]
        }
      )

    %{
      "schema_contract" => @resolution_contract,
      "model" => "deterministic_contact_contention_recommendation",
      "policy" => policy,
      "conflict_group_count" => length(groups),
      "recommendation_count" => length(recommendations),
      "recommendations" => recommendations,
      "model_limits" => model_limits(),
      "assumptions" => %{
        "boundary" => "recommendation_only_no_station_reservation",
        "candidate_mutation" => "none",
        "operator_review" => "required_for_conflicting_contacts"
      }
    }
  end

  def resolution_report(_contacts, _contention_report, _opts),
    do: raise(ArgumentError, "contacts must be a list and contention report must be a map")

  @doc """
  Builds a compact artifact-only summary for contention resolution routing.

  The summary preserves recommendation counts, policy/action counts, and the
  selected/deferred/review contact identities needed by review and import queues
  without suppressing candidates, reserving provider time, or mutating schedules.
  Existing `contact_contention_resolution_summary.v1` artifacts are accepted as
  idempotent handoff inputs.
  """
  def resolution_summary(contact_contention_resolution_report)

  def resolution_summary(%{"schema_contract" => @resolution_summary_contract} = summary),
    do: summary

  def resolution_summary(%{"schema_contract" => @resolution_contract} = report) do
    ResolutionSummary.build(report, model_limits())
  end

  def resolution_summary(%{schema_contract: @resolution_summary_contract} = summary) do
    stringify_keys(summary)
  end

  def resolution_summary(%{schema_contract: @resolution_contract} = report) do
    report
    |> stringify_keys()
    |> resolution_summary()
  end

  def resolution_summary(_contact_contention_resolution_report),
    do: raise(ArgumentError, "contact contention resolution report is required")

  def resolution_summary(contacts, contention_report, opts \\ [])

  def resolution_summary(contacts, contention_report, opts)
      when is_list(contacts) and is_map(contention_report) do
    contacts
    |> resolution_report(contention_report, opts)
    |> resolution_summary()
  end

  def resolution_summary(_contacts, _contention_report, _opts),
    do: raise(ArgumentError, "contacts must be a list and contention report must be a map")

  defp contention_report(contact_inputs, groups, invalid_contact_inputs, opts) do
    source = opts |> Keyword.get(:source, "contact_candidates") |> to_string()
    approval_policy = Keyword.get(opts, :approval_policy)

    invalid_rows =
      invalid_contact_inputs
      |> invalid_contact_rows()
      |> Enum.map(&ApprovalPolicy.apply_invalid_input(&1, approval_policy))

    groups =
      Enum.map(groups, &ApprovalPolicy.apply_group(&1, approval_policy))

    %{
      "schema_contract" => @contention_contract,
      "model" => "single_station_interval_overlap",
      "input_contact_count" => length(contact_inputs),
      "conflicted_contact_count" => conflicted_contact_count(groups),
      "duplicate_contact_id_count" => duplicate_contact_id_count(groups),
      "duplicate_contact_candidate_count" => duplicate_contact_candidate_count(groups),
      "invalid_contact_input_count" => length(invalid_rows),
      "invalid_contact_input_ids" => Enum.map(invalid_rows, & &1["contact_id"]),
      "invalid_contact_inputs" => invalid_rows,
      "conflict_group_count" => length(groups),
      "conflict_groups" => groups,
      "model_limits" => model_limits(),
      "provenance" => %{"source" => source},
      "assumptions" =>
        Map.merge(
          %{
            "resource_scope" => "ground_station_id_or_spacecraft_id",
            "contention_rule" =>
              "contacts_overlap_when_time_intervals_overlap_at_same_station_or_same_spacecraft_across_multiple_stations",
            "duplicate_contact_identity" =>
              "duplicate contact IDs are reported as ambiguous and do not receive deterministic resolution selections",
            "invalid_contact_input" =>
              "contact-like inputs missing required contention identity, station, or timing fields are blocked for operator review instead of being silently dropped",
            "resolution" => "report_only_no_candidate_suppression"
          },
          capability_assumptions()
        )
    }
  end

  defp invalid_contact_rows(invalid_contact_inputs) do
    Enum.map(invalid_contact_inputs, fn {contact, index} ->
      reason = invalid_contact_input_reason(contact)
      contact_id = contact_id_or_nil(contact) || invalid_contact_row_id(reason, index)
      scenario_id = stable_id_or_nil(contact["scenario_id"])
      spacecraft_id = contact_spacecraft_id(contact)
      ground_station_id = stable_id_or_nil(contact["ground_station_id"])

      %{
        "id" => "contact_contention:invalid_contact_input:#{contact_id}",
        "contact_id" => contact_id,
        "contact_ids" => [contact_id],
        "contact_count" => 1,
        "scenario_id" => scenario_id,
        "scenario_ids" => List.wrap(scenario_id) |> Enum.reject(&is_nil/1),
        "spacecraft_id" => spacecraft_id,
        "spacecraft_ids" => List.wrap(spacecraft_id) |> Enum.reject(&is_nil/1),
        "ground_station_id" => ground_station_id,
        "ground_station_ids" => List.wrap(ground_station_id) |> Enum.reject(&is_nil/1),
        "type" => contact["type"],
        "direction" => contact_direction(contact),
        "directions" => [contact_direction(contact)],
        "starts_at_s" => contact["starts_at_s"],
        "ends_at_s" => contact["ends_at_s"],
        "required_operator_action" => "review_invalid_contact_contention_input",
        "approval_status" => "operator_review_required",
        "review_status" => "operator_review_required",
        "operator_action_reason" => reason,
        "invalid_contact_input" => true,
        "invalid_contact_input_reason" => reason,
        "source_contact_candidate" => contact
      }
      |> compact_map()
    end)
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_contention_groups(contacts) do
    station_groups =
      contacts
      |> Enum.filter(&contact_candidate?/1)
      |> Enum.group_by(& &1["ground_station_id"])
      |> Enum.flat_map(fn {ground_station_id, station_contacts} ->
        station_contacts
        |> Enum.sort_by(&canonical_contact_sort_key/1)
        |> station_contention_groups(ground_station_id)
      end)

    spacecraft_groups =
      contacts
      |> Enum.filter(&spacecraft_contact_candidate?/1)
      |> Enum.group_by(&contact_spacecraft_id/1)
      |> Enum.flat_map(fn {spacecraft_id, spacecraft_contacts} ->
        spacecraft_contacts
        |> Enum.sort_by(&canonical_contact_sort_key/1)
        |> spacecraft_contention_groups(spacecraft_id)
      end)

    (station_groups ++ spacecraft_groups)
    |> Enum.sort_by(
      &{
        &1["resource_scope"],
        &1["ground_station_id"],
        &1["spacecraft_id"] || "",
        &1["starts_at_s"],
        &1["id"]
      }
    )
  end

  defp station_contention_groups(contacts, ground_station_id) do
    contacts
    |> interval_contention_groups()
    |> Enum.with_index(1)
    |> Enum.map(fn {group, index} ->
      station_contention_group(ground_station_id, group.contacts, index)
    end)
  end

  defp spacecraft_contention_groups(contacts, spacecraft_id) do
    contacts
    |> interval_contention_groups()
    |> Enum.reject(&(length(group_ground_station_ids(&1.contacts)) <= 1))
    |> Enum.with_index(1)
    |> Enum.map(fn {group, index} ->
      spacecraft_contention_group(spacecraft_id, group.contacts, index)
    end)
  end

  defp interval_contention_groups(contacts) do
    contacts
    |> Enum.reduce([], &add_contact_to_contention_groups/2)
    |> Enum.reverse()
    |> Enum.filter(&(length(&1.contacts) > 1))
  end

  defp add_contact_to_contention_groups(contact, []) do
    [%{latest_end_s: contact["ends_at_s"], contacts: [contact]}]
  end

  defp add_contact_to_contention_groups(contact, [current | rest]) do
    if intervals_overlap?(contact["starts_at_s"], contact["ends_at_s"], current.latest_end_s) do
      [
        %{
          current
          | latest_end_s: max(current.latest_end_s, contact["ends_at_s"]),
            contacts: [contact | current.contacts]
        }
        | rest
      ]
    else
      [%{latest_end_s: contact["ends_at_s"], contacts: [contact]}, current | rest]
    end
  end

  defp intervals_overlap?(starts_at_s, ends_at_s, latest_end_s) do
    is_number(starts_at_s) and is_number(ends_at_s) and is_number(latest_end_s) and
      starts_at_s < latest_end_s
  end

  defp station_contention_group(ground_station_id, contacts, index) do
    contacts = Enum.sort_by(contacts, &canonical_contact_sort_key/1)
    duplicate_contact_ids = duplicate_contact_ids(contacts)

    %{
      "id" =>
        ["station", ground_station_id, "contention", index]
        |> Enum.map(&encode_value/1)
        |> Enum.join(":"),
      "resource_scope" => "ground_station",
      "ground_station_id" => ground_station_id,
      "ground_station_ids" => [ground_station_id],
      "contact_count" => length(contacts),
      "starts_at_s" => contacts |> Enum.map(& &1["starts_at_s"]) |> Enum.min(),
      "ends_at_s" => contacts |> Enum.map(& &1["ends_at_s"]) |> Enum.max(),
      "direction" => group_direction(contacts),
      "directions" => group_directions(contacts),
      "required_operator_action" => "review_contact_contention",
      "approval_status" => "operator_review_required",
      "operator_action_reason" => "same_station_overlapping_contact_windows",
      "contact_ids" => Enum.map(contacts, &contact_id/1),
      "spacecraft_ids" => group_spacecraft_ids(contacts),
      "duplicate_contact_ids" => duplicate_contact_ids,
      "duplicate_contact_id_count" => length(duplicate_contact_ids),
      "duplicate_contact_candidate_count" =>
        duplicate_contact_candidate_count(contacts, duplicate_contact_ids),
      "source_contact_candidates" => contacts,
      "source_window_ids" =>
        contacts
        |> group_stable_ids("source_window_id"),
      "scenario_ids" => group_stable_ids(contacts, "scenario_id")
    }
    |> Map.merge(contention_timing_metrics(contacts))
    |> Map.merge(contact_feedback_context(contacts))
    |> Map.merge(StationCalendarContext.build(contacts))
    |> compact_map()
  end

  defp spacecraft_contention_group(spacecraft_id, contacts, index) do
    contacts = Enum.sort_by(contacts, &canonical_contact_sort_key/1)
    duplicate_contact_ids = duplicate_contact_ids(contacts)
    ground_station_ids = group_ground_station_ids(contacts)

    %{
      "id" =>
        ["spacecraft", spacecraft_id, "contention", index]
        |> Enum.map(&encode_value/1)
        |> Enum.join(":"),
      "resource_scope" => "spacecraft",
      "ground_station_id" => group_ground_station_id(ground_station_ids),
      "ground_station_ids" => ground_station_ids,
      "spacecraft_id" => spacecraft_id,
      "spacecraft_ids" => [spacecraft_id],
      "contact_count" => length(contacts),
      "starts_at_s" => contacts |> Enum.map(& &1["starts_at_s"]) |> Enum.min(),
      "ends_at_s" => contacts |> Enum.map(& &1["ends_at_s"]) |> Enum.max(),
      "direction" => group_direction(contacts),
      "directions" => group_directions(contacts),
      "required_operator_action" => "review_contact_contention",
      "approval_status" => "operator_review_required",
      "operator_action_reason" => "same_spacecraft_overlapping_contact_windows",
      "contact_ids" => Enum.map(contacts, &contact_id/1),
      "duplicate_contact_ids" => duplicate_contact_ids,
      "duplicate_contact_id_count" => length(duplicate_contact_ids),
      "duplicate_contact_candidate_count" =>
        duplicate_contact_candidate_count(contacts, duplicate_contact_ids),
      "source_contact_candidates" => contacts,
      "source_window_ids" =>
        contacts
        |> group_stable_ids("source_window_id"),
      "scenario_ids" => group_stable_ids(contacts, "scenario_id")
    }
    |> Map.merge(contention_timing_metrics(contacts))
    |> Map.merge(contact_feedback_context(contacts))
    |> Map.merge(StationCalendarContext.build(contacts))
    |> compact_map()
  end

  defp contact_contention_recommendation(group, contacts, policy) do
    group = stringify_keys(group)

    contacts =
      group
      |> recommendation_contacts(contacts)
      |> Enum.sort_by(&contention_resolution_sort_key(&1, policy))

    duplicate_contact_ids = duplicate_contact_ids(contacts)

    if duplicate_contact_ids == [] do
      deterministic_contact_contention_recommendation(group, contacts, policy)
    else
      ambiguous_contact_contention_recommendation(group, contacts, duplicate_contact_ids, policy)
    end
  end

  defp deterministic_contact_contention_recommendation(group, contacts, policy) do
    selected = List.first(contacts)
    deferred = Enum.drop(contacts, 1)

    %{
      "group_id" => group["id"],
      "resource_scope" => group["resource_scope"],
      "ground_station_id" => group["ground_station_id"],
      "ground_station_ids" => group["ground_station_ids"],
      "spacecraft_id" => group["spacecraft_id"],
      "spacecraft_ids" => group["spacecraft_ids"],
      "starts_at_s" => group["starts_at_s"],
      "ends_at_s" => group["ends_at_s"],
      "contention_window_s" => group["contention_window_s"],
      "total_contact_duration_s" => group["total_contact_duration_s"],
      "overlap_duration_s" => group["overlap_duration_s"],
      "max_concurrent_contacts" => group["max_concurrent_contacts"],
      "overlap_contact_pair_count" => group["overlap_contact_pair_count"],
      "direction" => group["direction"],
      "directions" => group["directions"],
      "selected_contact_id" => contact_id(selected),
      "selected_scenario_id" => stable_id_or_nil(selected["scenario_id"]),
      "selected_priority" => contact_priority(selected, policy),
      "selected_priority_source" => contact_priority_source(selected, policy),
      "deferred_contact_ids" => Enum.map(deferred, &contact_id/1),
      "deferred_contact_priorities" => deferred_contact_priorities(deferred, policy),
      "candidate_count" => length(contacts),
      "source_contact_candidates" => contacts,
      "selection_reason" => policy["selection_rule"],
      "action" => policy["action"],
      "review_status" => "operator_review_required"
    }
    |> Map.merge(resolution_policy_context(policy))
    |> Map.merge(priority_field_evidence_context(contacts, policy))
    |> Map.merge(contact_feedback_context(contacts))
    |> Map.merge(StationCalendarContext.build(contacts))
    |> compact_map()
  end

  defp ambiguous_contact_contention_recommendation(group, contacts, duplicate_contact_ids, policy) do
    %{
      "group_id" => group["id"],
      "resource_scope" => group["resource_scope"],
      "ground_station_id" => group["ground_station_id"],
      "ground_station_ids" => group["ground_station_ids"],
      "spacecraft_id" => group["spacecraft_id"],
      "spacecraft_ids" => group["spacecraft_ids"],
      "starts_at_s" => group["starts_at_s"],
      "ends_at_s" => group["ends_at_s"],
      "contention_window_s" => group["contention_window_s"],
      "total_contact_duration_s" => group["total_contact_duration_s"],
      "overlap_duration_s" => group["overlap_duration_s"],
      "max_concurrent_contacts" => group["max_concurrent_contacts"],
      "overlap_contact_pair_count" => group["overlap_contact_pair_count"],
      "direction" => group["direction"],
      "directions" => group["directions"],
      "deferred_contact_ids" => [],
      "candidate_count" => length(contacts),
      "selection_reason" => "duplicate_contact_id_requires_operator_review",
      "resolution_status" => "ambiguous_contact_identity",
      "resolution_issue" => "duplicate_contact_id",
      "duplicate_contact_ids" => duplicate_contact_ids,
      "duplicate_contact_id_count" => length(duplicate_contact_ids),
      "duplicate_contact_candidate_count" =>
        duplicate_contact_candidate_count(contacts, duplicate_contact_ids),
      "source_contact_candidates" => contacts,
      "duplicate_contact_candidates" =>
        Enum.filter(contacts, &(contact_id(&1) in duplicate_contact_ids)),
      "action" => "review_ambiguous_contact_contention_identity",
      "review_status" => "operator_review_required"
    }
    |> Map.merge(resolution_policy_context(policy))
    |> Map.merge(priority_field_evidence_context(contacts, policy))
    |> Map.merge(contact_feedback_context(contacts))
    |> Map.merge(StationCalendarContext.build(contacts))
    |> compact_map()
  end

  defp resolution_policy_context(policy) do
    %{
      "resolution_selection_rule" => policy["selection_rule"],
      "resolution_priority_fields" => policy["priority_fields"],
      "requested_priority_fields" => policy["requested_priority_fields"],
      "resolution_priority_override_count" => policy["priority_override_count"],
      "resolution_priority_override_contact_ids" => policy["priority_override_contact_ids"],
      "ignored_priority_override_count" => policy["ignored_priority_override_count"],
      "ignored_priority_override_keys" => policy["ignored_priority_override_keys"],
      "ignored_priority_override_contact_ids" => policy["ignored_priority_override_contact_ids"],
      "ignored_priority_override_input" => policy["ignored_priority_override_input"],
      "resolution_tie_breakers" => policy["tie_breakers"],
      "requested_selection_rule" => policy["requested_selection_rule"],
      "ignored_tie_breakers" => policy["ignored_tie_breakers"],
      "ignored_policy_input" => policy["ignored_policy_input"],
      "policy_warnings" => policy["policy_warnings"]
    }
    |> compact_map()
  end

  defp priority_field_evidence_context(
         contacts,
         %{"requested_priority_fields" => fields} = policy
       )
       when is_list(fields) and fields != [] do
    evidence_counts =
      Map.new(fields, fn field ->
        count =
          Enum.count(contacts, fn contact ->
            not is_nil(numeric_or_nil(priority_field_value(contact, policy, field)))
          end)

        {field, count}
      end)

    fields_without_evidence =
      evidence_counts
      |> Enum.filter(fn {_field, count} -> count == 0 end)
      |> Enum.map(fn {field, _count} -> field end)

    %{
      "priority_field_evidence_counts" => evidence_counts,
      "priority_fields_without_numeric_evidence_count" => length(fields_without_evidence),
      "priority_fields_without_numeric_evidence" =>
        if(fields_without_evidence == [], do: nil, else: fields_without_evidence)
    }
    |> compact_map()
  end

  defp priority_field_evidence_context(_contacts, _policy), do: %{}

  defp recommendation_contacts(%{"source_contact_candidates" => contacts}, _all_contacts)
       when is_list(contacts),
       do: Enum.map(contacts, &stringify_keys/1)

  defp recommendation_contacts(group, contacts) do
    Enum.filter(contacts, &(contact_id(&1) in group["contact_ids"]))
  end

  defp conflicted_contact_count(groups) do
    groups
    |> Enum.map(&Map.get(&1, "contact_count", 0))
    |> Enum.sum()
  end

  defp duplicate_contact_id_count(groups) do
    groups
    |> Enum.flat_map(&Map.get(&1, "duplicate_contact_ids", []))
    |> Enum.uniq()
    |> length()
  end

  defp duplicate_contact_candidate_count(groups) do
    groups
    |> Enum.map(&Map.get(&1, "duplicate_contact_candidate_count", 0))
    |> Enum.sum()
  end

  defp duplicate_contact_ids(contacts) do
    contacts
    |> Enum.group_by(&contact_id/1)
    |> Enum.filter(fn {_contact_id, grouped_contacts} -> length(grouped_contacts) > 1 end)
    |> Enum.map(fn {contact_id, _grouped_contacts} -> contact_id end)
    |> Enum.sort()
  end

  defp duplicate_contact_candidate_count(contacts, duplicate_contact_ids) do
    Enum.count(contacts, &(contact_id(&1) in duplicate_contact_ids))
  end

  defp contention_timing_metrics(contacts), do: TimingMetrics.build(contacts)

  defp contact_feedback_context(contacts) do
    FeedbackContext.build(contacts, @provider_result_map_value_keys, &contact_id/1)
  end

  defp contention_resolution_sort_key(
         contact,
         %{
           "selection_rule" => "earliest_start_highest_score"
         } = policy
       ) do
    [contact["starts_at_s"], -numeric_or_zero(contact["score"])] ++
      tie_breaker_sort_key(contact, policy) ++ [canonical_contact_sort_key(contact)]
  end

  defp contention_resolution_sort_key(
         contact,
         %{
           "selection_rule" => "highest_priority_highest_score"
         } = policy
       ) do
    [-numeric_or_zero(contact_priority(contact, policy)), -numeric_or_zero(contact["score"])] ++
      tie_breaker_sort_key(contact, policy) ++ [canonical_contact_sort_key(contact)]
  end

  defp contention_resolution_sort_key(
         contact,
         %{
           "selection_rule" => "highest_priority_earliest_start"
         } = policy
       ) do
    [
      -numeric_or_zero(contact_priority(contact, policy)),
      contact["starts_at_s"],
      -numeric_or_zero(contact["score"])
    ] ++
      tie_breaker_sort_key(contact, policy) ++ [canonical_contact_sort_key(contact)]
  end

  defp contention_resolution_sort_key(contact, policy) do
    [-numeric_or_zero(contact["score"])] ++
      tie_breaker_sort_key(contact, policy) ++ [canonical_contact_sort_key(contact)]
  end

  defp resolution_policy(opts) do
    {policy, ignored_policy_input} =
      opts
      |> Keyword.get(:policy, %{})
      |> normalize_resolution_policy_input()

    selection_rule = selection_rule(policy)
    requested_selection_rule = requested_selection_rule(policy)
    ignored_tie_breakers = ignored_tie_breakers(policy)

    %{
      "selection_rule" => selection_rule,
      "priority_fields" => priority_fields(policy),
      "requested_priority_fields" => requested_priority_fields(policy),
      "tie_breakers" => tie_breakers(policy),
      "action" => resolution_action(policy),
      "priority_overrides" => priority_overrides(policy),
      "priority_override_count" => priority_override_count(policy),
      "priority_override_contact_ids" => priority_override_contact_ids(policy),
      "ignored_priority_override_count" => ignored_priority_override_count(policy),
      "ignored_priority_override_keys" => ignored_priority_override_keys(policy),
      "ignored_priority_override_contact_ids" => ignored_priority_override_contact_ids(policy),
      "ignored_priority_override_input" => Map.get(policy, "ignored_priority_override_input"),
      "requested_selection_rule" =>
        if(requested_selection_rule not in [nil, selection_rule], do: requested_selection_rule),
      "ignored_tie_breakers" =>
        if(ignored_tie_breakers == [], do: nil, else: ignored_tie_breakers),
      "ignored_policy_input" => ignored_policy_input,
      "policy_warnings" =>
        policy_warnings(
          requested_selection_rule,
          selection_rule,
          ignored_tie_breakers,
          ignored_policy_input,
          ignored_priority_override_count(policy)
        )
    }
    |> compact_map()
  end

  defp normalize_resolution_policy_input(nil), do: {%{}, nil}

  defp normalize_resolution_policy_input(%{} = policy) do
    policy
    |> stringify_keys()
    |> normalize_priority_overrides()
    |> then(&{&1, nil})
  end

  defp normalize_resolution_policy_input(policy) when is_list(policy) do
    if Keyword.keyword?(policy) do
      policy
      |> Map.new()
      |> stringify_keys()
      |> normalize_priority_overrides()
      |> then(&{&1, nil})
    else
      {%{}, inspect(policy, limit: 20)}
    end
  end

  defp normalize_resolution_policy_input(policy), do: {%{}, inspect(policy, limit: 20)}

  defp normalize_priority_overrides(policy), do: PriorityOverrides.normalize(policy)

  defp priority_override_count(policy), do: PriorityOverrides.count(policy)

  defp ignored_priority_override_count(policy), do: PriorityOverrides.ignored_count(policy)

  defp priority_overrides(policy), do: PriorityOverrides.values(policy)

  defp priority_override_contact_ids(policy), do: PriorityOverrides.contact_ids(policy)

  defp ignored_priority_override_keys(policy), do: PriorityOverrides.ignored_keys(policy)

  defp ignored_priority_override_contact_ids(policy),
    do: PriorityOverrides.ignored_contact_ids(policy)

  defp selection_rule(policy) do
    case requested_selection_rule(policy) do
      rule when rule in @resolution_selection_rules -> rule
      _rule -> "highest_score_earliest_start"
    end
  end

  defp requested_selection_rule(%{"selection_rule" => rule}) when not is_nil(rule) do
    rule
    |> encode_value()
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp requested_selection_rule(_policy), do: nil

  defp resolution_action(%{"action" => action}) when is_atom(action) or is_binary(action) do
    case encode_value(action) do
      "" -> "recommend_preferred_contact_for_operator_review"
      action -> action
    end
  end

  defp resolution_action(_policy), do: "recommend_preferred_contact_for_operator_review"

  defp tie_breakers(%{"tie_breakers" => fields}) when is_list(fields) do
    fields
    |> Enum.map(&encode_value/1)
    |> Enum.filter(&(&1 in @resolution_tie_breakers))
    |> case do
      [] -> default_tie_breakers()
      fields -> Enum.uniq(fields)
    end
  end

  defp tie_breakers(%{"tie_breaker" => field}) when not is_nil(field),
    do: tie_breakers(%{"tie_breakers" => [field]})

  defp tie_breakers(_policy), do: default_tie_breakers()

  defp ignored_tie_breakers(%{"tie_breakers" => fields}) when is_list(fields) do
    fields
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in @resolution_tie_breakers))
    |> Enum.uniq()
  end

  defp ignored_tie_breakers(%{"tie_breaker" => field}) when not is_nil(field),
    do: ignored_tie_breakers(%{"tie_breakers" => [field]})

  defp ignored_tie_breakers(_policy), do: []

  defp policy_warnings(
         requested_selection_rule,
         selection_rule,
         ignored_tie_breakers,
         ignored_policy_input,
         ignored_priority_override_count
       ) do
    []
    |> maybe_add_policy_warning(
      not is_nil(ignored_policy_input),
      "unsupported_policy_input_ignored"
    )
    |> maybe_add_policy_warning(
      requested_selection_rule not in [nil, selection_rule],
      "unsupported_selection_rule_defaulted"
    )
    |> maybe_add_policy_warning(ignored_tie_breakers != [], "unsupported_tie_breakers_ignored")
    |> maybe_add_policy_warning(
      ignored_priority_override_count > 0,
      "invalid_priority_overrides_ignored"
    )
    |> case do
      [] -> nil
      warnings -> Enum.reverse(warnings)
    end
  end

  defp maybe_add_policy_warning(warnings, true, warning), do: [warning | warnings]
  defp maybe_add_policy_warning(warnings, false, _warning), do: warnings

  defp default_tie_breakers, do: ["starts_at_s", "id"]

  defp tie_breaker_sort_key(contact, policy) do
    policy
    |> Map.get("tie_breakers", default_tie_breakers())
    |> Enum.map(&tie_breaker_value(contact, policy, &1))
  end

  defp tie_breaker_value(contact, _policy, "starts_at_s"),
    do: numeric_or_zero(contact["starts_at_s"])

  defp tie_breaker_value(contact, _policy, "ends_at_s"), do: numeric_or_zero(contact["ends_at_s"])
  defp tie_breaker_value(contact, _policy, "score"), do: -numeric_or_zero(contact["score"])

  defp tie_breaker_value(contact, policy, "priority"),
    do: -numeric_or_zero(contact_priority(contact, policy))

  defp tie_breaker_value(contact, policy, "policy_contact_priority"),
    do: -numeric_or_zero(priority_field_value(contact, policy, "policy_contact_priority"))

  defp tie_breaker_value(contact, _policy, "command_contact_priority"),
    do: -numeric_or_zero(priority_field_value(contact, "command_contact_priority"))

  defp tie_breaker_value(contact, _policy, "station_reservation_priority"),
    do: -numeric_or_zero(priority_field_value(contact, "station_reservation_priority"))

  defp tie_breaker_value(contact, _policy, "id"), do: contact_id(contact)
  defp tie_breaker_value(contact, _policy, "contact_id"), do: contact_id(contact)

  defp priority_fields(%{"priority_fields" => fields}) when is_list(fields) do
    fields
    |> Enum.map(&encode_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> case do
      [] -> default_priority_fields()
      fields -> fields
    end
  end

  defp priority_fields(%{"priority_field" => field}) when not is_nil(field),
    do: priority_fields(%{"priority_fields" => [field]})

  defp priority_fields(%{"priority_overrides" => overrides}) when map_size(overrides) > 0 do
    ["policy_contact_priority" | default_priority_fields()]
  end

  defp priority_fields(_policy), do: default_priority_fields()

  defp requested_priority_fields(%{"priority_fields" => fields}) when is_list(fields) do
    fields
    |> Enum.map(&encode_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [] -> nil
      fields -> fields
    end
  end

  defp requested_priority_fields(%{"priority_field" => field}) when not is_nil(field),
    do: requested_priority_fields(%{"priority_fields" => [field]})

  defp requested_priority_fields(_policy), do: nil

  defp default_priority_fields, do: @default_resolution_priority_fields

  defp contact_priority(contact, policy) do
    policy
    |> priority_fields()
    |> Enum.find_value(fn field ->
      case priority_field_value(contact, policy, field) do
        value when is_number(value) -> numeric_or_nil(value)
        value when is_binary(value) -> numeric_or_nil(value)
        _value -> nil
      end
    end)
  end

  defp contact_priority_source(contact, policy) do
    policy
    |> priority_fields()
    |> Enum.find(fn field ->
      not is_nil(numeric_or_nil(priority_field_value(contact, policy, field)))
    end)
  end

  defp priority_field_value(contact, policy, "policy_contact_priority") do
    policy
    |> Map.get("priority_overrides", %{})
    |> Map.get(contact_id_or_nil(contact))
  end

  defp priority_field_value(contact, _policy, field), do: priority_field_value(contact, field)

  defp priority_field_value(contact, "command_contact_priority") do
    if command_contact?(contact), do: 1.0, else: 0.0
  end

  defp priority_field_value(contact, "station_reservation_priority") do
    if direct_station_reservation_priority?(contact), do: 1.0
  end

  defp priority_field_value(contact, field), do: Map.get(contact, field)

  defp command_contact?(contact), do: contact_direction(contact) in @command_contact_directions

  defp direct_station_reservation_priority?(contact) do
    match_status =
      contact
      |> aliased_value(["station_reservation_match_status", "reservation_match_status"])

    reservation_status =
      contact
      |> aliased_value(["station_reservation_status", "reservation_status"])

    match_status in @station_reservation_priority_match_statuses or
      (direct_station_reservation_identity?(contact) and
         reservation_status in @station_reservation_priority_statuses)
  end

  defp direct_station_reservation_identity?(contact) do
    value_present?(Map.get(contact, "station_reservation_id")) or
      value_present?(Map.get(contact, "reservation_id"))
  end

  defp deferred_contact_priorities(contacts, policy) do
    contacts
    |> Enum.map(fn contact ->
      %{
        "contact_id" => contact_id(contact),
        "priority" => contact_priority(contact, policy),
        "priority_source" => contact_priority_source(contact, policy)
      }
      |> compact_map()
    end)
    |> Enum.reject(&(map_size(&1) == 1 and Map.has_key?(&1, "contact_id")))
  end

  defp contact_candidate?(contact) do
    contact_like_input?(contact) and
      is_nil(contact_id_issue(contact)) and
      is_nil(contact_identity_issue(contact)) and
      not is_nil(Map.get(contact, "ground_station_id")) and
      is_number(Map.get(contact, "starts_at_s")) and
      is_number(Map.get(contact, "ends_at_s"))
  end

  defp spacecraft_contact_candidate?(contact) do
    contact_candidate?(contact) and not is_nil(contact_spacecraft_id(contact))
  end

  defp contact_like_input?(contact) do
    Map.get(contact, "invalid_contact_shape") == true or
      Map.get(contact, "type") in @contact_types or
      Map.get(contact, "direction") in @contact_directions or
      provider_downlink_contact_input?(contact)
  end

  defp provider_downlink_contact_input?(contact) do
    Map.get(contact, "type") in [nil, "contact", "planned_contact"] and
      Map.get(contact, "direction") in [nil, "downlink"] and
      provider_contact_evidence?(contact)
  end

  defp provider_contact_evidence?(contact) do
    Enum.any?(
      [
        Map.get(contact, "id"),
        Map.get(contact, "contact_id"),
        Map.get(contact, "activity_id"),
        Map.get(contact, "ground_station_id"),
        Map.get(contact, "station"),
        Map.get(contact, "ground_station"),
        Map.get(contact, "starts_at_s"),
        Map.get(contact, "ends_at_s"),
        Map.get(contact, "source_window_id"),
        Map.get(contact, "estimated_throughput_mb"),
        actual_throughput_value(contact)
      ],
      fn value -> not is_nil(value) end
    )
  end

  defp actual_throughput_value(contact), do: FeedbackContext.actual_throughput_value(contact)

  defp invalid_contact_input?(contact), do: not contact_candidate?(contact)

  defp invalid_contact_input_reason(contact) do
    cond do
      Map.get(contact, "invalid_contact_shape") == true -> "invalid_contact_shape"
      reason = contact_id_issue(contact) -> reason
      reason = contact_identity_issue(contact) -> reason
      is_nil(Map.get(contact, "ground_station_id")) -> "missing_ground_station_id"
      not is_number(Map.get(contact, "starts_at_s")) -> "missing_contact_starts_at_s"
      not is_number(Map.get(contact, "ends_at_s")) -> "missing_contact_ends_at_s"
      true -> "invalid_contact_input"
    end
  end

  defp contact_spacecraft_id(contact), do: ContactIdentity.spacecraft_id(contact)

  defp group_ground_station_ids(contacts), do: ContactIdentity.group_ground_station_ids(contacts)

  defp group_spacecraft_ids(contacts), do: ContactIdentity.group_spacecraft_ids(contacts)

  defp group_stable_ids(contacts, field), do: ContactIdentity.group_stable_ids(contacts, field)

  defp group_ground_station_id(ground_station_ids),
    do: ContactIdentity.group_ground_station_id(ground_station_ids)

  defp group_direction(contacts), do: ContactIdentity.group_direction(contacts)

  defp group_directions(contacts), do: ContactIdentity.group_directions(contacts)

  defp contact_direction(contact), do: ContactIdentity.direction(contact)

  defp contact_id(contact), do: ContactIdentity.contact_id(contact)

  defp contact_id_or_nil(contact), do: ContactIdentity.contact_id_or_nil(contact)

  defp invalid_contact_row_id("invalid_contact_shape", index), do: "missing_contact_id:#{index}"
  defp invalid_contact_row_id(reason, index), do: "#{reason}:#{index}"

  defp contact_id_issue(contact), do: ContactIdentity.id_issue(contact)

  defp contact_identity_issue(contact), do: ContactIdentity.identity_issue(contact)

  defp stable_id_or_nil(value), do: ContactIdentity.stable_id_or_nil(value)

  defp canonical_contact_sort_key(contact), do: ContactIdentity.sort_key(contact)

  defp numeric_or_zero(value), do: numeric_or_nil(value) || 0.0

  defp numeric_or_nil(value), do: ContactNormalization.numeric_or_nil(value)
  defp stringify_keys(value), do: ContactNormalization.stringify_keys(value)

  defp normalize_contact(contact) do
    ContactNormalization.normalize(
      contact,
      StationCalendarContext.unavailable_aliases(),
      @default_resolution_priority_fields,
      @provider_direction_aliases
    )
  end

  defp compact_map(map), do: ContactNormalization.compact_map(map)
  defp encode_value(value), do: ContactNormalization.encode_value(value)

  defp encoded_value_or_nil(value), do: encode_value(value)

  defp aliased_value(contact, fields) do
    fields
    |> Enum.find_value(fn field ->
      value = Map.get(contact, field)

      if value_present?(value), do: encoded_value_or_nil(value)
    end)
  end

  defp value_present?(nil), do: false
  defp value_present?(""), do: false
  defp value_present?([]), do: false
  defp value_present?(_value), do: true
end
