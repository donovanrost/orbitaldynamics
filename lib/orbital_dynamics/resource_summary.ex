defmodule OrbitalDynamics.ResourceSummary do
  @moduledoc """
  Thin planning-grade spacecraft resource summary.

  This is not a subsystem simulator. It normalizes externally supplied resource
  state into deterministic artifact rows that planners can score and Cadence can
  inspect without implying higher fidelity than the source supports.
  """

  @enforce_keys [:spacecraft_id]
  @derived_margin_tolerance 1.0e-9
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @resource_availability_aliases %{
    "payload_available" => ["payload_available?", "payload_status"],
    "antenna_available" => ["antenna_available?", "antenna_status"],
    "spacecraft_available" => [
      "spacecraft_available?",
      "spacecraft_availability",
      "spacecraft_status"
    ]
  }
  @resource_degraded_aliases ["degraded?"]
  @resource_margin_aliases %{
    "storage_margin" => ["storage_capacity_margin"],
    "downlink_margin" => ["downlink_capacity_margin"]
  }
  @resource_unit_interval_aliases %{
    "battery_state_of_charge" => ["battery_soc"]
  }
  @battery_energy_generated_aliases [
    "energy_generated_wh",
    "estimated_energy_generated_wh",
    "estimated_battery_energy_generated_wh",
    "planned_energy_generated_wh"
  ]
  @roll_forward_flow_statuses ~w(clear review_required)
  @roll_forward_pressure_statuses ~w(clear review_required)
  @roll_forward_pressure_types ~w(
    activity_type_incompatible_with_resource_summary
    activity_type_suppressed_by_resource_summary
    antenna_unavailable
    battery_depletion
    downlink_shortfall
    payload_unavailable
    spacecraft_degraded_payload_unavailable
    spacecraft_unavailable
    storage_overflow
    thermal_margin_below_limit
  )
  @roll_forward_resource_effect_statuses ~w(projected ignored)
  @roll_forward_ignored_effect_reason_families [
    "activity_status_*",
    "approval_status_rejected",
    "contact_allocation_*",
    "activity_type_suppressed_by_resource_summary",
    "activity_type_incompatible_with_resource_summary",
    "spacecraft_unavailable",
    "payload_unavailable",
    "spacecraft_degraded_payload_unavailable",
    "antenna_unavailable"
  ]
  @spacecraft_stable_identity_fields ~w(
    spacecraft_id
    satellite_id
    spacecraft.spacecraft_id
    spacecraft.satellite_id
    spacecraft.id
    satellite.spacecraft_id
    satellite.satellite_id
    satellite.id
  )
  @availability_true_tokens ~w(true yes y available nominal operational enabled 1)
  @availability_false_tokens ~w(false no n unavailable offline down outage maintenance disabled 0)
  @resource_activity_type_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "command",
    "up" => "command",
    "up_link" => "command",
    "uplink_command" => "command",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "down_link" => "downlink",
    "x_band_downlink" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }
  defstruct [
    :spacecraft_id,
    :mode,
    :fuel_margin,
    :power_margin,
    :battery_capacity_wh,
    :battery_energy_used_wh,
    :battery_energy_generated_wh,
    :battery_state_of_charge,
    :thermal_margin_c,
    :storage_capacity_mb,
    :storage_used_mb,
    :storage_margin,
    :downlink_capacity_mb,
    :downlink_margin,
    :spacecraft_available?,
    :source_quality,
    :trust_boundary,
    :suppressed_activity_types,
    :incompatible_activity_types,
    payload_available?: true,
    antenna_available?: true,
    degraded?: false,
    assumptions: %{},
    provenance: %{}
  ]

  @doc """
  Declares the planning-grade resource model and known limits.
  """
  def capabilities do
    %{
      product: :resource_summary,
      model: :externally_supplied_planning_resource_summary,
      validation_level: :assumption_declared,
      units: %{
        storage_capacity_mb: :megabytes,
        storage_used_mb: :megabytes,
        downlink_capacity_mb: :megabytes,
        battery_capacity_wh: :watt_hours,
        battery_energy_used_wh: :watt_hours,
        battery_energy_generated_wh: :watt_hours,
        thermal_margin_c: :celsius,
        margins: :unit_interval
      },
      known_limits: [
        :no_subsystem_simulation,
        :no_resource_time_propagation,
        :battery_state_of_charge_is_externally_supplied_or_derived_summary,
        :no_link_budget_model,
        :source_quality_is_declared_or_inferred_from_provenance
      ],
      source_quality_aliases: [
        "source_quality",
        "resource_source_quality",
        "provenance.source_quality",
        "provenance.resource_source_quality",
        "provenance.quality"
      ],
      trust_boundary_aliases: [
        "trust_boundary",
        "resource_trust_boundary",
        "provenance.trust_boundary",
        "provenance.resource_trust_boundary"
      ],
      spacecraft_stable_identity_fields: @spacecraft_stable_identity_fields,
      resource_availability_aliases: @resource_availability_aliases,
      resource_degraded_aliases: @resource_degraded_aliases,
      resource_margin_aliases: @resource_margin_aliases,
      resource_unit_interval_aliases: @resource_unit_interval_aliases,
      battery_energy_generated_aliases: @battery_energy_generated_aliases,
      resource_availability_true_tokens: @availability_true_tokens,
      resource_availability_false_tokens: @availability_false_tokens,
      resource_activity_type_aliases: @resource_activity_type_aliases,
      roll_forward_flow_statuses: @roll_forward_flow_statuses,
      roll_forward_pressure_statuses: @roll_forward_pressure_statuses,
      roll_forward_pressure_types: @roll_forward_pressure_types,
      roll_forward_resource_effect_statuses: @roll_forward_resource_effect_statuses,
      roll_forward_ignored_effect_reason_families: @roll_forward_ignored_effect_reason_families,
      roll_forward_helpers: [:roll_forward],
      roll_forward_contract: %{
        input_contracts: ["resource_summary.v1", "selected_activity_rows"],
        output_contract: "resource_projection_flow_summary.v1",
        validation_level: :schema_validated_artifact,
        boundary: :thin_selected_activity_projection,
        model: :resource_projection_flow_report,
        execution_boundary: :artifact_only_no_schedule_mutation
      },
      public_facades: [:resource_summary_roll_forward],
      activity_type_list_fields: [
        "suppressed_activity_types",
        "incompatible_activity_types"
      ],
      row_semantics: [
        :spacecraft_stable_identity_fields,
        :resource_source_quality_aliases,
        :resource_trust_boundary_aliases,
        :resource_activity_type_list_fields,
        :resource_availability_aliases,
        :resource_availability_status_tokens,
        :resource_degraded_aliases,
        :resource_margin_aliases,
        :resource_unit_interval_aliases,
        :battery_energy_generated_aliases,
        :resource_activity_type_aliases,
        :selected_activity_resource_roll_forward,
        :resource_summary_roll_forward_flow_status_values,
        :resource_summary_roll_forward_pressure_status_values,
        :resource_summary_roll_forward_pressure_type_values,
        :resource_summary_roll_forward_resource_effect_status_values,
        :resource_summary_roll_forward_ignored_effect_reason_families,
        :thin_selected_activity_roll_forward_contract
      ]
    }
  end

  @doc """
  Builds a summary from string-keyed or atom-keyed map data.
  """
  def from_map!(source) when is_map(source) do
    source =
      source
      |> stringify_keys()
      |> put_spacecraft_alias()

    spacecraft_id =
      source
      |> required!("spacecraft_id")
      |> normalize_spacecraft_id!()

    battery_capacity_wh =
      non_negative_number_or_nil(source["battery_capacity_wh"], "battery_capacity_wh")

    battery_energy_used_wh =
      non_negative_number_or_nil(source["battery_energy_used_wh"], "battery_energy_used_wh")

    battery_energy_generated_wh =
      source
      |> field_or_alias_value("battery_energy_generated_wh", @battery_energy_generated_aliases)
      |> non_negative_number_or_nil("battery_energy_generated_wh")

    storage_capacity_mb =
      non_negative_number_or_nil(source["storage_capacity_mb"], "storage_capacity_mb")

    storage_used_mb = non_negative_number_or_nil(source["storage_used_mb"], "storage_used_mb")

    battery_state_of_charge =
      margin_or_derived(
        field_or_alias_value(
          source,
          "battery_state_of_charge",
          @resource_unit_interval_aliases["battery_state_of_charge"]
        ),
        battery_capacity_wh,
        battery_energy_used_wh,
        "battery_state_of_charge"
      )

    %__MODULE__{
      spacecraft_id: spacecraft_id,
      mode: source["mode"],
      fuel_margin: margin_or_nil(source["fuel_margin"], "fuel_margin"),
      power_margin:
        margin_or_nil(source["power_margin"] || battery_state_of_charge, "power_margin"),
      battery_capacity_wh: battery_capacity_wh,
      battery_energy_used_wh: battery_energy_used_wh,
      battery_energy_generated_wh: battery_energy_generated_wh,
      battery_state_of_charge: battery_state_of_charge,
      thermal_margin_c: number_or_nil(source["thermal_margin_c"], "thermal_margin_c"),
      storage_capacity_mb: storage_capacity_mb,
      storage_used_mb: storage_used_mb,
      storage_margin:
        margin_or_derived(
          field_or_alias_value(
            source,
            "storage_margin",
            @resource_margin_aliases["storage_margin"]
          ),
          storage_capacity_mb,
          storage_used_mb,
          "storage_margin"
        ),
      downlink_capacity_mb:
        non_negative_number_or_nil(source["downlink_capacity_mb"], "downlink_capacity_mb"),
      downlink_margin:
        margin_alias(source, "downlink_margin", @resource_margin_aliases["downlink_margin"]),
      spacecraft_available?:
        optional_boolean_alias(
          source,
          "spacecraft_available",
          Map.fetch!(@resource_availability_aliases, "spacecraft_available")
        ),
      source_quality: source_quality(source),
      trust_boundary: trust_boundary(source),
      suppressed_activity_types:
        activity_type_list_or_nil(
          source["suppressed_activity_types"],
          "suppressed_activity_types"
        ),
      incompatible_activity_types:
        activity_type_list_or_nil(
          source["incompatible_activity_types"],
          "incompatible_activity_types"
        ),
      payload_available?:
        boolean_alias(
          source,
          "payload_available",
          Map.fetch!(@resource_availability_aliases, "payload_available"),
          true
        ),
      antenna_available?:
        boolean_alias(
          source,
          "antenna_available",
          Map.fetch!(@resource_availability_aliases, "antenna_available"),
          true
        ),
      degraded?:
        boolean_alias(
          source,
          "degraded",
          @resource_degraded_aliases,
          source["mode"] in ["degraded", "degraded_mode"]
        ),
      assumptions: map_or_empty(source["assumptions"], "assumptions"),
      provenance: map_or_empty(source["provenance"], "provenance")
    }
  end

  def from_map!(_source), do: raise(ArgumentError, "resource summary must be a map")

  defp put_spacecraft_alias(%{} = source) do
    case spacecraft_identity_value(Map.get(source, "spacecraft_id")) ||
           spacecraft_identity_value(Map.get(source, "satellite_id")) ||
           nested_spacecraft_id(source) do
      value when value in [nil, ""] -> source
      value -> Map.put(source, "spacecraft_id", value)
    end
  end

  defp nested_spacecraft_id(source) do
    Enum.find_value(["spacecraft", "satellite"], fn field ->
      spacecraft_identity_value(Map.get(source, field))
    end)
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value) when is_atom(value) and not is_nil(value),
    do: Atom.to_string(value)

  defp spacecraft_identity_value(value) when is_integer(value), do: Integer.to_string(value)

  defp spacecraft_identity_value(value), do: value

  defp normalize_spacecraft_id!(spacecraft_id) do
    if stable_id?(spacecraft_id) do
      spacecraft_id
    else
      raise ArgumentError,
            "spacecraft_id must be a stable ID matching #{@stable_id_pattern.source}"
    end
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(_value), do: false

  @doc """
  Converts one or more summaries to JSON-serializable maps.
  """
  def to_map(%__MODULE__{} = summary) do
    spacecraft_id =
      summary.spacecraft_id
      |> spacecraft_identity_value()
      |> normalize_spacecraft_id!()

    %{
      "schema_contract" => "resource_summary.v1",
      "spacecraft_id" => spacecraft_id,
      "mode" => summary.mode,
      "fuel_margin" => summary.fuel_margin,
      "power_margin" => summary.power_margin,
      "battery_capacity_wh" => summary.battery_capacity_wh,
      "battery_energy_used_wh" => summary.battery_energy_used_wh,
      "battery_energy_generated_wh" => summary.battery_energy_generated_wh,
      "battery_state_of_charge" => summary.battery_state_of_charge,
      "thermal_margin_c" => summary.thermal_margin_c,
      "storage_capacity_mb" => summary.storage_capacity_mb,
      "storage_used_mb" => summary.storage_used_mb,
      "storage_margin" => summary.storage_margin,
      "downlink_capacity_mb" => summary.downlink_capacity_mb,
      "downlink_margin" => summary.downlink_margin,
      "spacecraft_available" => summary.spacecraft_available?,
      "source_quality" => summary.source_quality,
      "trust_boundary" => summary.trust_boundary,
      "suppressed_activity_types" => summary.suppressed_activity_types,
      "incompatible_activity_types" => summary.incompatible_activity_types,
      "payload_available" => summary.payload_available?,
      "antenna_available" => summary.antenna_available?,
      "degraded" => summary.degraded?,
      "assumptions" => summary.assumptions,
      "provenance" => summary.provenance
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def to_maps(summaries) when is_list(summaries) do
    Enum.map(summaries, fn
      %__MODULE__{} = summary -> to_map(summary)
      %{} = summary -> summary |> from_map!() |> to_map()
    end)
  end

  @doc """
  Projects one resource summary across selected activities.

  This is a convenience boundary over the schema-validated
  `ResourceProjection.flow_report/3` roll-forward model. It normalizes the
  summary through `resource_summary.v1`, then returns compact storage/downlink
  flow evidence without mutating schedules, reconciling realized state, or
  claiming Cadence import authority.
  """
  def roll_forward(summary, selected_activities, opts \\ [])

  def roll_forward(summary, selected_activities, opts)
      when is_list(selected_activities) and is_list(opts) do
    summary
    |> roll_forward_summary_map()
    |> then(fn summary_map ->
      OrbitalDynamics.ResourceProjection.flow_report(selected_activities, [summary_map], opts)
    end)
  end

  def roll_forward(_summary, selected_activities, _opts) when not is_list(selected_activities),
    do: raise(ArgumentError, "selected activities must be a list")

  def roll_forward(_summary, _selected_activities, _opts),
    do: raise(ArgumentError, "roll-forward options must be a keyword list")

  defp roll_forward_summary_map(%__MODULE__{} = summary), do: to_map(summary)

  defp roll_forward_summary_map(%{} = summary) do
    summary
    |> from_map!()
    |> to_map()
  end

  defp roll_forward_summary_map(_summary),
    do: raise(ArgumentError, "resource summary must be a map or ResourceSummary struct")

  defp required!(map, key) do
    case Map.get(map, key) do
      value when value in [nil, ""] -> raise ArgumentError, "#{key} is required"
      value -> value
    end
  end

  defp margin_or_nil(nil, _field), do: nil

  defp margin_or_nil(value, field) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 ->
        value

      value when is_number(value) ->
        raise ArgumentError, "#{field} must be between 0 and 1"

      _value ->
        raise ArgumentError, "#{field} must be numeric"
    end
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp field_or_alias_value(source, key, aliases) do
    if Map.has_key?(source, key) do
      Map.get(source, key)
    else
      case Enum.find(aliases, &Map.has_key?(source, &1)) do
        nil -> nil
        alias_key -> Map.get(source, alias_key)
      end
    end
  end

  defp margin_alias(source, key, aliases) do
    source
    |> field_or_alias_value(key, aliases)
    |> margin_or_nil(key)
  end

  defp margin_or_derived(nil, capacity, used, _field)
       when is_number(capacity) and capacity > 0 and is_number(used) do
    derived_margin(capacity, used)
  end

  defp margin_or_derived(value, capacity, used, field) do
    value
    |> margin_or_nil(field)
    |> validate_derived_margin!(capacity, used, field)
  end

  defp validate_derived_margin!(margin, capacity, used, field)
       when is_number(margin) and is_number(capacity) and capacity > 0 and is_number(used) do
    expected = derived_margin(capacity, used)

    if abs(margin - expected) <= @derived_margin_tolerance do
      margin
    else
      raise ArgumentError, "#{field} must match capacity and used values"
    end
  end

  defp validate_derived_margin!(margin, _capacity, _used, _field), do: margin

  defp derived_margin(capacity, used), do: max((capacity - used) / capacity, 0.0)

  defp non_negative_number_or_nil(nil, _field), do: nil

  defp non_negative_number_or_nil(value, field) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 ->
        value

      value when is_number(value) ->
        raise ArgumentError, "#{field} must be non-negative"

      _value ->
        raise ArgumentError, "resource numeric fields must be numeric"
    end
  end

  defp number_or_nil(nil, _field), do: nil

  defp number_or_nil(value, field) do
    case numeric_or_nil(value) do
      value when is_number(value) ->
        value

      _value ->
        raise ArgumentError, "#{field} must be numeric"
    end
  end

  defp source_quality(source) do
    explicit_quality =
      source["source_quality"] ||
        source["resource_source_quality"] ||
        get_in(source, ["provenance", "source_quality"]) ||
        get_in(source, ["provenance", "resource_source_quality"]) ||
        get_in(source, ["provenance", "quality"])

    case explicit_quality do
      value when is_binary(value) and value != "" ->
        value

      nil ->
        infer_source_quality(
          get_in(source, ["provenance", "source"]) || get_in(source, ["provenance", "system"])
        )

      _value ->
        raise ArgumentError, "source_quality must be a string"
    end
  end

  defp infer_source_quality(source) when source in [nil, ""], do: "unknown"

  defp infer_source_quality(source) when is_binary(source) do
    cond do
      source in [
        "cadence_snapshot",
        "operator_import",
        "operator_planning_input",
        "operator_summary",
        "ops",
        "ops_snapshot"
      ] ->
        "operator_supplied"

      String.contains?(source, "simulat") ->
        "simulated"

      true ->
        "declared"
    end
  end

  defp infer_source_quality(_source), do: "unknown"

  defp trust_boundary(source) do
    case source["trust_boundary"] ||
           source["resource_trust_boundary"] ||
           get_in(source, ["provenance", "trust_boundary"]) ||
           get_in(source, ["provenance", "resource_trust_boundary"]) do
      nil -> nil
      boundary when is_binary(boundary) and boundary != "" -> boundary
      _value -> raise ArgumentError, "trust_boundary must be a non-empty string"
    end
  end

  defp activity_type_list_or_nil(nil, _field), do: nil

  defp activity_type_list_or_nil(value, field) do
    value
    |> List.wrap()
    |> Enum.flat_map(&activity_type_list_entry(&1, field))
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp activity_type_list_entry(nil, _field), do: []

  defp activity_type_list_entry(value, field) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&normalize_activity_type_token/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> raise ArgumentError, "#{field} entries must be non-empty strings"
      values -> values
    end
  end

  defp activity_type_list_entry(value, field) when is_atom(value) do
    value
    |> Atom.to_string()
    |> activity_type_list_entry(field)
  end

  defp activity_type_list_entry(%{} = value, field) do
    value = stringify_keys(value)

    entry = value["type"] || value["activity_type"] || value["direction"]

    case entry do
      nil -> raise ArgumentError, "#{field} map entries require type, activity_type, or direction"
      entry -> activity_type_list_entry(entry, field)
    end
  end

  defp activity_type_list_entry(_value, field) do
    raise ArgumentError, "#{field} entries must be strings, atoms, or typed maps"
  end

  defp normalize_activity_type_token(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      token when is_map_key(@resource_activity_type_aliases, token) ->
        Map.fetch!(@resource_activity_type_aliases, token)

      value ->
        value
    end
  end

  defp boolean(source, key, default) do
    case Map.get(source, key, default) do
      value when is_boolean(value) -> value
      value when value in [1] -> true
      value when value in [0] -> false
      value when is_binary(value) -> status_boolean(value, key)
      _value -> raise ArgumentError, "#{key} must be a boolean"
    end
  end

  defp boolean_alias(source, key, aliases, default) do
    value =
      if Map.has_key?(source, key) do
        Map.get(source, key)
      else
        case Enum.find(aliases, &Map.has_key?(source, &1)) do
          nil -> default
          alias_key -> Map.get(source, alias_key)
        end
      end

    boolean(%{key => value}, key, default)
  end

  defp optional_boolean_alias(source, key, aliases) do
    value =
      if Map.has_key?(source, key) do
        Map.get(source, key)
      else
        aliases
        |> Enum.find(&Map.has_key?(source, &1))
        |> case do
          nil -> nil
          alias_key -> Map.get(source, alias_key)
        end
      end

    case value do
      nil -> nil
      value when is_boolean(value) -> value
      value when value in [1] -> true
      value when value in [0] -> false
      value when is_binary(value) -> status_boolean(value, key)
      _value -> raise ArgumentError, "#{key} must be a boolean"
    end
  end

  defp status_boolean(value, key) do
    case String.downcase(String.trim(value)) do
      value when value in @availability_true_tokens -> true
      value when value in @availability_false_tokens -> false
      _value -> raise ArgumentError, "#{key} must be a boolean"
    end
  end

  defp map_or_empty(nil, _field), do: %{}
  defp map_or_empty(%{} = value, _field), do: stringify_keys(value)
  defp map_or_empty(_value, field), do: raise(ArgumentError, "#{field} must be a map")

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
