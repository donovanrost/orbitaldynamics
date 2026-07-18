defmodule OrbitalDynamics.Timeline.SourceWindowNormalizationPolicy do
  @moduledoc false

  def normalize(
        %{"source_window" => %{} = source_window} = activity,
        put_new_present
      ) do
    activity
    |> put_new_present.("source_window_id", source_window_id_value(source_window))
    |> put_new_present.("source_window_type", source_window_type_value(source_window))
    |> put_new_present.("source_window_type", Map.get(activity, "source_window_kind"))
    |> put_new_present.(
      "source_window_type",
      get_in(activity, ["metadata", "source_window_kind"])
    )
  end

  def normalize(
        %{"metadata" => %{"source_window" => %{} = source_window}} = activity,
        put_new_present
      ) do
    activity
    |> Map.put("source_window", source_window)
    |> put_new_present.("source_window_id", source_window_id_value(source_window))
    |> put_new_present.("source_window_type", source_window_type_value(source_window))
    |> put_new_present.(
      "source_window_type",
      get_in(activity, ["metadata", "source_window_kind"])
    )
  end

  def normalize(activity, put_new_present) do
    activity
    |> put_new_present.("source_window_type", Map.get(activity, "source_window_kind"))
    |> put_new_present.(
      "source_window_type",
      get_in(activity, ["metadata", "source_window_kind"])
    )
  end

  defp source_window_id_value(%{} = source_window) do
    Map.get(source_window, "id") || Map.get(source_window, "window_id")
  end

  defp source_window_type_value(%{} = source_window) do
    Map.get(source_window, "type") || Map.get(source_window, "kind") ||
      Map.get(source_window, "window_type")
  end
end
