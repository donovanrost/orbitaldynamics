defmodule OrbitalDynamics.Communications.StationCalendar.ProviderCounteroffer do
  @moduledoc false

  @negotiation_states ~w(proposed pending accepted rejected expired canceled unknown)
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def negotiation_states, do: @negotiation_states

  def entry?(entry) do
    value_present?(
      first_present_value(entry, ["provider_counteroffer_id", "counteroffer_id", "offer_id"])
    ) or
      value_present?(
        first_present_value(entry, [
          "provider_counteroffer_status",
          "counteroffer_status",
          "offer_status",
          "negotiation_status"
        ])
      )
  end

  def id(entry) do
    entry
    |> first_present_value(["provider_counteroffer_id", "counteroffer_id", "offer_id"])
    |> stable_id_or_nil()
  end

  def status(entry) do
    entry
    |> first_present_value([
      "provider_counteroffer_status",
      "counteroffer_status",
      "offer_status",
      "negotiation_status"
    ])
    |> normalize_status_value()
  end

  def negotiation_state(%{} = entry) do
    entry
    |> first_present_value([
      "provider_counteroffer_negotiation_state",
      "counteroffer_negotiation_state",
      "negotiation_state",
      "provider_counteroffer_status",
      "counteroffer_status",
      "offer_status",
      "negotiation_status"
    ])
    |> normalize_negotiation_state()
  end

  def reason_code(entry) do
    entry
    |> first_present_value([
      "provider_counteroffer_reason_code",
      "counteroffer_reason_code",
      "offer_reason_code",
      "provider_reason_code",
      "reason_code"
    ])
    |> normalize_status_value()
  end

  def cost_delta(entry) do
    entry
    |> first_present_value([
      "provider_counteroffer_cost_delta",
      "counteroffer_cost_delta",
      "cost_delta",
      "price_delta"
    ])
    |> numeric_or_nil()
  end

  def lock_deadline_s(entry) do
    entry
    |> first_present_value([
      "provider_counteroffer_lock_deadline_s",
      "counteroffer_lock_deadline_s",
      "schedule_lock_deadline_s",
      "lock_deadline_s"
    ])
    |> numeric_or_nil()
  end

  def starts_at_s(entry) do
    entry
    |> first_present_value([
      "provider_counteroffer_starts_at_s",
      "counteroffer_starts_at_s",
      "counteroffer_start_s",
      "offered_starts_at_s",
      "offered_start_s"
    ])
    |> numeric_or_nil()
  end

  def ends_at_s(entry) do
    entry
    |> first_present_value([
      "provider_counteroffer_ends_at_s",
      "counteroffer_ends_at_s",
      "counteroffer_end_s",
      "offered_ends_at_s",
      "offered_end_s"
    ])
    |> numeric_or_nil()
  end

  defp normalize_negotiation_state(nil), do: "unknown"

  defp normalize_negotiation_state(value) do
    value
    |> normalize_status_value()
    |> case do
      state when state in @negotiation_states -> state
      state when state in ["proposal", "offered", "offer", "new"] -> "proposed"
      state when state in ["open", "in_review", "review", "review_required"] -> "pending"
      state when state in ["approved", "confirmed", "accepted_by_operator"] -> "accepted"
      state when state in ["declined", "denied", "provider_rejected"] -> "rejected"
      state when state in ["timed_out", "timeout", "lapsed"] -> "expired"
      state when state in ["cancelled", "withdrawn", "withdraw"] -> "canceled"
      _state -> "unknown"
    end
  end

  defp stable_id_or_nil(value) when value in [nil, ""], do: nil
  defp stable_id_or_nil(value), do: stable_id!(value)

  defp stable_id!(value) when is_binary(value) do
    if value != "nil" and Regex.match?(@stable_id_pattern, value) do
      value
    else
      raise ArgumentError,
            "station calendar provider_counteroffer_id must match stable ID pattern"
    end
  end

  defp stable_id!(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id!()
  end

  defp stable_id!(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> stable_id!()
  end

  defp stable_id!(_value) do
    raise ArgumentError, "station calendar provider_counteroffer_id must match stable ID pattern"
  end

  defp first_present_value(map, keys) do
    keys
    |> Enum.map(&Map.get(map, &1))
    |> Enum.find(fn value -> value not in [nil, ""] end)
  end

  defp normalize_status_value(nil), do: nil

  defp normalize_status_value(value) do
    value
    |> encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
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

  defp value_present?(value), do: value not in [nil, ""]

  defp encode_value(value) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 6)

  defp encode_value(value), do: to_string(value)
end
