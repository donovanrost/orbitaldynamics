defmodule OrbitalDynamics.Schema.LocalSearchValidationEnvelope do
  @moduledoc false

  alias OrbitalDynamics.Schema.{JsonSafety, PrimitiveValidation}

  @truncation_message "certificate validation envelope truncated to remain within JSON safety limits"

  def fit_issues(issues, envelope_fun) when is_list(issues) and is_function(envelope_fun, 1) do
    issues = normalize_issue_count(issues)
    envelope = envelope_fun.(issues)

    if JsonSafety.errors(envelope) == [] do
      {issues, envelope}
    else
      marker = truncation_marker(issues)
      regular = Enum.reject(issues, &truncation_issue?/1)
      fit_regular_issues(regular, marker, envelope_fun)
    end
  rescue
    _error -> minimal_envelope(envelope_fun)
  catch
    _kind, _reason -> minimal_envelope(envelope_fun)
  end

  def truncated?(issues) when is_list(issues), do: Enum.any?(issues, &truncation_issue?/1)
  def truncated?(_issues), do: true

  defp normalize_issue_count(issues) do
    maximum = JsonSafety.limits()["max_issues"]
    markers = Enum.filter(issues, &truncation_issue?/1)
    regular = Enum.reject(issues, &truncation_issue?/1)

    cond do
      length(issues) <= maximum and length(markers) <= 1 ->
        sort_issues(issues)

      true ->
        marker = List.first(markers) || truncation_marker([])

        regular
        |> Enum.take(maximum - 1)
        |> then(&sort_issues([marker | &1]))
    end
  end

  defp fit_regular_issues(regular, marker, envelope_fun) do
    maximum_regular = min(length(regular), JsonSafety.limits()["max_issues"] - 1)
    search_largest_fit(regular, marker, envelope_fun, 0, maximum_regular, nil)
  end

  defp search_largest_fit(_regular, _marker, envelope_fun, lower, upper, best)
       when lower > upper do
    best || minimal_envelope(envelope_fun)
  end

  defp search_largest_fit(regular, marker, envelope_fun, lower, upper, best) do
    count = div(lower + upper, 2)
    issues = regular |> Enum.take(count) |> then(&sort_issues([marker | &1]))
    envelope = envelope_fun.(issues)

    if JsonSafety.errors(envelope) == [] do
      search_largest_fit(regular, marker, envelope_fun, count + 1, upper, {issues, envelope})
    else
      search_largest_fit(regular, marker, envelope_fun, lower, count - 1, best)
    end
  end

  defp minimal_envelope(envelope_fun) do
    issues = [truncation_marker([])]
    {issues, envelope_fun.(issues)}
  end

  defp truncation_marker(issues) do
    Enum.find(issues, &truncation_issue?/1) ||
      PrimitiveValidation.error("$", @truncation_message)
  end

  def truncation_issue?(%{"message" => message}) when is_binary(message),
    do:
      String.contains?(message, "issue budget exhausted") or
        String.contains?(message, "validation envelope truncated")

  def truncation_issue?(_issue), do: false

  defp sort_issues(issues),
    do: Enum.sort_by(issues, &{&1["path"], &1["message"], &1["severity"]})
end
