defmodule OrbitalDynamics.Timeline.CommandWindowContext do
  @moduledoc false

  @command_window_activity_types ~w(command tracking health_check)

  def build(activity, callbacks) when is_list(callbacks) do
    if command_window_context_relevant?(activity) do
      %{
        "command_window_id" => activity_command_window_id(activity, callbacks),
        "command_window_type" => activity_command_window_type(activity)
      }
      |> compact_map(callbacks)
    else
      %{}
    end
  end

  defp command_window_context_relevant?(activity) do
    activity["type"] in @command_window_activity_types or
      is_map(activity["command_window"]) or
      is_binary(activity["command_window_id"]) or
      is_binary(activity["command_window_type"]) or
      is_binary(activity["window_type"]) or
      is_binary(get_in(activity, ["metadata", "command_window_id"])) or
      is_binary(get_in(activity, ["metadata", "command_window_type"]))
  end

  defp activity_command_window_id(activity, callbacks) do
    activity["command_window_id"] ||
      get_in(activity, ["command_window", "id"]) ||
      get_in(activity, ["metadata", "command_window_id"]) ||
      inferred_command_window_id(activity, callbacks)
  end

  defp inferred_command_window_id(activity, callbacks) do
    case activity_id(activity, callbacks) do
      "" -> nil
      activity_id -> "command_window:#{activity_id}"
    end
  end

  defp activity_command_window_type(activity) do
    activity["command_window_type"] ||
      activity["window_type"] ||
      get_in(activity, ["command_window", "type"]) ||
      get_in(activity, ["command_window", "window_type"]) ||
      get_in(activity, ["metadata", "command_window_type"]) ||
      infer_command_window_type(activity)
  end

  defp infer_command_window_type(%{"type" => "command"}), do: "command_window"
  defp infer_command_window_type(%{"type" => "health_check"}), do: "health_check_window"
  defp infer_command_window_type(%{"type" => "tracking"}), do: "tracking_window"
  defp infer_command_window_type(%{"direction" => "tracking"}), do: "tracking_window"
  defp infer_command_window_type(%{"direction" => "uplink"}), do: "uplink_window"
  defp infer_command_window_type(%{"direction" => "command"}), do: "command_window"
  defp infer_command_window_type(_activity), do: "command_context_window"

  defp activity_id(activity, callbacks),
    do: apply(Keyword.fetch!(callbacks, :activity_id), [activity])

  defp compact_map(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :compact_map), [value])
end
