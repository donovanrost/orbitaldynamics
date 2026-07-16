defmodule OrbitalDynamics.CampaignPlanner.ContactSuccessValue do
  @moduledoc false

  def value(%{} = activity, callbacks) do
    cond do
      Map.has_key?(activity, "contact_success") ->
        contact_success_field_value(activity, callbacks)

      Map.has_key?(activity, "contact_result") ->
        contact_result_field_value(activity, callbacks)

      true ->
        status_field_value(activity, "realized_status", callbacks) ||
          status_field_value(activity, "status", callbacks)
    end
  end

  def value(_activity, _callbacks), do: nil

  defp contact_success_field_value(activity, callbacks) do
    json_boolean_value = Keyword.fetch!(callbacks, :json_boolean_value)

    case json_boolean_value.(activity["contact_success"]) do
      bool when is_boolean(bool) -> if(bool, do: 1.0, else: 0.0)
      nil -> activity |> Map.delete("contact_success") |> value(callbacks)
    end
  end

  defp contact_result_field_value(activity, callbacks) do
    provider_result_success_value = Keyword.fetch!(callbacks, :provider_result_success_value)

    completed_fraction_success_value =
      Keyword.fetch!(callbacks, :completed_fraction_success_value)

    case provider_result_success_value.(activity["contact_result"]) do
      :failure -> 0.0
      :success -> completed_fraction_success_value.(activity, 1.0)
      :unknown -> activity |> Map.delete("contact_result") |> value(callbacks)
    end
  end

  defp status_field_value(activity, field, callbacks) do
    failure_statuses = Keyword.fetch!(callbacks, :failure_statuses)
    completion_statuses = Keyword.fetch!(callbacks, :completion_statuses)

    completed_fraction_success_value =
      Keyword.fetch!(callbacks, :completed_fraction_success_value)

    status = Map.get(activity, field)

    cond do
      status in failure_statuses ->
        0.0

      status in completion_statuses ->
        completed_fraction_success_value.(activity, 1.0)

      status == "partial" ->
        completed_fraction_success_value.(activity, 0.5)

      true ->
        nil
    end
  end
end
