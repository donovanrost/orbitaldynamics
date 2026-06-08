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
  @health_check_contact_directions ~w(health_check)
  @unavailable_aliases ["outage", "down", "offline"]
  @station_availability_severity %{
    "unavailable" => 5,
    "maintenance" => 5,
    "reserved" => 4,
    "reduced_capacity" => 3,
    "available" => 1
  }
  @station_capacity_fraction_paths [
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["station_capacity_percent"],
    ["capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"]
  ]
  @station_capacity_value_paths [
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]},
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]}
  ]
  @required_capacity_fraction_paths [
    ["required_capacity_fraction"],
    ["required_station_capacity_fraction"],
    ["station_capacity_requirement"],
    ["throughput_model", "required_capacity_fraction"],
    ["throughput_model", "required_station_capacity_fraction"],
    ["throughput_model", "station_capacity_requirement"],
    ["capacity_model", "required_capacity_fraction"],
    ["capacity_model", "required_station_capacity_fraction"],
    ["capacity_model", "station_capacity_requirement"],
    ["activity_context", "required_capacity_fraction"],
    ["activity_context", "required_station_capacity_fraction"],
    ["activity_context", "station_capacity_requirement"]
  ]
  @required_capacity_percent_paths [
    ["required_capacity_percent"],
    ["required_station_capacity_percent"],
    ["station_capacity_requirement_percent"],
    ["throughput_model", "required_capacity_percent"],
    ["throughput_model", "required_station_capacity_percent"],
    ["throughput_model", "station_capacity_requirement_percent"],
    ["capacity_model", "required_capacity_percent"],
    ["capacity_model", "required_station_capacity_percent"],
    ["capacity_model", "station_capacity_requirement_percent"],
    ["activity_context", "required_capacity_percent"],
    ["activity_context", "required_station_capacity_percent"],
    ["activity_context", "station_capacity_requirement_percent"]
  ]
  @required_capacity_fraction_source_values ~w(
    contact_required_capacity_fraction
    throughput_model
    capacity_model
    activity_context
  )
  @required_capacity_value_paths [
    {:fraction, ["required_capacity_fraction"]},
    {:fraction, ["required_station_capacity_fraction"]},
    {:fraction, ["station_capacity_requirement"]},
    {:percent, ["required_capacity_percent"]},
    {:percent, ["required_station_capacity_percent"]},
    {:percent, ["station_capacity_requirement_percent"]},
    {:fraction, ["throughput_model", "required_capacity_fraction"]},
    {:fraction, ["throughput_model", "required_station_capacity_fraction"]},
    {:fraction, ["throughput_model", "station_capacity_requirement"]},
    {:percent, ["throughput_model", "required_capacity_percent"]},
    {:percent, ["throughput_model", "required_station_capacity_percent"]},
    {:percent, ["throughput_model", "station_capacity_requirement_percent"]},
    {:fraction, ["capacity_model", "required_capacity_fraction"]},
    {:fraction, ["capacity_model", "required_station_capacity_fraction"]},
    {:fraction, ["capacity_model", "station_capacity_requirement"]},
    {:percent, ["capacity_model", "required_capacity_percent"]},
    {:percent, ["capacity_model", "required_station_capacity_percent"]},
    {:percent, ["capacity_model", "station_capacity_requirement_percent"]},
    {:fraction, ["activity_context", "required_capacity_fraction"]},
    {:fraction, ["activity_context", "required_station_capacity_fraction"]},
    {:fraction, ["activity_context", "station_capacity_requirement"]},
    {:percent, ["activity_context", "required_capacity_percent"]},
    {:percent, ["activity_context", "required_station_capacity_percent"]},
    {:percent, ["activity_context", "station_capacity_requirement_percent"]}
  ]
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
  @resolution_priority_override_aliases ~w(
    priority_overrides
    contact_priority_overrides
    contact_priorities
    priority_by_contact_id
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
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @contact_stable_identity_fields ~w(
    scenario_id
    spacecraft_id
    satellite_id
    ground_station_id
    source_window_id
  )
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  alias OrbitalDynamics.Policy

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
      station_unavailable_aliases: @unavailable_aliases,
      station_availability_precedence: @station_availability_severity,
      station_capacity_fraction_paths: @station_capacity_fraction_paths,
      station_capacity_percent_paths: @station_capacity_percent_paths,
      station_capacity_value_paths: capacity_value_path_metadata(@station_capacity_value_paths),
      source_station_capacity_fraction_paths: @station_capacity_fraction_paths,
      source_station_capacity_percent_paths: @station_capacity_percent_paths,
      source_station_capacity_value_paths:
        capacity_value_path_metadata(@station_capacity_value_paths),
      required_capacity_fraction_paths: @required_capacity_fraction_paths,
      required_capacity_percent_paths: @required_capacity_percent_paths,
      required_capacity_value_paths: capacity_value_path_metadata(@required_capacity_value_paths),
      required_capacity_fraction_source_values: @required_capacity_fraction_source_values,
      station_reservation_priority_match_statuses: @station_reservation_priority_match_statuses,
      station_reservation_priority_statuses: @station_reservation_priority_statuses,
      resolution_selection_rules: @resolution_selection_rules,
      resolution_tie_breakers: @resolution_tie_breakers,
      default_resolution_priority_fields: @default_resolution_priority_fields,
      resolution_priority_override_aliases: @resolution_priority_override_aliases,
      provider_direction_aliases: @provider_direction_aliases,
      provider_result_map_value_keys: @provider_result_map_value_keys,
      contact_stable_identity_fields: @contact_stable_identity_fields,
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
      |> Enum.map(&maybe_apply_recommendation_approval_policy(&1, approval_policy))
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
    contention_resolution_summary(report)
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

  defp contention_resolution_summary(report) do
    report = stringify_keys(report)
    recommendations = report |> Map.get("recommendations", []) |> Enum.filter(&is_map/1)

    review_recommendations =
      Enum.filter(recommendations, &(&1["review_status"] == "operator_review_required"))

    capacity_pack_demand = contention_resolution_capacity_pack_demand(recommendations)

    %{
      "schema_contract" => @resolution_summary_contract,
      "model" => "artifact_only_contact_contention_resolution_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @resolution_contract),
      "model_limits" => model_limits(),
      "conflict_group_count" => length(recommendation_values(recommendations, "group_id")),
      "recommendation_count" => length(recommendations),
      "policy" => report["policy"],
      "recommendation_group_ids" => recommendation_values(recommendations, "group_id"),
      "review_group_ids" => recommendation_values(review_recommendations, "group_id"),
      "selected_contact_ids" => recommendation_values(recommendations, "selected_contact_id"),
      "selected_contact_ids_by_group_id" =>
        recommendation_values_by_field(recommendations, "group_id", "selected_contact_id"),
      "deferred_contact_ids" =>
        recommendation_list_values(recommendations, "deferred_contact_ids"),
      "deferred_contact_ids_by_group_id" =>
        recommendation_list_values_by_field(recommendations, "group_id", "deferred_contact_ids"),
      "ambiguous_group_ids" =>
        recommendations
        |> Enum.filter(&(&1["resolution_status"] == "ambiguous_contact_identity"))
        |> recommendation_values("group_id"),
      "ambiguous_duplicate_contact_ids" =>
        recommendation_list_values(recommendations, "duplicate_contact_ids"),
      "ambiguous_duplicate_contact_ids_by_group_id" =>
        recommendation_list_values_by_field(recommendations, "group_id", "duplicate_contact_ids"),
      "review_contact_ids" => contention_resolution_review_contact_ids(review_recommendations),
      "review_contact_ids_by_group_id" =>
        contention_resolution_review_contact_ids_by_field(review_recommendations, "group_id"),
      "review_recommendation_count" => length(review_recommendations),
      "resource_scope_counts" => recommendation_count_by_field(recommendations, "resource_scope"),
      "selected_contact_ids_by_resource_scope" =>
        recommendation_values_by_field(recommendations, "resource_scope", "selected_contact_id"),
      "deferred_contact_ids_by_resource_scope" =>
        recommendation_list_values_by_field(
          recommendations,
          "resource_scope",
          "deferred_contact_ids"
        ),
      "review_contact_ids_by_resource_scope" =>
        contention_resolution_review_contact_ids_by_field(
          review_recommendations,
          "resource_scope"
        ),
      "selection_reason_counts" =>
        recommendation_count_by_field(recommendations, "selection_reason"),
      "selected_contact_ids_by_selection_reason" =>
        recommendation_values_by_field(
          recommendations,
          "selection_reason",
          "selected_contact_id"
        ),
      "action_counts" => recommendation_count_by_field(recommendations, "action"),
      "review_contact_ids_by_action" =>
        contention_resolution_review_contact_ids_by_field(review_recommendations, "action"),
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
    |> compact_map()
  end

  defp contention_resolution_capacity_pack_demand(recommendations) do
    rows = Enum.flat_map(recommendations, &contention_resolution_capacity_pack_demand_rows/1)
    selected_rows = Enum.filter(rows, &(&1.status == :selected))
    deferred_rows = Enum.filter(rows, &(&1.status == :deferred))

    %{
      "capacity_pack_required_capacity_fraction" => demand_row_total(rows),
      "capacity_pack_selected_required_capacity_fraction" => demand_row_total(selected_rows),
      "capacity_pack_deferred_required_capacity_fraction" => demand_row_total(deferred_rows),
      "capacity_pack_required_capacity_fraction_by_status" => demand_rows_by_status(rows),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        demand_rows_by_station(rows),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        demand_rows_by_station(selected_rows),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        demand_rows_by_station(deferred_rows),
      "required_capacity_fraction_source_counts" => demand_rows_by_source(rows),
      "required_capacity_fraction_contact_ids_by_source" => demand_row_ids_by_source(rows)
    }
  end

  defp contention_resolution_capacity_pack_demand_rows(recommendation) do
    candidates = recommendation |> Map.get("source_contact_candidates", []) |> List.wrap()
    selected_contact_id = recommendation["selected_contact_id"]
    deferred_contact_ids = MapSet.new(List.wrap(recommendation["deferred_contact_ids"]))

    candidates
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn contact ->
      contact_id = contact_id(contact)
      required_capacity_fraction = required_capacity_fraction(contact)

      cond do
        is_nil(contact_id) or is_nil(required_capacity_fraction) ->
          []

        contact_id == selected_contact_id ->
          [capacity_pack_demand_row(contact, :selected, required_capacity_fraction)]

        MapSet.member?(deferred_contact_ids, contact_id) ->
          [capacity_pack_demand_row(contact, :deferred, required_capacity_fraction)]

        true ->
          []
      end
    end)
  end

  defp capacity_pack_demand_row(contact, status, required_capacity_fraction) do
    %{
      status: status,
      contact_id: contact_id(contact),
      ground_station_id: stable_id_or_nil(contact["ground_station_id"]),
      required_capacity_fraction: required_capacity_fraction,
      required_capacity_fraction_source: required_capacity_fraction_source(contact)
    }
  end

  defp demand_row_total(rows) do
    rows
    |> Enum.map(& &1.required_capacity_fraction)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp demand_rows_by_station(rows) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      if is_nil(row.ground_station_id) do
        totals
      else
        Map.update(totals, row.ground_station_id, row.required_capacity_fraction, fn value ->
          value + row.required_capacity_fraction
        end)
      end
    end)
    |> case do
      values when values == %{} -> nil
      values -> values
    end
  end

  defp demand_rows_by_status(rows) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      Map.update(totals, Atom.to_string(row.status), row.required_capacity_fraction, fn value ->
        value + row.required_capacity_fraction
      end)
    end)
  end

  defp contention_resolution_review_contact_ids(recommendations) do
    recommendations
    |> Enum.flat_map(fn recommendation ->
      [recommendation["selected_contact_id"]] ++
        List.wrap(recommendation["deferred_contact_ids"]) ++
        List.wrap(recommendation["duplicate_contact_ids"])
    end)
    |> compact_sorted_unique_list()
  end

  defp recommendation_values(recommendations, field) do
    recommendations
    |> Enum.map(& &1[field])
    |> compact_sorted_unique_list()
  end

  defp recommendation_list_values(recommendations, field) do
    recommendations
    |> Enum.flat_map(&List.wrap(&1[field]))
    |> compact_sorted_unique_list()
  end

  defp recommendation_values_by_field(recommendations, group_field, value_field) do
    recommendations
    |> Enum.group_by(& &1[group_field], & &1[value_field])
    |> compact_value_map()
  end

  defp recommendation_list_values_by_field(recommendations, group_field, value_field) do
    recommendations
    |> Enum.group_by(& &1[group_field], &List.wrap(&1[value_field]))
    |> Map.new(fn {group, values} -> {group, Enum.flat_map(values, & &1)} end)
    |> compact_value_map()
  end

  defp contention_resolution_review_contact_ids_by_field(recommendations, group_field) do
    recommendations
    |> Enum.group_by(& &1[group_field], fn recommendation ->
      [recommendation["selected_contact_id"]] ++
        List.wrap(recommendation["deferred_contact_ids"]) ++
        List.wrap(recommendation["duplicate_contact_ids"])
    end)
    |> Map.new(fn {group, values} -> {group, Enum.flat_map(values, & &1)} end)
    |> compact_value_map()
  end

  defp recommendation_count_by_field(recommendations, field) do
    recommendations
    |> Enum.map(& &1[field])
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp compact_sorted_unique_list(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_value_map(values_by_group) do
    values_by_group
    |> Enum.reject(fn {group, values} ->
      is_nil(group) or Enum.all?(List.wrap(values), &is_nil/1)
    end)
    |> Map.new(fn {group, values} -> {group, compact_sorted_unique_list(List.wrap(values))} end)
  end

  defp contention_report(contact_inputs, groups, invalid_contact_inputs, opts) do
    source = opts |> Keyword.get(:source, "contact_candidates") |> to_string()
    approval_policy = Keyword.get(opts, :approval_policy)

    invalid_rows =
      invalid_contact_inputs
      |> invalid_contact_rows()
      |> Enum.map(&maybe_apply_invalid_input_approval_policy(&1, approval_policy))

    groups =
      Enum.map(groups, &maybe_apply_group_approval_policy(&1, approval_policy))

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
    |> Map.merge(station_calendar_context(contacts))
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
    |> Map.merge(station_calendar_context(contacts))
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
    |> Map.merge(station_calendar_context(contacts))
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
    |> Map.merge(station_calendar_context(contacts))
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

  defp contention_timing_metrics(contacts) do
    intervals =
      contacts
      |> Enum.map(fn contact -> {contact["starts_at_s"], contact["ends_at_s"]} end)
      |> Enum.filter(fn {starts_at_s, ends_at_s} ->
        is_number(starts_at_s) and is_number(ends_at_s) and starts_at_s < ends_at_s
      end)

    %{
      "contention_window_s" => contention_window_s(intervals),
      "total_contact_duration_s" => total_contact_duration_s(intervals),
      "overlap_duration_s" => overlap_duration_s(intervals),
      "max_concurrent_contacts" => max_concurrent_contacts(intervals),
      "overlap_contact_pair_count" => overlap_contact_pair_count(intervals)
    }
    |> compact_map()
  end

  defp contention_window_s([]), do: nil

  defp contention_window_s(intervals) do
    starts_at_s =
      intervals |> Enum.map(fn {starts_at_s, _ends_at_s} -> starts_at_s end) |> Enum.min()

    ends_at_s = intervals |> Enum.map(fn {_starts_at_s, ends_at_s} -> ends_at_s end) |> Enum.max()

    ends_at_s - starts_at_s
  end

  defp total_contact_duration_s(intervals) do
    Enum.reduce(intervals, 0.0, fn {starts_at_s, ends_at_s}, total ->
      total + ends_at_s - starts_at_s
    end)
  end

  defp overlap_duration_s(intervals) do
    intervals
    |> interval_events()
    |> Enum.reduce({nil, 0, 0.0}, fn {time_s, delta}, {previous_time_s, active_count, total} ->
      total =
        if is_number(previous_time_s) and active_count > 1 do
          total + time_s - previous_time_s
        else
          total
        end

      {time_s, active_count + delta, total}
    end)
    |> elem(2)
  end

  defp max_concurrent_contacts(intervals) do
    intervals
    |> interval_events()
    |> Enum.reduce({0, 0}, fn {_time_s, delta}, {active_count, maximum} ->
      active_count = active_count + delta
      {active_count, max(maximum, active_count)}
    end)
    |> elem(1)
  end

  defp interval_events(intervals) do
    intervals
    |> Enum.flat_map(fn {starts_at_s, ends_at_s} -> [{starts_at_s, 1}, {ends_at_s, -1}] end)
    |> Enum.group_by(fn {time_s, _delta} -> time_s end, fn {_time_s, delta} -> delta end)
    |> Enum.map(fn {time_s, deltas} -> {time_s, Enum.sum(deltas)} end)
    |> Enum.sort_by(fn {time_s, _delta} -> time_s end)
  end

  defp overlap_contact_pair_count(intervals) do
    intervals
    |> Enum.with_index()
    |> Enum.flat_map(fn {{starts_at_s, ends_at_s}, index} ->
      intervals
      |> Enum.with_index()
      |> Enum.filter(fn {{other_starts_at_s, other_ends_at_s}, other_index} ->
        index < other_index and starts_at_s < other_ends_at_s and other_starts_at_s < ends_at_s
      end)
    end)
    |> length()
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
        ),
      "actual_throughput_mb" => aggregate_actual_throughput_mb(contacts),
      "actual_data_rate_throughput_derivations" =>
        aggregate_actual_data_rate_throughput_derivations(contacts)
    }
    |> compact_map()
  end

  defp contact_feedback_fields do
    [
      "contact_success",
      "contact_result",
      "contact_success_factor",
      "contact_success_factor_source",
      "command_success",
      "command_result",
      "command_success_factor",
      "command_success_factor_source",
      "actual_throughput_mb",
      "actual_data_rate_throughput_derivations"
    ]
  end

  defp station_calendar_context(contacts) do
    %{
      "station_availability" => station_availability(contacts),
      "station_calendar_status" => station_calendar_status(contacts),
      "capacity_fraction" => station_capacity_fraction(contacts),
      "capacity_fraction_min" => station_capacity_fraction_min(contacts),
      "capacity_fraction_max" => station_capacity_fraction_max(contacts),
      "station_calendar_entry_ids" =>
        stable_context_values(contacts, ["station_calendar_entry_id"]),
      "station_calendar_provider_ids" =>
        stable_context_values(contacts, ["station_calendar_provider_id"]),
      "station_calendar_provider_entry_ids" =>
        stable_context_values(contacts, ["station_calendar_provider_entry_id"]),
      "station_calendar_overlap_entry_ids" =>
        stable_context_values(contacts, ["station_calendar_overlap_entry_ids"]),
      "station_calendar_directions" =>
        string_context_values(contacts, ["station_calendar_directions"]),
      "station_calendar_reservation_ids" =>
        stable_context_values(contacts, ["station_calendar_reservation_ids"]),
      "station_calendar_reserved_by" =>
        string_context_values(contacts, ["station_calendar_reserved_by"]),
      "station_calendar_reservation_statuses" =>
        string_context_values(contacts, ["station_calendar_reservation_statuses"]),
      "station_calendar_reservation_expires_at_s" =>
        numeric_context_values(contacts, [
          "station_calendar_reservation_expires_at_s",
          "station_reservation_expires_at_s",
          "reservation_expires_at_s"
        ]),
      "station_calendar_trust_boundary_statuses" =>
        string_context_values(contacts, ["station_calendar_trust_boundary_status"]),
      "station_reservation_ids" =>
        stable_context_values(contacts, ["station_reservation_id", "reservation_id"]),
      "station_reserved_bys" =>
        string_context_values(contacts, ["station_reserved_by", "reserved_by"]),
      "station_reservation_statuses" =>
        string_context_values(contacts, ["station_reservation_status", "reservation_status"]),
      "station_reservation_match_statuses" =>
        string_context_values(contacts, [
          "station_reservation_match_status",
          "reservation_match_status"
        ])
    }
    |> Enum.reject(fn {_key, value} -> value == [] end)
    |> Map.new()
  end

  defp demand_rows_by_source(rows) do
    rows
    |> Enum.map(& &1.required_capacity_fraction_source)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp demand_row_ids_by_source(rows) do
    rows
    |> Enum.group_by(& &1.required_capacity_fraction_source, & &1.contact_id)
    |> Enum.reject(fn {source, ids} ->
      is_nil(source) or Enum.all?(ids, &is_nil/1)
    end)
    |> Map.new(fn {source, ids} ->
      {source, compact_sorted_unique_list(ids)}
    end)
  end

  defp station_calendar_context_fields do
    [
      "station_availability",
      "station_calendar_status",
      "capacity_fraction",
      "capacity_fraction_min",
      "capacity_fraction_max",
      "station_calendar_entry_ids",
      "station_calendar_provider_ids",
      "station_calendar_provider_entry_ids",
      "station_calendar_overlap_entry_ids",
      "station_calendar_directions",
      "station_calendar_reservation_ids",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses",
      "station_calendar_reservation_expires_at_s",
      "station_calendar_trust_boundary_statuses",
      "station_reservation_ids",
      "station_reserved_bys",
      "station_reservation_statuses",
      "station_reservation_match_statuses"
    ]
  end

  defp station_availability(contacts) do
    contacts
    |> Enum.flat_map(&station_availability_candidates/1)
    |> Enum.filter(&station_availability_value?/1)
    |> highest_station_availability()
    |> canonical_station_availability()
  end

  defp station_calendar_status(contacts) do
    contacts
    |> Enum.flat_map(&station_calendar_status_candidates/1)
    |> Enum.filter(&station_availability_value?/1)
    |> highest_station_availability()
    |> canonical_station_availability()
  end

  defp station_capacity_fraction(contacts) do
    contacts
    |> station_capacity_fractions()
    |> case do
      [] -> nil
      fractions -> Enum.min(fractions)
    end
  end

  defp station_capacity_fraction_min(contacts), do: station_capacity_fraction(contacts)

  defp station_capacity_fraction_max(contacts) do
    contacts
    |> station_capacity_fractions()
    |> case do
      [] -> nil
      fractions -> Enum.max(fractions)
    end
  end

  defp station_capacity_fractions(contacts) do
    contacts
    |> Enum.flat_map(&station_capacity_fraction_candidates/1)
    |> Enum.map(&unit_interval_number/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_capacity_fraction_candidates(contact) do
    capacity_value_candidates(contact, @station_capacity_value_paths) ++
      source_station_capacity_fraction_candidates(contact["source_station_calendar_entry"]) ++
      source_station_capacity_fraction_candidates(contact["source_station_calendar_overlaps"])
  end

  defp required_capacity_fraction(contact) do
    contact
    |> capacity_value_candidates(@required_capacity_value_paths)
    |> Enum.find_value(&unit_interval_number/1)
  end

  defp required_capacity_fraction_source(contact) do
    cond do
      valid_capacity_value_declared?(contact["required_capacity_fraction"]) or
        valid_capacity_value_declared?(contact["required_station_capacity_fraction"]) or
        valid_capacity_value_declared?(contact["station_capacity_requirement"]) or
        valid_capacity_percent_declared?(contact["required_capacity_percent"]) or
        valid_capacity_percent_declared?(contact["required_station_capacity_percent"]) or
          valid_capacity_percent_declared?(contact["station_capacity_requirement_percent"]) ->
        "contact_required_capacity_fraction"

      valid_capacity_value_declared?(
        get_in(contact, ["throughput_model", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["throughput_model", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["throughput_model", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["throughput_model", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["throughput_model", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["throughput_model", "station_capacity_requirement_percent"])
          ) ->
        "throughput_model"

      valid_capacity_value_declared?(
        get_in(contact, ["capacity_model", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["capacity_model", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["capacity_model", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["capacity_model", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["capacity_model", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["capacity_model", "station_capacity_requirement_percent"])
          ) ->
        "capacity_model"

      valid_capacity_value_declared?(
        get_in(contact, ["activity_context", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["activity_context", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["activity_context", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["activity_context", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["activity_context", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["activity_context", "station_capacity_requirement_percent"])
          ) ->
        "activity_context"

      true ->
        nil
    end
  end

  defp valid_capacity_value_declared?(value) do
    case numeric_or_nil(value) do
      value when is_number(value) -> value >= 0.0 and value <= 1.0
      _value -> false
    end
  end

  defp valid_capacity_percent_declared?(value) do
    case numeric_or_nil(value) do
      value when is_number(value) -> value >= 0.0 and value <= 100.0
      _value -> false
    end
  end

  defp source_station_capacity_fraction_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_fraction_candidates/1)

  defp source_station_capacity_fraction_candidates(%{} = source) do
    capacity_value_candidates(source, @station_capacity_value_paths)
  end

  defp source_station_capacity_fraction_candidates(_source), do: []

  defp capacity_value_candidates(value, paths) do
    Enum.map(paths, fn
      {:fraction, path} ->
        path_value(value, path)

      {:percent, path} ->
        capacity_percent_fraction(path_value(value, path))
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp capacity_percent_fraction(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp unit_interval_number(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
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

  defp station_calendar_status_candidates(contact) do
    [
      contact["station_calendar_status"],
      contact["status"]
    ] ++
      source_station_calendar_status_candidates(contact["source_station_calendar_entry"]) ++
      source_station_calendar_status_candidates(contact["source_station_calendar_overlaps"])
  end

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

  defp source_station_calendar_status_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_status_candidates/1)

  defp source_station_calendar_status_candidates(%{} = source) do
    [
      source["station_calendar_status"],
      source["status"],
      source["availability"]
    ]
  end

  defp source_station_calendar_status_candidates(_source), do: []

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

  defp canonical_station_availability(value)
       when value in ["unavailable", "maintenance" | @unavailable_aliases],
       do: "unavailable"

  defp canonical_station_availability(value), do: value

  defp stable_context_values(contacts, fields) do
    contacts
    |> context_values(fields)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp string_context_values(contacts, fields) do
    contacts
    |> context_values(fields)
    |> Enum.map(&encode_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp numeric_context_values(contacts, fields) do
    contacts
    |> context_values(fields)
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp context_values(contacts, fields) do
    Enum.flat_map(contacts, fn contact ->
      Enum.flat_map(fields, fn field ->
        contact
        |> Map.get(field)
        |> List.wrap()
      end)
    end)
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
    |> Enum.map(&numeric_or_nil(contact_value(&1, key)))
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> nil end)
  end

  defp aggregate_factor_source(contacts, factor_key, source_key) do
    contacts
    |> Enum.filter(&is_number(numeric_or_nil(contact_value(&1, factor_key))))
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

  defp aggregate_actual_throughput_mb(contacts) do
    contacts
    |> Enum.map(&actual_throughput_value/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp aggregate_actual_data_rate_throughput_derivations(contacts) do
    contacts
    |> Enum.map(fn contact ->
      case actual_data_rate_throughput_derivation(contact) do
        %{} = derivation ->
          derivation
          |> Map.put("contact_id", contact_id(contact))

        _derivation ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      derivations -> derivations
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

  defp maybe_apply_group_approval_policy(group, nil), do: group

  defp maybe_apply_group_approval_policy(group, approval_policy) do
    requirement = group_approval_requirement(group)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "contact_contention", "events" => []},
        %{},
        approval_policy
      )

    group
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
        %{"id" => "contact_contention_invalid_input", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp maybe_apply_recommendation_approval_policy(recommendation, nil), do: recommendation

  defp maybe_apply_recommendation_approval_policy(recommendation, approval_policy) do
    requirement = recommendation_approval_requirement(recommendation)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "contact_contention_resolution", "events" => []},
        %{},
        approval_policy
      )

    recommendation
    |> Map.put("review_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp group_approval_requirement(group) do
    %{
      "activity_id" => group["id"],
      "activity_type" => "contact_contention",
      "action" => group["required_operator_action"],
      "requirement_type" => contention_requirement_type(group),
      "reason" => contention_requirement_reason(group),
      "activity_context" =>
        %{
          "resource_scope" => group["resource_scope"],
          "ground_station_id" => group["ground_station_id"],
          "ground_station_ids" => group["ground_station_ids"],
          "spacecraft_id" => group["spacecraft_id"],
          "spacecraft_ids" => group["spacecraft_ids"],
          "direction" => group["direction"],
          "directions" => group["directions"],
          "required_operator_action" => group["required_operator_action"],
          "operator_action_reason" => group["operator_action_reason"],
          "contact_count" => group["contact_count"],
          "contact_ids" => group["contact_ids"],
          "duplicate_contact_ids" => group["duplicate_contact_ids"],
          "duplicate_contact_id_count" => group["duplicate_contact_id_count"],
          "duplicate_contact_candidate_count" => group["duplicate_contact_candidate_count"],
          "source_window_ids" => group["source_window_ids"],
          "scenario_ids" => group["scenario_ids"]
        }
        |> Map.merge(Map.take(group, contact_feedback_fields()))
        |> Map.merge(Map.take(group, station_calendar_context_fields()))
        |> compact_map()
    }
    |> compact_map()
  end

  defp invalid_input_approval_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => "contact_contention",
      "action" => row["required_operator_action"],
      "requirement_type" => "contact_schedule_change",
      "reason" => row["operator_action_reason"],
      "activity_context" =>
        %{
          "resource_scope" => "ground_station",
          "ground_station_id" => row["ground_station_id"],
          "ground_station_ids" => row["ground_station_ids"],
          "spacecraft_id" => row["spacecraft_id"],
          "spacecraft_ids" => row["spacecraft_ids"],
          "direction" => row["direction"],
          "directions" => row["directions"],
          "required_operator_action" => row["required_operator_action"],
          "operator_action_reason" => row["operator_action_reason"],
          "contact_id" => row["contact_id"],
          "contact_ids" => row["contact_ids"],
          "contact_count" => row["contact_count"],
          "invalid_contact_input" => row["invalid_contact_input"],
          "invalid_contact_input_reason" => row["invalid_contact_input_reason"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp recommendation_approval_requirement(recommendation) do
    %{
      "activity_id" => recommendation["group_id"],
      "activity_type" => "contact_contention_resolution",
      "action" => recommendation["action"],
      "requirement_type" => contention_requirement_type(recommendation),
      "reason" => contention_resolution_requirement_reason(recommendation),
      "activity_context" =>
        %{
          "resource_scope" => recommendation["resource_scope"],
          "ground_station_id" => recommendation["ground_station_id"],
          "ground_station_ids" => recommendation["ground_station_ids"],
          "spacecraft_id" => recommendation["spacecraft_id"],
          "spacecraft_ids" => recommendation["spacecraft_ids"],
          "direction" => recommendation["direction"],
          "directions" => recommendation["directions"],
          "required_operator_action" => recommendation["action"],
          "selected_contact_id" => recommendation["selected_contact_id"],
          "selected_priority" => recommendation["selected_priority"],
          "selected_priority_source" => recommendation["selected_priority_source"],
          "deferred_contact_ids" => recommendation["deferred_contact_ids"],
          "deferred_contact_priorities" => recommendation["deferred_contact_priorities"],
          "candidate_count" => recommendation["candidate_count"],
          "resolution_status" => recommendation["resolution_status"],
          "resolution_issue" => recommendation["resolution_issue"],
          "duplicate_contact_ids" => recommendation["duplicate_contact_ids"],
          "duplicate_contact_id_count" => recommendation["duplicate_contact_id_count"],
          "duplicate_contact_candidate_count" =>
            recommendation["duplicate_contact_candidate_count"],
          "selection_reason" => recommendation["selection_reason"],
          "resolution_selection_rule" => recommendation["resolution_selection_rule"],
          "resolution_priority_fields" => recommendation["resolution_priority_fields"],
          "requested_priority_fields" => recommendation["requested_priority_fields"],
          "priority_field_evidence_counts" => recommendation["priority_field_evidence_counts"],
          "priority_fields_without_numeric_evidence_count" =>
            recommendation["priority_fields_without_numeric_evidence_count"],
          "priority_fields_without_numeric_evidence" =>
            recommendation["priority_fields_without_numeric_evidence"],
          "resolution_priority_override_count" =>
            recommendation["resolution_priority_override_count"],
          "resolution_priority_override_contact_ids" =>
            recommendation["resolution_priority_override_contact_ids"],
          "resolution_tie_breakers" => recommendation["resolution_tie_breakers"],
          "requested_selection_rule" => recommendation["requested_selection_rule"],
          "ignored_tie_breakers" => recommendation["ignored_tie_breakers"],
          "ignored_policy_input" => recommendation["ignored_policy_input"],
          "policy_warnings" => recommendation["policy_warnings"]
        }
        |> Map.merge(Map.take(recommendation, contact_feedback_fields()))
        |> Map.merge(Map.take(recommendation, station_calendar_context_fields()))
        |> compact_map()
    }
    |> compact_map()
  end

  defp contention_requirement_type(row) do
    cond do
      command_contact_contention?(row) -> "command_review"
      health_check_contact_contention?(row) -> "health_check_review"
      true -> "contact_schedule_change"
    end
  end

  defp contention_requirement_reason(row) do
    cond do
      command_contact_contention?(row) ->
        "command contact contention requires operator review"

      health_check_contact_contention?(row) ->
        "health-check contact contention requires operator review"

      true ->
        row["operator_action_reason"]
    end
  end

  defp contention_resolution_requirement_reason(recommendation) do
    if recommendation["resource_scope"] == "spacecraft" do
      spacecraft = Map.get(recommendation, "spacecraft_id", "spacecraft")
      "resolve #{spacecraft} spacecraft contact contention"
    else
      station = Map.get(recommendation, "ground_station_id", "station")

      cond do
        command_contact_contention?(recommendation) ->
          "resolve #{station} command contact contention"

        health_check_contact_contention?(recommendation) ->
          "resolve #{station} health-check contact contention"

        true ->
          "resolve #{station} contact contention"
      end
    end
  end

  defp command_contact_contention?(row) do
    row["direction"] in @command_contact_directions or
      row
      |> Map.get("directions", [])
      |> List.wrap()
      |> Enum.any?(&(&1 in @command_contact_directions))
  end

  defp health_check_contact_contention?(row) do
    row["direction"] in @health_check_contact_directions or row["type"] == "health_check" or
      row
      |> Map.get("directions", [])
      |> List.wrap()
      |> Enum.any?(&(&1 in @health_check_contact_directions))
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

  defp normalize_priority_overrides(policy) do
    {priority_overrides, ignored_override_context} =
      policy
      |> raw_priority_overrides()
      |> normalized_priority_overrides()

    policy =
      if map_size(priority_overrides) == 0 do
        policy
      else
        Map.put(policy, "priority_overrides", priority_overrides)
      end

    Map.merge(policy, ignored_override_context)
  end

  defp raw_priority_overrides(policy) do
    Enum.find_value(@resolution_priority_override_aliases, &Map.get(policy, &1)) || %{}
  end

  defp normalized_priority_overrides(%{} = overrides) do
    {priority_overrides, ignored_keys, ignored_contact_ids} =
      Enum.reduce(overrides, {%{}, [], []}, fn {raw_id, raw_priority},
                                               {priority_overrides, ignored_keys,
                                                ignored_contact_ids} ->
        contact_id = stable_id_or_nil(raw_id)
        priority = numeric_or_nil(raw_priority)

        if is_binary(contact_id) and is_number(priority) do
          {Map.put(priority_overrides, contact_id, priority), ignored_keys, ignored_contact_ids}
        else
          ignored_key = encode_value(raw_id) || inspect(raw_id, limit: 20)

          ignored_contact_ids =
            if is_binary(contact_id),
              do: [contact_id | ignored_contact_ids],
              else: ignored_contact_ids

          {priority_overrides, [ignored_key | ignored_keys], ignored_contact_ids}
        end
      end)

    ignored_context =
      ignored_priority_override_context(ignored_keys, ignored_contact_ids, nil)

    {priority_overrides, ignored_context}
  end

  defp normalized_priority_overrides(overrides) do
    {%{}, ignored_priority_override_context([], [], inspect(overrides, limit: 20))}
  end

  defp ignored_priority_override_context(ignored_keys, ignored_contact_ids, ignored_input) do
    ignored_keys =
      ignored_keys
      |> Enum.map(&encode_value/1)
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()

    ignored_contact_ids =
      ignored_contact_ids
      |> Enum.uniq()
      |> Enum.sort()

    ignored_count = length(ignored_keys) + if(is_nil(ignored_input), do: 0, else: 1)

    %{
      "ignored_priority_override_count" => if(ignored_count == 0, do: nil, else: ignored_count),
      "ignored_priority_override_keys" => if(ignored_keys == [], do: nil, else: ignored_keys),
      "ignored_priority_override_contact_ids" =>
        if(ignored_contact_ids == [], do: nil, else: ignored_contact_ids),
      "ignored_priority_override_input" => ignored_input
    }
    |> compact_map()
  end

  defp priority_override_count(policy), do: map_size(Map.get(policy, "priority_overrides", %{}))

  defp ignored_priority_override_count(policy),
    do: Map.get(policy, "ignored_priority_override_count", 0)

  defp priority_overrides(policy) do
    case Map.get(policy, "priority_overrides", %{}) do
      overrides when map_size(overrides) == 0 -> nil
      overrides -> overrides
    end
  end

  defp priority_override_contact_ids(policy) do
    policy
    |> Map.get("priority_overrides", %{})
    |> Map.keys()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp ignored_priority_override_keys(policy),
    do: Map.get(policy, "ignored_priority_override_keys")

  defp ignored_priority_override_contact_ids(policy),
    do: Map.get(policy, "ignored_priority_override_contact_ids")

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

  defp actual_throughput_value(contact) do
    explicit_actual_throughput_value(contact) || actual_data_rate_derived_throughput_mb(contact)
  end

  defp explicit_actual_throughput_value(contact) do
    first_number([
      contact["actual_throughput_mb"],
      contact["actual_downlink_mb"],
      contact["actual_data_volume_mb"],
      contact["delivered_data_mb"],
      contact["received_data_mb"],
      get_in(contact, ["throughput_model", "actual_throughput_mb"]),
      get_in(contact, ["throughput_model", "actual_downlink_mb"]),
      get_in(contact, ["throughput_model", "actual_data_volume_mb"]),
      get_in(contact, ["throughput_model", "delivered_data_mb"]),
      get_in(contact, ["throughput_model", "received_data_mb"])
    ])
  end

  defp actual_data_rate_derived_throughput_mb(contact) do
    case actual_data_rate_throughput_derivation(contact) do
      %{"actual_throughput_mb" => actual_throughput_mb} when is_number(actual_throughput_mb) ->
        actual_throughput_mb

      _derivation ->
        nil
    end
  end

  defp actual_data_rate_throughput_derivation(contact) do
    duration_s = actual_duration_s(contact)

    cond do
      is_number(explicit_actual_throughput_value(contact)) ->
        nil

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

  defp actual_data_rate_mb_s(contact) do
    first_number([
      contact["actual_data_rate_mb_s"],
      contact["actual_downlink_rate_mb_s"],
      contact["delivered_rate_mb_s"],
      contact["received_rate_mb_s"],
      get_in(contact, ["throughput_model", "actual_data_rate_mb_s"]),
      get_in(contact, ["throughput_model", "actual_downlink_rate_mb_s"]),
      get_in(contact, ["throughput_model", "delivered_rate_mb_s"]),
      get_in(contact, ["throughput_model", "received_rate_mb_s"])
    ])
  end

  defp actual_data_rate_mbps(contact) do
    first_number([
      contact["actual_data_rate_mbps"],
      contact["actual_downlink_rate_mbps"],
      contact["delivered_rate_mbps"],
      contact["received_rate_mbps"],
      get_in(contact, ["throughput_model", "actual_data_rate_mbps"]),
      get_in(contact, ["throughput_model", "actual_downlink_rate_mbps"]),
      get_in(contact, ["throughput_model", "delivered_rate_mbps"]),
      get_in(contact, ["throughput_model", "received_rate_mbps"])
    ])
  end

  defp actual_duration_s(contact) do
    first_number([
      contact["actual_duration_s"],
      contact["actual_contact_duration_s"],
      get_in(contact, ["throughput_model", "actual_duration_s"]),
      get_in(contact, ["throughput_model", "actual_contact_duration_s"])
    ]) || contact_duration_s(contact)
  end

  defp contact_duration_s(contact) do
    first_number([
      contact["duration_s"],
      contact["contact_duration_s"],
      contact["scheduled_duration_s"],
      get_in(contact, ["throughput_model", "duration_s"]),
      get_in(contact, ["throughput_model", "contact_duration_s"]),
      get_in(contact, ["throughput_model", "scheduled_duration_s"])
    ]) || interval_duration_s(contact)
  end

  defp interval_duration_s(contact) do
    starts_at_s = numeric_or_nil(contact["starts_at_s"])
    ends_at_s = numeric_or_nil(contact["ends_at_s"])

    if is_number(starts_at_s) and is_number(ends_at_s) do
      ends_at_s - starts_at_s
    end
  end

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

  defp contact_spacecraft_id(contact) do
    spacecraft_identity_value(contact["spacecraft_id"]) ||
      spacecraft_identity_value(contact["satellite_id"]) ||
      spacecraft_identity_value(contact["spacecraft"]) ||
      spacecraft_identity_value(contact["satellite"]) ||
      stable_id_or_nil(contact["scenario_id"])
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: stable_id_or_nil(value)

  defp group_ground_station_ids(contacts) do
    contacts
    |> Enum.map(&stable_id_or_nil(&1["ground_station_id"]))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp group_spacecraft_ids(contacts) do
    contacts
    |> Enum.map(&contact_spacecraft_id/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp group_stable_ids(contacts, field) do
    contacts
    |> Enum.map(&stable_id_or_nil(&1[field]))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp group_ground_station_id([ground_station_id]), do: ground_station_id
  defp group_ground_station_id(_ground_station_ids), do: "multi_station"

  defp group_direction(contacts) do
    case group_directions(contacts) do
      [direction] -> direction
      [] -> "downlink"
      _directions -> "mixed"
    end
  end

  defp group_directions(contacts) do
    contacts
    |> Enum.map(&contact_direction/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp contact_direction(%{"direction" => direction})
       when is_binary(direction) and direction != "",
       do: direction

  defp contact_direction(%{"type" => "command"}), do: "command"
  defp contact_direction(%{"type" => "tracking"}), do: "tracking"
  defp contact_direction(%{"type" => "health_check"}), do: "health_check"
  defp contact_direction(_contact), do: "downlink"

  defp contact_id(nil), do: nil

  defp contact_id(contact) do
    case contact_id_or_nil(contact) do
      value when is_binary(value) and value != "" -> value
      _value -> raise ArgumentError, "contact id is required"
    end
  end

  defp contact_id_or_nil(nil), do: nil

  defp contact_id_or_nil(contact) do
    case Map.get(contact, "id") || Map.get(contact, "contact_id") ||
           Map.get(contact, "activity_id") do
      value when is_binary(value) and value != "" -> stable_id_or_nil(value)
      value when is_atom(value) and not is_nil(value) -> stable_id_or_nil(value)
      value when is_integer(value) -> stable_id_or_nil(value)
      _value -> nil
    end
  end

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

  defp canonical_contact_sort_key(contact) do
    {
      numeric_or_zero(contact["starts_at_s"]),
      numeric_or_zero(contact["ends_at_s"]),
      contact_id_or_nil(contact) || "",
      stable_id_or_nil(contact["scenario_id"]) || "",
      contact_spacecraft_id(contact) || "",
      stable_id_or_nil(contact["ground_station_id"]) || "",
      stable_id_or_nil(contact["source_window_id"]) || "",
      stable_id_or_nil(contact["station_calendar_provider_id"]) || "",
      stable_id_or_nil(contact["station_calendar_provider_entry_id"]) || "",
      contact_direction(contact)
    }
  end

  defp numeric_or_zero(value), do: numeric_or_nil(value) || 0.0

  defp first_number(values), do: Enum.find_value(values, &numeric_or_nil/1)

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp normalize_contact(%{} = contact) do
    contact
    |> stringify_keys()
    |> normalize_station_id()
    |> normalize_contact_time("starts_at_s", "start_s")
    |> normalize_contact_time("ends_at_s", "end_s")
    |> normalize_contact_numeric_fields()
    |> normalize_station_calendar_status_fields()
    |> normalize_activity_type_alias()
    |> normalize_contact_direction()
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

  defp normalize_station_calendar_status_fields(contact) do
    contact
    |> normalize_status_field("availability")
    |> normalize_status_field("status")
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("station_contention_status")
    |> normalize_status_field("reservation_status")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("reservation_match_status")
    |> normalize_status_field("station_reservation_match_status")
    |> normalize_status_list_field("station_calendar_overlap_availabilities")
    |> normalize_status_list_field("station_calendar_reservation_statuses")
    |> normalize_source_station_calendar_field("source_station_calendar_entry")
    |> normalize_source_station_calendar_field("source_station_calendar_overlaps")
  end

  defp normalize_status_field(contact, field) do
    case Map.fetch(contact, field) do
      {:ok, value} when value in [nil, ""] ->
        contact

      {:ok, value} ->
        Map.put(contact, field, normalized_status_token(value))

      :error ->
        contact
    end
  end

  defp normalize_status_list_field(contact, field) do
    case Map.fetch(contact, field) do
      {:ok, values} when is_list(values) ->
        values =
          values
          |> Enum.map(&normalized_status_token/1)
          |> Enum.reject(&(&1 in [nil, ""]))

        Map.put(contact, field, values)

      {:ok, value} when value not in [nil, ""] ->
        Map.put(contact, field, [normalized_status_token(value)])

      _missing_or_empty ->
        contact
    end
  end

  defp normalize_source_station_calendar_field(contact, field) do
    case Map.fetch(contact, field) do
      {:ok, values} when is_list(values) ->
        Map.put(contact, field, Enum.map(values, &normalize_source_station_calendar/1))

      {:ok, value} ->
        Map.put(contact, field, normalize_source_station_calendar(value))

      :error ->
        contact
    end
  end

  defp normalize_source_station_calendar(%{} = source),
    do: normalize_station_calendar_status_fields(source)

  defp normalize_source_station_calendar(value), do: value

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

  defp normalize_contact_time(contact, canonical_key, alternate_key) do
    case first_number([Map.get(contact, canonical_key), Map.get(contact, alternate_key)]) do
      nil -> contact
      value -> Map.put(contact, canonical_key, value)
    end
  end

  defp normalize_contact_numeric_fields(contact) do
    ["score" | @default_resolution_priority_fields]
    |> Enum.uniq()
    |> Enum.reduce(contact, &normalize_contact_numeric_field(&2, &1))
  end

  defp normalize_contact_numeric_field(contact, field) do
    case Map.fetch(contact, field) do
      {:ok, value} ->
        case numeric_or_nil(value) do
          number when is_number(number) -> Map.put(contact, field, number)
          _value -> contact
        end

      :error ->
        contact
    end
  end

  defp normalize_activity_type_alias(%{"type" => type} = contact) when not is_nil(type),
    do: contact

  defp normalize_activity_type_alias(%{"activity_type" => type} = contact)
       when is_binary(type) and type != "",
       do: Map.put(contact, "type", type)

  defp normalize_activity_type_alias(contact), do: contact

  defp normalize_contact_direction(%{"direction" => direction} = contact) do
    case normalize_direction(direction) do
      nil -> contact
      direction -> Map.put(contact, "direction", direction)
    end
  end

  defp normalize_contact_direction(%{"type" => "downlink"} = contact),
    do: Map.put(contact, "direction", "downlink")

  defp normalize_contact_direction(%{"type" => "tracking"} = contact),
    do: Map.put(contact, "direction", "tracking")

  defp normalize_contact_direction(%{"type" => "command"} = contact),
    do: Map.put(contact, "direction", "command")

  defp normalize_contact_direction(%{"type" => "health_check"} = contact),
    do: Map.put(contact, "direction", "health_check")

  defp normalize_contact_direction(contact), do: contact

  defp normalize_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_direction(direction) do
    direction
    |> encode_value()
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
      value -> Map.get(@provider_direction_aliases, value, value)
    end
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key

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

  defp encode_value(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 6)
  defp encode_value(value), do: to_string(value)
end
