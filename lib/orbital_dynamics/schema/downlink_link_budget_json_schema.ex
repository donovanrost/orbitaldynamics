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

  def property("model_limits", _opts) do
    %{
      "type" => "array",
      "const" => DownlinkLinkBudget.model_limits(),
      "items" => %{"type" => "string", "enum" => DownlinkLinkBudget.model_limits()}
    }
  end

  def artifact_schema(opts) do
    required =
      OrbitalDynamics.Schema.DownlinkLinkBudgetRegistryContracts.contracts()
      |> Map.fetch!(DownlinkLinkBudget.schema_contract())
      |> Map.fetch!("required_fields")

    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => required,
      "properties" => Map.new(required, &{&1, property(&1, opts)})
    }
  end

  defp contact_binding(opts) do
    object(
      ~w(contact_id spacecraft_id ground_station_id direction mode starts_at_s ends_at_s duration_s source_window_id source_window_revision),
      %{
        "contact_id" => stable_id(opts),
        "spacecraft_id" => stable_id(opts),
        "ground_station_id" => stable_id(opts),
        "direction" => %{"type" => "string", "const" => "downlink"},
        "mode" => %{"type" => "string", "const" => DownlinkLinkBudget.supported_mode()},
        "starts_at_s" => non_negative_number(),
        "ends_at_s" => non_negative_number(),
        "duration_s" => positive_number(),
        "source_window_id" => stable_id(opts),
        "source_window_revision" => non_blank_string()
      }
    )
  end

  defp access_window(opts) do
    object(
      ~w(id revision spacecraft_id ground_station_id starts_at_s ends_at_s source source_revision),
      %{
        "id" => stable_id(opts),
        "revision" => non_blank_string(),
        "spacecraft_id" => stable_id(opts),
        "ground_station_id" => stable_id(opts),
        "starts_at_s" => non_negative_number(),
        "ends_at_s" => non_negative_number(),
        "source" => non_blank_string(),
        "source_revision" => non_blank_string()
      }
    )
  end

  defp geometry do
    object(~w(slant_range elevation sample_at), %{
      "slant_range" => quantity("km", exclusive_minimum: 0.0),
      "elevation" => quantity("deg", minimum: 0.0, maximum: 90.0),
      "sample_at" => quantity("s", minimum: 0.0)
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
        "carrier_frequency" => quantity("Hz", exclusive_minimum: 0.0),
        "transmit_power" => quantity("W", exclusive_minimum: 0.0),
        "transmit_antenna_gain" => quantity("dBi", minimum: 0.0)
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
        "carrier_frequency" => quantity("Hz", exclusive_minimum: 0.0),
        "receive_antenna_gain" => quantity("dBi", minimum: 0.0),
        "system_noise_temperature" => quantity("K", exclusive_minimum: 0.0)
      }
    )
  end

  defp rf_link do
    object(
      ~w(direction mode carrier_frequency occupied_bandwidth explicit_losses coding_efficiency modulation_efficiency),
      %{
        "direction" => %{"type" => "string", "const" => "downlink"},
        "mode" => %{"type" => "string", "const" => DownlinkLinkBudget.supported_mode()},
        "carrier_frequency" => quantity("Hz", exclusive_minimum: 0.0),
        "occupied_bandwidth" => quantity("Hz", exclusive_minimum: 0.0),
        "explicit_losses" => quantity("dB", minimum: 0.0),
        "coding_efficiency" => quantity("ratio", exclusive_minimum: 0.0, maximum: 1.0),
        "modulation_efficiency" => quantity("bit/s/Hz", exclusive_minimum: 0.0)
      }
    )
  end

  defp margin_policy do
    object(~w(minimum_elevation required_eb_n0 required_margin), %{
      "minimum_elevation" => quantity("deg", minimum: 0.0, maximum: 90.0),
      "required_eb_n0" => quantity("dB", minimum: 0.0),
      "required_margin" => quantity("dB", minimum: 0.0)
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
      end)

    object(["value", "unit"], %{
      "value" => value_schema,
      "unit" => %{"type" => "string", "const" => unit, "enum" => @quantity_units}
    })
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
  defp positive_number, do: %{"type" => "number", "exclusiveMinimum" => 0.0}
  defp non_blank_string, do: %{"type" => "string", "minLength" => 1}
end
