defmodule OrbitalDynamics.CampaignPlanner.RealizedActivitySuccessValues do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CommandSuccessValue,
    ContactSuccessValue,
    FeedbackNumericValues,
    ManeuverSuccessValue,
    ObservationSuccessValue,
    ProviderResultValues,
    ScalarValues
  }

  @completion_statuses ~w(completed executed)
  @failure_statuses ~w(missed failed canceled cancelled rejected)

  def contact(activity), do: contact(activity, callbacks())
  def contact(activity, callbacks), do: ContactSuccessValue.value(activity, callbacks)

  def observation(activity), do: observation(activity, callbacks())
  def observation(activity, callbacks), do: ObservationSuccessValue.value(activity, callbacks)

  def maneuver(activity), do: maneuver(activity, callbacks())
  def maneuver(activity, callbacks), do: ManeuverSuccessValue.value(activity, callbacks)

  def command(activity), do: command(activity, callbacks())
  def command(activity, callbacks), do: CommandSuccessValue.value(activity, callbacks)

  defp callbacks,
    do: [
      json_boolean_value: &ScalarValues.json_boolean_value/1,
      provider_result_success_value: &ProviderResultValues.success_value/1,
      completed_fraction_success_value: &completed_fraction_success_value/2,
      failure_statuses: @failure_statuses,
      completion_statuses: @completion_statuses
    ]

  defp completed_fraction_success_value(activity, default) do
    FeedbackNumericValues.completed_fraction_success_value(
      activity,
      default,
      feedback_numeric_callbacks()
    )
  end

  defp feedback_numeric_callbacks,
    do: [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      feedback_value_missing?: &feedback_value_missing?/1
    ]

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false
end
