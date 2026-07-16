defmodule OrbitalDynamics.CampaignPlanner.ObjectiveWindowBounds do
  @moduledoc false

  def start(nil, default), do: default

  def start(%{"starts_at_s" => starts_at_s}, default),
    do: numeric_or_default(starts_at_s, default)

  def start(%{"start_s" => start_s}, default),
    do: numeric_or_default(start_s, default)

  def start(_objective, default), do: default

  def finish(nil, default), do: default

  def finish(%{"ends_at_s" => ends_at_s}, default),
    do: numeric_or_default(ends_at_s, default)

  def finish(%{"end_s" => end_s}, default),
    do: numeric_or_default(end_s, default)

  def finish(_objective, default), do: default

  defp numeric_or_default(value, default), do: numeric_or_nil(value) || default

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil
end
