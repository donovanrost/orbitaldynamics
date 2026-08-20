defmodule OrbitalDynamics.Communications.ContactAllocation.ThroughputEvidence do
  @moduledoc false

  alias OrbitalDynamics.Communications.DownlinkLinkBudget

  def actual_throughput(contact) do
    explicit_actual_throughput(contact) || actual_data_rate_derived_throughput_mb(contact)
  end

  def estimated_throughput(contact) do
    DownlinkLinkBudget.supported_volume_mb(contact) ||
      first_number([
        contact["estimated_throughput_mb"],
        contact["estimated_downlink_mb"],
        contact["planned_throughput_mb"],
        get_in(contact, ["throughput_model", "estimated_throughput_mb"]),
        get_in(contact, ["throughput_model", "estimated_downlink_mb"]),
        get_in(contact, ["throughput_model", "planned_throughput_mb"])
      ])
  end

  def actual_data_rate_derivation(contact) do
    duration_s = actual_duration_s(contact)

    cond do
      is_number(explicit_actual_throughput(contact)) ->
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

  def downlink_completion_context(contact) do
    %{
      "required_downlink_mb" =>
        first_number([
          contact["required_downlink_mb"],
          get_in(contact, ["throughput_model", "required_downlink_mb"]),
          get_in(contact, ["activity_context", "required_downlink_mb"])
        ]),
      "candidate_downlink_mb" =>
        DownlinkLinkBudget.supported_volume_mb(contact) ||
          first_number([
            contact["candidate_downlink_mb"],
            get_in(contact, ["throughput_model", "candidate_downlink_mb"]),
            get_in(contact, ["activity_context", "candidate_downlink_mb"])
          ]),
      "downlink_completion_ratio" =>
        first_number([
          contact["downlink_completion_ratio"],
          get_in(contact, ["throughput_model", "downlink_completion_ratio"]),
          get_in(contact, ["activity_context", "downlink_completion_ratio"])
        ]),
      "selected_downlink_shortfall_mb" =>
        first_number([
          contact["selected_downlink_shortfall_mb"],
          get_in(contact, ["throughput_model", "selected_downlink_shortfall_mb"]),
          get_in(contact, ["activity_context", "selected_downlink_shortfall_mb"])
        ]),
      "downlink_requirement_status" =>
        first_string([
          contact["downlink_requirement_status"],
          get_in(contact, ["throughput_model", "downlink_requirement_status"]),
          get_in(contact, ["activity_context", "downlink_requirement_status"])
        ]),
      "downlink_completion_source" =>
        first_string([
          contact["downlink_completion_source"],
          get_in(contact, ["throughput_model", "downlink_completion_source"]),
          get_in(contact, ["activity_context", "downlink_completion_source"])
        ]),
      "downlink_completion_sources" =>
        first_string_list([
          contact["downlink_completion_sources"],
          get_in(contact, ["throughput_model", "downlink_completion_sources"]),
          get_in(contact, ["activity_context", "downlink_completion_sources"])
        ])
    }
  end

  defp explicit_actual_throughput(contact) do
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
    case actual_data_rate_derivation(contact) do
      %{"actual_throughput_mb" => actual_throughput_mb} when is_number(actual_throughput_mb) ->
        actual_throughput_mb

      _derivation ->
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

  defp first_string(values), do: Enum.find(values, &(is_binary(&1) and &1 != ""))

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
end
