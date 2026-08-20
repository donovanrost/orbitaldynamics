defmodule OrbitalDynamics.Schema.DownlinkLinkBudgetJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Communications.DownlinkLinkBudget

  @quantity_units ["km", "deg", "s", "Hz", "W", "dBi", "K", "dB", "ratio", "bit/s/Hz"]

  def property("schema_contract", _opts),
    do: %{"type" => "string", "const" => DownlinkLinkBudget.schema_contract()}

  def property("id", opts), do: stable_id(opts)

  def property("model", _opts),
    do: %{"type" => "string", "const" => DownlinkLinkBudget.model()}

  def property("status", _opts) do
    %{
      "type" => "string",
      "enum" => ["supported", "below_minimum_elevation", "insufficient_link_margin"]
    }
  end

  def property("pass", _opts), do: %{"type" => "boolean"}
  def property("contact_binding", opts), do: contact_binding(opts)
  def property("access_window", opts), do: access_window(opts)
  def property("geometry", _opts), do: geometry()
  def property("spacecraft_terminal", opts), do: spacecraft_terminal(opts)
  def property("ground_terminal", opts), do: ground_terminal(opts)
  def property("rf_link", _opts), do: rf_link()
  def property("margin_policy", _opts), do: margin_policy()
  def property("derived", _opts), do: derived()

  def property("assumptions", _opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "const" => DownlinkLinkBudget.assumptions()
    }
  end

  def property("provenance", _opts), do: provenance()

  def property("candidate_binding", _opts),
    do: OrbitalDynamics.Optimizer.CandidateBinding.json_schema()

  def property("model_limits", _opts) do
    %{
      "type" => "array",
      "const" => DownlinkLinkBudget.model_limits(),
      "items" => %{"type" => "string", "enum" => DownlinkLinkBudget.model_limits()}
    }
  end

  def artifact_schema(opts) do
    contract =
      OrbitalDynamics.Schema.DownlinkLinkBudgetRegistryContracts.contracts()
      |> Map.fetch!(DownlinkLinkBudget.schema_contract())

    required = Map.fetch!(contract, "required_fields")
    properties = required ++ Map.fetch!(contract, "optional_fields")

    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => required,
      "properties" => Map.new(properties, &{&1, property(&1, opts)})
    }
  end

  defp contact_binding(opts) do
    time_bounds = envelope("time_s")

    object(
      ~w(contact_id spacecraft_id ground_station_id direction mode starts_at_s ends_at_s duration_s source_window_id source_window_revision),
      %{
        "contact_id" => stable_id(opts),
        "spacecraft_id" => stable_id(opts),
        "ground_station_id" => stable_id(opts),
        "direction" => %{"type" => "string", "const" => "downlink"},
        "mode" => %{"type" => "string", "const" => DownlinkLinkBudget.supported_mode()},
        "starts_at_s" => bounded_number(time_bounds),
        "ends_at_s" => bounded_number(time_bounds),
        "duration_s" => bounded_number(time_bounds, exclusive_minimum: true),
        "source_window_id" => stable_id(opts),
        "source_window_revision" => non_blank_string()
      }
    )
  end

  defp access_window(opts) do
    time_bounds = envelope("time_s")

    object(
      ~w(id revision spacecraft_id ground_station_id starts_at_s ends_at_s source source_revision),
      %{
        "id" => stable_id(opts),
        "revision" => non_blank_string(),
        "spacecraft_id" => stable_id(opts),
        "ground_station_id" => stable_id(opts),
        "starts_at_s" => bounded_number(time_bounds),
        "ends_at_s" => bounded_number(time_bounds),
        "source" => non_blank_string(),
        "source_revision" => non_blank_string()
      }
    )
  end

  defp geometry do
    object(~w(slant_range elevation sample_at), %{
      "slant_range" => quantity("km", envelope("slant_range_km")),
      "elevation" => quantity("deg", envelope("elevation_deg")),
      "sample_at" => quantity("s", envelope("time_s"))
    })
  end

  defp spacecraft_terminal(opts) do
    object(
      ~w(id spacecraft_id source revision direction mode carrier_frequency transmit_power transmit_antenna_gain),
      %{
        "id" => stable_id(opts),
        "spacecraft_id" => stable_id(opts),
        "source" => non_blank_string(),
        "revision" => non_blank_string(),
        "direction" => %{"type" => "string", "const" => "downlink"},
        "mode" => %{"type" => "string", "const" => DownlinkLinkBudget.supported_mode()},
        "carrier_frequency" => quantity("Hz", envelope("carrier_frequency_hz")),
        "transmit_power" => quantity("W", envelope("transmit_power_w")),
        "transmit_antenna_gain" => quantity("dBi", envelope("antenna_gain_dbi"))
      }
    )
  end

  defp ground_terminal(opts) do
    object(
      ~w(id ground_station_id source revision direction mode carrier_frequency receive_antenna_gain system_noise_temperature),
      %{
        "id" => stable_id(opts),
        "ground_station_id" => stable_id(opts),
        "source" => non_blank_string(),
        "revision" => non_blank_string(),
        "direction" => %{"type" => "string", "const" => "downlink"},
        "mode" => %{"type" => "string", "const" => DownlinkLinkBudget.supported_mode()},
        "carrier_frequency" => quantity("Hz", envelope("carrier_frequency_hz")),
        "receive_antenna_gain" => quantity("dBi", envelope("antenna_gain_dbi")),
        "system_noise_temperature" => quantity("K", envelope("system_noise_temperature_k"))
      }
    )
  end

  defp rf_link do
    object(
      ~w(direction mode carrier_frequency occupied_bandwidth explicit_losses coding_efficiency modulation_efficiency),
      %{
        "direction" => %{"type" => "string", "const" => "downlink"},
        "mode" => %{"type" => "string", "const" => DownlinkLinkBudget.supported_mode()},
        "carrier_frequency" => quantity("Hz", envelope("carrier_frequency_hz")),
        "occupied_bandwidth" => quantity("Hz", envelope("occupied_bandwidth_hz")),
        "explicit_losses" => quantity("dB", envelope("explicit_losses_db")),
        "coding_efficiency" => quantity("ratio", envelope("coding_efficiency_ratio")),
        "modulation_efficiency" =>
          quantity("bit/s/Hz", envelope("modulation_efficiency_bit_s_hz"))
      }
    )
  end

  defp margin_policy do
    object(~w(minimum_elevation required_eb_n0 required_margin), %{
      "minimum_elevation" => quantity("deg", envelope("elevation_deg")),
      "required_eb_n0" => quantity("dB", envelope("required_eb_n0_db")),
      "required_margin" => quantity("dB", envelope("required_margin_db"))
    })
  end

  defp derived do
    fields = ~w(
      transmit_power_dbw eirp_dbw free_space_path_loss_db received_power_dbw
      noise_spectral_density_dbw_per_hz c_n0_db_hz configured_data_rate_bps
      configured_data_rate_mbps eb_n0_db eb_n0_margin_db required_margin_db
      pass_fail_margin_db geometry_margin_deg supported_data_rate_bps
      supported_data_rate_mbps supported_volume_mb
    )

    non_negative = ~w(
      free_space_path_loss_db configured_data_rate_bps configured_data_rate_mbps
      required_margin_db supported_data_rate_bps supported_data_rate_mbps supported_volume_mb
    )

    properties =
      Map.new(fields, fn field ->
        schema = if field in non_negative, do: non_negative_number(), else: number()
        {field, schema}
      end)

    object(fields, properties)
  end

  defp provenance do
    fields = ~w(
      source source_revision access_window_source access_window_source_revision
      spacecraft_terminal_source spacecraft_terminal_revision ground_terminal_source
      ground_terminal_revision builder
    )

    object(fields, Map.new(fields, &{&1, non_blank_string()}))
  end

  defp quantity(unit, bounds) do
    value_schema =
      bounds
      |> Enum.reduce(number(), fn
        {:minimum, value}, schema -> Map.put(schema, "minimum", value)
        {:maximum, value}, schema -> Map.put(schema, "maximum", value)
        {:exclusive_minimum, value}, schema -> Map.put(schema, "exclusiveMinimum", value)
        {"minimum", value}, schema -> Map.put(schema, "minimum", value)
        {"maximum", value}, schema -> Map.put(schema, "maximum", value)
      end)

    object(["value", "unit"], %{
      "value" => value_schema,
      "unit" => %{"type" => "string", "const" => unit, "enum" => @quantity_units}
    })
  end

  defp envelope(field), do: Map.fetch!(DownlinkLinkBudget.input_envelopes(), field)

  defp bounded_number(bounds, opts \\ []) do
    minimum_key =
      if Keyword.get(opts, :exclusive_minimum, false), do: "exclusiveMinimum", else: "minimum"

    %{
      "type" => "number",
      minimum_key => bounds["minimum"],
      "maximum" => bounds["maximum"]
    }
  end

  defp object(required, properties) do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => required,
      "properties" => properties
    }
  end

  defp stable_id(opts) do
    pattern =
      Keyword.get_lazy(opts, :stable_id_pattern, fn ->
        OrbitalDynamics.Schema.StableIdValidation.pattern()
      end)

    %{"type" => "string", "pattern" => pattern}
  end

  defp number, do: %{"type" => "number"}
  defp non_negative_number, do: %{"type" => "number", "minimum" => 0.0}
  defp non_blank_string, do: %{"type" => "string", "minLength" => 1}
end
