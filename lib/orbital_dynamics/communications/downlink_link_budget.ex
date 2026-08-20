defmodule OrbitalDynamics.Communications.DownlinkLinkBudget do
  @moduledoc """
  Deterministic point-geometry budgets for one fixed one-way downlink mode.

  The caller supplies the contact/access-window binding, one slant-range and
  elevation sample, both terminal definitions, RF/noise/loss inputs, bandwidth,
  coding/modulation efficiency, and margin policy within the published finite
  LEO ground-downlink engineering envelopes. The resulting artifact is
  evidence only: it does not recompute access geometry, select another mode,
  reserve a provider contact, calibrate hidden losses, or mutate a schedule.
  """

  alias OrbitalDynamics.Optimizer.CandidateBinding

  @schema_contract "downlink_link_budget.v1"
  @model "deterministic_point_one_way_downlink_budget"
  @supported_mode "fixed_single_carrier"
  @speed_of_light_m_s 299_792_458.0
  @boltzmann_constant_w_hz_k 1.380649e-23
  @megabyte_bits 8_000_000.0
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @maximum_finite_float 1.7976931348623157e308
  @maximum_time_s 1.0e12
  @input_envelopes %{
    "time_s" => %{"minimum" => 0.0, "maximum" => @maximum_time_s},
    "slant_range_km" => %{"minimum" => 100.0, "maximum" => 6_000.0},
    "carrier_frequency_hz" => %{"minimum" => 100.0e6, "maximum" => 100.0e9},
    "occupied_bandwidth_hz" => %{"minimum" => 1.0, "maximum" => 1.0e9},
    "transmit_power_w" => %{"minimum" => 0.001, "maximum" => 10_000.0},
    "antenna_gain_dbi" => %{"minimum" => 0.0, "maximum" => 100.0},
    "system_noise_temperature_k" => %{"minimum" => 1.0, "maximum" => 10_000.0},
    "explicit_losses_db" => %{"minimum" => 0.0, "maximum" => 300.0},
    "coding_efficiency_ratio" => %{"minimum" => 0.01, "maximum" => 1.0},
    "modulation_efficiency_bit_s_hz" => %{"minimum" => 0.01, "maximum" => 16.0},
    "required_eb_n0_db" => %{"minimum" => 0.0, "maximum" => 100.0},
    "required_margin_db" => %{"minimum" => 0.0, "maximum" => 100.0},
    "elevation_deg" => %{"minimum" => 0.0, "maximum" => 90.0}
  }
  @model_limits [
    "explicit_losses_only",
    "no_adaptive_coding_or_modulation",
    "no_antenna_pattern_integration",
    "no_atmospheric_rain_or_polarization_integration",
    "no_hidden_calibration",
    "no_provider_reservation_or_network_truth",
    "no_schedule_mutation",
    "one_way_downlink_only",
    "single_fixed_mode_only",
    "supplied_point_geometry_not_recomputed"
  ]

  @doc "Declares the bounded opt-in downlink-budget contract."
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      model: :deterministic_point_one_way_downlink_budget,
      validation_level: :artifact_contract,
      public_facades: [:downlink_link_budget],
      supported_direction: :downlink,
      supported_mode: String.to_atom(@supported_mode),
      input_geometry: [:slant_range_km, :elevation_deg, :sample_at_s],
      input_envelopes: @input_envelopes,
      output_metrics: [
        :received_power_dbw,
        :c_n0_db_hz,
        :eb_n0_db,
        :supported_data_rate_bps,
        :supported_volume_mb,
        :pass_fail_margin_db
      ],
      known_limits: Enum.map(@model_limits, &String.to_atom/1)
    }
  end

  @doc false
  def schema_contract, do: @schema_contract

  @doc false
  def model, do: @model

  @doc false
  def supported_mode, do: @supported_mode

  @doc false
  def model_limits, do: @model_limits

  @doc false
  def input_envelopes, do: @input_envelopes

  @doc false
  def assumptions do
    %{
      "calibration" => "none",
      "speed_of_light_m_s" => @speed_of_light_m_s,
      "boltzmann_constant_w_hz_k" => @boltzmann_constant_w_hz_k,
      "megabyte_definition_bits" => @megabyte_bits,
      "input_envelopes" => @input_envelopes,
      "input_envelope_basis" =>
        "bounded_leo_ground_downlink_engineering_screen_not_mission_certification",
      "free_space_path_loss_model" => "20_log10_4_pi_range_m_frequency_hz_over_c",
      "noise_density_model" => "10_log10_boltzmann_constant_times_system_noise_temperature_k",
      "configured_data_rate_model" =>
        "occupied_bandwidth_hz_times_coding_efficiency_times_modulation_efficiency_bits_per_hz",
      "supported_rate_model" =>
        "configured_fixed_mode_rate_when_geometry_and_margin_pass_else_zero",
      "supported_volume_model" => "supported_data_rate_bps_times_contact_duration_s_over_8000000",
      "pass_threshold" =>
        "elevation_at_or_above_minimum_and_eb_n0_minus_required_eb_n0_minus_required_margin_at_or_above_zero"
    }
  end

  @doc """
  Builds one schema-backed downlink budget for a contact.

  The contact must bind its source access-window ID and revision. Parameters
  must contain `access_window`, `geometry`, `spacecraft_terminal`,
  `ground_terminal`, `rf_link`, `margin_policy`, `source`, and
  `source_revision` maps/values with the explicit quantity units documented by
  the exported contract. An optional typed `candidate_binding` is included in
  the artifact's content identity for consumers that must bind this evidence
  to one generated alternative and its parameter revision/content.
  """
  def build(contact, params) when is_map(contact) and is_map(params) do
    candidate_binding = CandidateBinding.optional_from_container!(params)
    contact = stringify_keys(contact)
    params = stringify_keys(params)

    normalized = %{
      contact_binding: normalize_contact_binding!(contact),
      access_window: normalize_access_window!(required_map!(params, "access_window")),
      geometry: normalize_geometry!(required_map!(params, "geometry")),
      spacecraft_terminal:
        normalize_spacecraft_terminal!(required_map!(params, "spacecraft_terminal")),
      ground_terminal: normalize_ground_terminal!(required_map!(params, "ground_terminal")),
      rf_link: normalize_rf_link!(required_map!(params, "rf_link")),
      margin_policy: normalize_margin_policy!(required_map!(params, "margin_policy")),
      source: required_text!(params, "source"),
      source_revision: required_text!(params, "source_revision"),
      candidate_binding: candidate_binding
    }

    validate_declared_contact_window!(contact, normalized.access_window)
    validate_bindings!(normalized)
    derived = derive!(normalized)

    core =
      %{
        "schema_contract" => @schema_contract,
        "model" => @model,
        "status" => derived["status"],
        "pass" => derived["pass"],
        "contact_binding" => normalized.contact_binding,
        "access_window" => normalized.access_window,
        "geometry" => normalized.geometry,
        "spacecraft_terminal" => normalized.spacecraft_terminal,
        "ground_terminal" => normalized.ground_terminal,
        "rf_link" => normalized.rf_link,
        "margin_policy" => normalized.margin_policy,
        "derived" => Map.drop(derived, ["status", "pass"]),
        "assumptions" => assumptions(),
        "provenance" => provenance(normalized),
        "model_limits" => @model_limits
      }
      |> maybe_put("candidate_binding", candidate_binding)

    Map.put(core, "id", artifact_id(core))
  end

  def build(_contact, _params),
    do: raise(ArgumentError, "contact and downlink link-budget parameters must be maps")

  @doc """
  Returns and validates attached `downlink_link_budget.v1` evidence, or `nil`.

  Evidence is accepted only when its contact/window identity still matches the
  consuming contact exactly.
  """
  def evidence_for_contact(contact) when is_map(contact) do
    contact = stringify_keys(contact)

    case Map.get(contact, "downlink_link_budget") do
      nil ->
        nil

      %{} = evidence ->
        evidence = stringify_keys(evidence)

        case validate_artifact(evidence) do
          :ok ->
            binding = normalize_contact_binding!(contact)

            if evidence["contact_binding"] == binding do
              validate_declared_contact_window!(contact, evidence["access_window"])
              evidence
            else
              raise ArgumentError,
                    "downlink_link_budget contact/window identity is stale or mismatched"
            end

          {:error, reason} ->
            raise ArgumentError, "invalid downlink_link_budget evidence: #{reason}"
        end

      _evidence ->
        raise ArgumentError, "downlink_link_budget evidence must be a map"
    end
  end

  def evidence_for_contact(_contact), do: nil

  @doc false
  def supported_volume_mb(contact) do
    case evidence_for_contact(contact) do
      %{} = evidence -> get_in(evidence, ["derived", "supported_volume_mb"])
      nil -> nil
    end
  end

  @doc false
  def supported_data_rate_bps(contact) do
    case evidence_for_contact(contact) do
      %{} = evidence -> get_in(evidence, ["derived", "supported_data_rate_bps"])
      nil -> nil
    end
  end

  @doc false
  def validate_artifact(artifact) when is_map(artifact) do
    artifact = stringify_keys(artifact)

    try do
      validate_artifact!(artifact)
      :ok
    rescue
      error in [ArgumentError, ArithmeticError, BadMapError, KeyError] ->
        {:error, Exception.message(error)}
    end
  end

  def validate_artifact(_artifact), do: {:error, "artifact must be a map"}

  @doc false
  def artifact_id(core) when is_map(core) do
    "downlink_link_budget:" <> digest(stringify_keys(core))
  end

  defp validate_artifact!(artifact) do
    required_top_level = ~w(
      schema_contract id model status pass contact_binding access_window geometry
      spacecraft_terminal ground_terminal rf_link margin_policy derived assumptions
      provenance model_limits
    )

    allowed_top_level =
      if Map.has_key?(artifact, "candidate_binding"),
        do: required_top_level ++ ["candidate_binding"],
        else: required_top_level

    require_fields!(artifact, required_top_level, "artifact")
    require_exact_fields!(artifact, allowed_top_level, "artifact")
    require_equal!(artifact["schema_contract"], @schema_contract, "schema_contract")
    require_equal!(artifact["model"], @model, "model")
    require_equal!(artifact["model_limits"], @model_limits, "model_limits")
    require_equal!(artifact["assumptions"], assumptions(), "assumptions")
    stable_id!(artifact["id"], "id")

    normalized = %{
      contact_binding: validate_contact_binding!(artifact["contact_binding"]),
      access_window: validate_access_window!(artifact["access_window"]),
      geometry: validate_geometry!(artifact["geometry"]),
      spacecraft_terminal: validate_spacecraft_terminal!(artifact["spacecraft_terminal"]),
      ground_terminal: validate_ground_terminal!(artifact["ground_terminal"]),
      rf_link: validate_rf_link!(artifact["rf_link"]),
      margin_policy: validate_margin_policy!(artifact["margin_policy"]),
      source: required_text!(artifact["provenance"], "source"),
      source_revision: required_text!(artifact["provenance"], "source_revision"),
      candidate_binding:
        case Map.get(artifact, "candidate_binding") do
          nil -> nil
          binding -> CandidateBinding.normalize!(binding)
        end
    }

    validate_bindings!(normalized)
    expected_derived = derive!(normalized)
    expected_provenance = provenance(normalized)

    require_equal!(artifact["contact_binding"], normalized.contact_binding, "contact_binding")
    require_equal!(artifact["access_window"], normalized.access_window, "access_window")
    require_equal!(artifact["geometry"], normalized.geometry, "geometry")

    require_equal!(
      artifact["spacecraft_terminal"],
      normalized.spacecraft_terminal,
      "spacecraft_terminal"
    )

    require_equal!(artifact["ground_terminal"], normalized.ground_terminal, "ground_terminal")
    require_equal!(artifact["rf_link"], normalized.rf_link, "rf_link")
    require_equal!(artifact["margin_policy"], normalized.margin_policy, "margin_policy")

    if normalized.candidate_binding do
      require_equal!(
        artifact["candidate_binding"],
        normalized.candidate_binding,
        "candidate_binding"
      )
    end

    require_equal!(artifact["status"], expected_derived["status"], "status")
    require_equal!(artifact["pass"], expected_derived["pass"], "pass")

    require_equal!(
      artifact["derived"],
      Map.drop(expected_derived, ["status", "pass"]),
      "derived"
    )

    require_equal!(artifact["provenance"], expected_provenance, "provenance")

    expected_id = artifact |> Map.delete("id") |> artifact_id()
    require_equal!(artifact["id"], expected_id, "id")
    :ok
  end

  defp normalize_contact_binding!(contact) do
    starts_at_s = time_s!(required_value!(contact, "starts_at_s"), "starts_at_s")
    ends_at_s = time_s!(required_value!(contact, "ends_at_s"), "ends_at_s")

    if ends_at_s <= starts_at_s do
      raise ArgumentError, "contact ends_at_s must be greater than starts_at_s"
    end

    %{
      "contact_id" => stable_id!(contact["id"] || contact["contact_id"], "contact_id"),
      "spacecraft_id" => stable_id!(contact["spacecraft_id"], "spacecraft_id"),
      "ground_station_id" => stable_id!(contact["ground_station_id"], "ground_station_id"),
      "direction" => required_text!(contact, "direction"),
      "mode" => required_text!(contact, "mode"),
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => ends_at_s - starts_at_s,
      "source_window_id" =>
        stable_id!(
          contact["source_window_id"] || get_in(contact, ["source_window", "id"]),
          "source_window_id"
        ),
      "source_window_revision" =>
        required_text_value!(
          contact["source_window_revision"] || get_in(contact, ["source_window", "revision"]),
          "source_window_revision"
        )
    }
  end

  defp normalize_access_window!(window) do
    starts_at_s = time_s!(required_value!(window, "starts_at_s"), "starts_at_s")
    ends_at_s = time_s!(required_value!(window, "ends_at_s"), "ends_at_s")

    if ends_at_s <= starts_at_s do
      raise ArgumentError, "access_window ends_at_s must be greater than starts_at_s"
    end

    %{
      "id" => stable_id!(required_value!(window, "id"), "access_window.id"),
      "revision" => required_text!(window, "revision"),
      "spacecraft_id" => stable_id!(required_value!(window, "spacecraft_id"), "spacecraft_id"),
      "ground_station_id" =>
        stable_id!(required_value!(window, "ground_station_id"), "ground_station_id"),
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "source" => required_text!(window, "source"),
      "source_revision" => required_text!(window, "source_revision")
    }
  end

  defp normalize_geometry!(geometry) do
    %{
      "slant_range" => quantity!(geometry, "slant_range", "km", envelope(:slant_range_km)),
      "elevation" => quantity!(geometry, "elevation", "deg", envelope(:elevation_deg)),
      "sample_at" => quantity!(geometry, "sample_at", "s", envelope(:time_s))
    }
  end

  defp normalize_spacecraft_terminal!(terminal) do
    %{
      "id" => stable_id!(required_value!(terminal, "id"), "spacecraft_terminal.id"),
      "spacecraft_id" =>
        stable_id!(
          required_value!(terminal, "spacecraft_id"),
          "spacecraft_terminal.spacecraft_id"
        ),
      "source" => required_text!(terminal, "source"),
      "revision" => required_text!(terminal, "revision"),
      "direction" => required_text!(terminal, "direction"),
      "mode" => required_text!(terminal, "mode"),
      "carrier_frequency" =>
        quantity!(terminal, "carrier_frequency", "Hz", envelope(:carrier_frequency_hz)),
      "transmit_power" => quantity!(terminal, "transmit_power", "W", envelope(:transmit_power_w)),
      "transmit_antenna_gain" =>
        quantity!(terminal, "transmit_antenna_gain", "dBi", envelope(:antenna_gain_dbi))
    }
  end

  defp normalize_ground_terminal!(terminal) do
    %{
      "id" => stable_id!(required_value!(terminal, "id"), "ground_terminal.id"),
      "ground_station_id" =>
        stable_id!(
          required_value!(terminal, "ground_station_id"),
          "ground_terminal.ground_station_id"
        ),
      "source" => required_text!(terminal, "source"),
      "revision" => required_text!(terminal, "revision"),
      "direction" => required_text!(terminal, "direction"),
      "mode" => required_text!(terminal, "mode"),
      "carrier_frequency" =>
        quantity!(terminal, "carrier_frequency", "Hz", envelope(:carrier_frequency_hz)),
      "receive_antenna_gain" =>
        quantity!(terminal, "receive_antenna_gain", "dBi", envelope(:antenna_gain_dbi)),
      "system_noise_temperature" =>
        quantity!(
          terminal,
          "system_noise_temperature",
          "K",
          envelope(:system_noise_temperature_k)
        )
    }
  end

  defp normalize_rf_link!(rf_link) do
    carrier_frequency =
      quantity!(rf_link, "carrier_frequency", "Hz", envelope(:carrier_frequency_hz))

    occupied_bandwidth =
      quantity!(rf_link, "occupied_bandwidth", "Hz", envelope(:occupied_bandwidth_hz))

    if occupied_bandwidth["value"] > carrier_frequency["value"] do
      raise ArgumentError, "occupied_bandwidth must not exceed carrier_frequency"
    end

    %{
      "direction" => required_text!(rf_link, "direction"),
      "mode" => required_text!(rf_link, "mode"),
      "carrier_frequency" => carrier_frequency,
      "occupied_bandwidth" => occupied_bandwidth,
      "explicit_losses" =>
        quantity!(rf_link, "explicit_losses", "dB", envelope(:explicit_losses_db)),
      "coding_efficiency" =>
        quantity!(rf_link, "coding_efficiency", "ratio", envelope(:coding_efficiency_ratio)),
      "modulation_efficiency" =>
        quantity!(
          rf_link,
          "modulation_efficiency",
          "bit/s/Hz",
          envelope(:modulation_efficiency_bit_s_hz)
        )
    }
  end

  defp normalize_margin_policy!(margin_policy) do
    %{
      "minimum_elevation" =>
        quantity!(margin_policy, "minimum_elevation", "deg", envelope(:elevation_deg)),
      "required_eb_n0" =>
        quantity!(margin_policy, "required_eb_n0", "dB", envelope(:required_eb_n0_db)),
      "required_margin" =>
        quantity!(margin_policy, "required_margin", "dB", envelope(:required_margin_db))
    }
  end

  defp validate_contact_binding!(binding) do
    binding = required_map_value!(binding, "contact_binding")

    require_fields!(
      binding,
      ~w(contact_id spacecraft_id ground_station_id direction mode starts_at_s ends_at_s duration_s source_window_id source_window_revision),
      "contact_binding"
    )

    starts_at_s = time_s!(binding["starts_at_s"], "starts_at_s")
    ends_at_s = time_s!(binding["ends_at_s"], "ends_at_s")
    duration_s = bounded_number!(binding["duration_s"], "duration_s", 0.0, @maximum_time_s, false)

    require_equal!(duration_s, ends_at_s - starts_at_s, "duration_s")

    %{
      "contact_id" => stable_id!(binding["contact_id"], "contact_id"),
      "spacecraft_id" => stable_id!(binding["spacecraft_id"], "spacecraft_id"),
      "ground_station_id" => stable_id!(binding["ground_station_id"], "ground_station_id"),
      "direction" => required_text!(binding, "direction"),
      "mode" => required_text!(binding, "mode"),
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => duration_s,
      "source_window_id" => stable_id!(binding["source_window_id"], "source_window_id"),
      "source_window_revision" => required_text!(binding, "source_window_revision")
    }
  end

  defp validate_access_window!(window),
    do: normalize_access_window!(required_map_value!(window, "access_window"))

  defp validate_geometry!(geometry),
    do: normalize_geometry!(required_map_value!(geometry, "geometry"))

  defp validate_spacecraft_terminal!(terminal),
    do: normalize_spacecraft_terminal!(required_map_value!(terminal, "spacecraft_terminal"))

  defp validate_ground_terminal!(terminal),
    do: normalize_ground_terminal!(required_map_value!(terminal, "ground_terminal"))

  defp validate_rf_link!(rf_link), do: normalize_rf_link!(required_map_value!(rf_link, "rf_link"))

  defp validate_margin_policy!(margin_policy),
    do: normalize_margin_policy!(required_map_value!(margin_policy, "margin_policy"))

  defp validate_bindings!(normalized) do
    binding = normalized.contact_binding
    window = normalized.access_window
    geometry = normalized.geometry
    spacecraft_terminal = normalized.spacecraft_terminal
    ground_terminal = normalized.ground_terminal
    rf_link = normalized.rf_link

    require_equal!(binding["direction"], "downlink", "contact direction")
    require_equal!(binding["mode"], @supported_mode, "contact mode")
    require_equal!(rf_link["direction"], "downlink", "RF direction")
    require_equal!(rf_link["mode"], @supported_mode, "RF mode")
    require_equal!(spacecraft_terminal["direction"], "downlink", "spacecraft terminal direction")
    require_equal!(ground_terminal["direction"], "downlink", "ground terminal direction")
    require_equal!(spacecraft_terminal["mode"], @supported_mode, "spacecraft terminal mode")
    require_equal!(ground_terminal["mode"], @supported_mode, "ground terminal mode")

    require_equal!(
      spacecraft_terminal["spacecraft_id"],
      binding["spacecraft_id"],
      "spacecraft terminal owner"
    )

    require_equal!(
      ground_terminal["ground_station_id"],
      binding["ground_station_id"],
      "ground terminal owner"
    )

    require_equal!(binding["source_window_id"], window["id"], "source window ID")

    require_equal!(
      binding["source_window_revision"],
      window["revision"],
      "source window revision"
    )

    require_equal!(binding["spacecraft_id"], window["spacecraft_id"], "spacecraft identity")

    require_equal!(
      binding["ground_station_id"],
      window["ground_station_id"],
      "ground-station identity"
    )

    if binding["starts_at_s"] < window["starts_at_s"] or
         binding["ends_at_s"] > window["ends_at_s"] do
      raise ArgumentError, "contact interval must be contained by its bound access window"
    end

    sample_at_s = geometry["sample_at"]["value"]

    if sample_at_s < binding["starts_at_s"] or sample_at_s > binding["ends_at_s"] do
      raise ArgumentError, "geometry sample_at must fall within the contact interval"
    end

    frequency_hz = rf_link["carrier_frequency"]["value"]

    require_equal!(
      spacecraft_terminal["carrier_frequency"]["value"],
      frequency_hz,
      "spacecraft terminal carrier frequency"
    )

    require_equal!(
      ground_terminal["carrier_frequency"]["value"],
      frequency_hz,
      "ground terminal carrier frequency"
    )
  end

  defp validate_declared_contact_window!(%{"source_window" => %{} = declared}, expected) do
    Enum.each(
      ~w(id revision spacecraft_id ground_station_id starts_at_s ends_at_s),
      fn field ->
        if Map.has_key?(declared, field) do
          require_equal!(declared[field], expected[field], "contact source_window.#{field}")
        end
      end
    )
  end

  defp validate_declared_contact_window!(_contact, _expected), do: :ok

  defp derive!(normalized) do
    binding = normalized.contact_binding
    geometry = normalized.geometry
    spacecraft_terminal = normalized.spacecraft_terminal
    ground_terminal = normalized.ground_terminal
    rf_link = normalized.rf_link
    margin_policy = normalized.margin_policy

    slant_range_m = geometry["slant_range"]["value"] * 1_000.0
    carrier_frequency_hz = rf_link["carrier_frequency"]["value"]
    transmit_power_w = spacecraft_terminal["transmit_power"]["value"]
    transmit_gain_dbi = spacecraft_terminal["transmit_antenna_gain"]["value"]
    receive_gain_dbi = ground_terminal["receive_antenna_gain"]["value"]
    noise_temperature_k = ground_terminal["system_noise_temperature"]["value"]
    explicit_losses_db = rf_link["explicit_losses"]["value"]

    transmit_power_dbw = 10.0 * :math.log10(transmit_power_w)
    eirp_dbw = transmit_power_dbw + transmit_gain_dbi

    free_space_path_loss_db =
      20.0 *
        (:math.log10(4.0 * :math.pi()) + :math.log10(slant_range_m) +
           :math.log10(carrier_frequency_hz) - :math.log10(@speed_of_light_m_s))

    received_power_dbw =
      eirp_dbw + receive_gain_dbi - free_space_path_loss_db - explicit_losses_db

    noise_spectral_density_dbw_per_hz =
      10.0 *
        (:math.log10(@boltzmann_constant_w_hz_k) + :math.log10(noise_temperature_k))

    c_n0_db_hz = received_power_dbw - noise_spectral_density_dbw_per_hz

    configured_data_rate_bps =
      rf_link["occupied_bandwidth"]["value"] * rf_link["coding_efficiency"]["value"] *
        rf_link["modulation_efficiency"]["value"]

    eb_n0_db = c_n0_db_hz - 10.0 * :math.log10(configured_data_rate_bps)
    eb_n0_margin_db = eb_n0_db - margin_policy["required_eb_n0"]["value"]
    pass_fail_margin_db = eb_n0_margin_db - margin_policy["required_margin"]["value"]

    geometry_margin_deg =
      geometry["elevation"]["value"] - margin_policy["minimum_elevation"]["value"]

    status =
      cond do
        geometry_margin_deg < 0.0 -> "below_minimum_elevation"
        pass_fail_margin_db < 0.0 -> "insufficient_link_margin"
        true -> "supported"
      end

    pass? = status == "supported"
    supported_data_rate_bps = if pass?, do: configured_data_rate_bps, else: 0.0
    supported_volume_mb = supported_data_rate_bps * binding["duration_s"] / @megabyte_bits

    derived = %{
      "status" => status,
      "pass" => pass?,
      "transmit_power_dbw" => transmit_power_dbw,
      "eirp_dbw" => eirp_dbw,
      "free_space_path_loss_db" => free_space_path_loss_db,
      "received_power_dbw" => received_power_dbw,
      "noise_spectral_density_dbw_per_hz" => noise_spectral_density_dbw_per_hz,
      "c_n0_db_hz" => c_n0_db_hz,
      "configured_data_rate_bps" => configured_data_rate_bps,
      "configured_data_rate_mbps" => configured_data_rate_bps / 1_000_000.0,
      "eb_n0_db" => eb_n0_db,
      "eb_n0_margin_db" => eb_n0_margin_db,
      "required_margin_db" => margin_policy["required_margin"]["value"],
      "pass_fail_margin_db" => pass_fail_margin_db,
      "geometry_margin_deg" => geometry_margin_deg,
      "supported_data_rate_bps" => supported_data_rate_bps,
      "supported_data_rate_mbps" => supported_data_rate_bps / 1_000_000.0,
      "supported_volume_mb" => supported_volume_mb
    }

    Enum.each(derived, fn
      {_field, value} when is_boolean(value) or is_binary(value) -> :ok
      {field, value} -> finite_number!(value, "derived.#{field}")
    end)

    derived
  rescue
    _error in ArithmeticError ->
      raise ArgumentError, "link-budget arithmetic must remain finite"
  end

  defp provenance(normalized) do
    %{
      "source" => normalized.source,
      "source_revision" => normalized.source_revision,
      "access_window_source" => normalized.access_window["source"],
      "access_window_source_revision" => normalized.access_window["source_revision"],
      "spacecraft_terminal_source" => normalized.spacecraft_terminal["source"],
      "spacecraft_terminal_revision" => normalized.spacecraft_terminal["revision"],
      "ground_terminal_source" => normalized.ground_terminal["source"],
      "ground_terminal_revision" => normalized.ground_terminal["revision"],
      "builder" => "OrbitalDynamics.Communications.DownlinkLinkBudget.build/2"
    }
  end

  defp quantity!(map, field, unit, constraint) do
    quantity = required_map!(map, field)
    require_equal!(required_value!(quantity, "unit"), unit, "#{field}.unit")
    value = finite_number!(required_value!(quantity, "value"), "#{field}.value")
    validate_quantity_constraint!(value, field, constraint)
    %{"value" => value, "unit" => unit}
  end

  defp validate_quantity_constraint!(value, field, {:envelope, minimum, maximum}) do
    if value >= minimum and value <= maximum do
      :ok
    else
      raise ArgumentError, "#{field}.value must be in [#{minimum}, #{maximum}]"
    end
  end

  defp envelope(field) do
    bounds = Map.fetch!(@input_envelopes, Atom.to_string(field))
    {:envelope, bounds["minimum"], bounds["maximum"]}
  end

  defp require_fields!(map, fields, scope) do
    Enum.each(fields, fn field ->
      if not Map.has_key?(map, field) do
        raise ArgumentError, "#{scope}.#{field} is required"
      end
    end)
  end

  defp require_exact_fields!(map, fields, scope) do
    case Map.keys(map) -- fields do
      [] ->
        :ok

      unexpected ->
        raise ArgumentError, "#{scope} has unexpected fields #{inspect(Enum.sort(unexpected))}"
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp required_map!(map, field) do
    case Map.get(map, field) do
      %{} = value -> value
      _value -> raise ArgumentError, "#{field} is required and must be a map"
    end
  end

  defp required_map_value!(%{} = value, _field), do: value
  defp required_map_value!(_value, field), do: raise(ArgumentError, "#{field} must be a map")

  defp required_value!(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} when not is_nil(value) -> value
      _missing -> raise ArgumentError, "#{field} is required"
    end
  end

  defp required_text!(map, field),
    do: map |> required_value!(field) |> required_text_value!(field)

  defp required_text_value!(value, field) when is_atom(value),
    do: value |> Atom.to_string() |> required_text_value!(field)

  defp required_text_value!(value, field) when is_binary(value) do
    case String.trim(value) do
      "" -> raise ArgumentError, "#{field} must be a non-empty string"
      value -> value
    end
  end

  defp required_text_value!(_value, field),
    do: raise(ArgumentError, "#{field} must be a non-empty string")

  defp stable_id!(value, field) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id!(field)

  defp stable_id!(value, field) when is_binary(value) do
    value = String.trim(value)

    if Regex.match?(@stable_id_pattern, value) do
      value
    else
      raise ArgumentError, "#{field} must be a stable ID"
    end
  end

  defp stable_id!(_value, field), do: raise(ArgumentError, "#{field} must be a stable ID")

  defp finite_number!(value, field) when is_integer(value) do
    if abs(value) <= @maximum_finite_float do
      value * 1.0
    else
      raise ArgumentError, "#{field} must be finite"
    end
  end

  defp finite_number!(value, field) when is_float(value) do
    if value == value and abs(value) <= @maximum_finite_float do
      value
    else
      raise ArgumentError, "#{field} must be finite"
    end
  end

  defp finite_number!(_value, field),
    do: raise(ArgumentError, "#{field} must be numeric and finite")

  defp time_s!(value, field),
    do: bounded_number!(value, field, 0.0, @maximum_time_s, true)

  defp bounded_number!(value, field, minimum, maximum, inclusive_minimum?) do
    value = finite_number!(value, field)

    minimum_valid? = if inclusive_minimum?, do: value >= minimum, else: value > minimum

    if minimum_valid? and value <= maximum do
      value
    else
      left_bracket = if inclusive_minimum?, do: "[", else: "("
      raise ArgumentError, "#{field} must be in #{left_bracket}#{minimum}, #{maximum}]"
    end
  end

  defp require_equal!(actual, expected, field) do
    if actual == expected do
      :ok
    else
      raise ArgumentError, "#{field} must equal #{inspect(expected)}"
    end
  end

  defp digest(value) do
    value
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    map
    |> Enum.sort_by(fn {key, _value} -> {to_string(key), key_precedence(key)} end)
    |> Map.new(fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(value) when is_atom(value) and not is_nil(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp key_precedence(key) when is_atom(key), do: 0
  defp key_precedence(_key), do: 1
end
