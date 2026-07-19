defmodule OrbitalDynamics.TimelineFeedback.LinkContext do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{ArtifactValue, RealizedIdentity, Throughput}

  def build(activity) do
    %{
      "link_protocol" =>
        first_string(activity, [
          "link_protocol",
          "protocol",
          ["link", "protocol"],
          ["communications", "protocol"],
          ["metadata", "link_protocol"]
        ]),
      "frequency_band" =>
        first_string(activity, [
          "frequency_band",
          "rf_band",
          ["link", "frequency_band"],
          ["communications", "frequency_band"],
          ["metadata", "frequency_band"]
        ]),
      "modulation" =>
        first_string(activity, [
          "modulation",
          "modulation_scheme",
          ["link", "modulation"],
          ["communications", "modulation"],
          ["metadata", "modulation"]
        ]),
      "coding_scheme" =>
        first_string(activity, [
          "coding_scheme",
          "coding",
          ["link", "coding_scheme"],
          ["communications", "coding_scheme"],
          ["metadata", "coding_scheme"]
        ]),
      "polarization" =>
        first_string(activity, [
          "polarization",
          ["link", "polarization"],
          ["communications", "polarization"],
          ["metadata", "polarization"]
        ]),
      "data_rate_mbps" => Throughput.data_rate_mbps(activity),
      "link_margin_db" =>
        Throughput.first_number(activity, [
          "link_margin_db",
          "link_margin_d_b",
          ["link", "link_margin_db"],
          ["communications", "link_margin_db"],
          ["metadata", "link_margin_db"]
        ]),
      "snr_db" =>
        Throughput.first_number(activity, [
          "snr_db",
          "signal_to_noise_db",
          ["link", "snr_db"],
          ["communications", "snr_db"],
          ["metadata", "snr_db"]
        ]),
      "eb_no_db" =>
        Throughput.first_number(activity, [
          "eb_no_db",
          "ebn0_db",
          "eb_no_d_b",
          ["link", "eb_no_db"],
          ["communications", "eb_no_db"],
          ["metadata", "eb_no_db"]
        ]),
      "bit_error_rate" =>
        Throughput.first_number(activity, [
          "bit_error_rate",
          "ber",
          ["link", "bit_error_rate"],
          ["communications", "bit_error_rate"],
          ["metadata", "bit_error_rate"]
        ]),
      "packet_loss_rate" =>
        Throughput.first_number(activity, [
          "packet_loss_rate",
          ["link", "packet_loss_rate"],
          ["communications", "packet_loss_rate"],
          ["metadata", "packet_loss_rate"]
        ]),
      "frame_loss_rate" =>
        Throughput.first_number(activity, [
          "frame_loss_rate",
          ["link", "frame_loss_rate"],
          ["communications", "frame_loss_rate"],
          ["metadata", "frame_loss_rate"]
        ]),
      "carrier_lock" =>
        first_boolean(activity, [
          "carrier_lock",
          "carrier_locked",
          ["link", "carrier_lock"],
          ["communications", "carrier_lock"],
          ["metadata", "carrier_lock"]
        ]),
      "symbol_lock" =>
        first_boolean(activity, [
          "symbol_lock",
          "symbol_locked",
          ["link", "symbol_lock"],
          ["communications", "symbol_lock"],
          ["metadata", "symbol_lock"]
        ]),
      "link_quality_status" =>
        first_string(activity, [
          "link_quality_status",
          "rf_status",
          ["link", "quality_status"],
          ["communications", "link_quality_status"],
          ["metadata", "link_quality_status"]
        ])
    }
    |> ArtifactValue.compact_map()
  end

  defp first_boolean(map, keys) do
    Enum.reduce_while(keys, nil, fn key, _value ->
      value =
        case key do
          path when is_list(path) -> get_in(map, path)
          key -> RealizedIdentity.first_value(map, [key])
        end

      case ArtifactValue.boolean_value(value) do
        value when is_boolean(value) -> {:halt, value}
        nil -> {:cont, nil}
      end
    end)
  end

  defp first_string(map, keys) do
    Enum.find_value(keys, fn key ->
      case RealizedIdentity.first_value(map, [key]) |> ArtifactValue.stringify_scalar() do
        value when value in [nil, ""] -> nil
        value -> value
      end
    end)
  end
end
