defmodule OrbitalDynamics.Validation.ReferenceFixtureVerification do
  @moduledoc false

  def verify(id, observations, reference_fixtures)
      when is_binary(id) and is_map(observations) and is_map(reference_fixtures) do
    with {:ok, fixture} <- Map.fetch(reference_fixtures, id) do
      observations = stringify_keys(observations)

      checks =
        fixture
        |> Map.fetch!("expected")
        |> Enum.map(fn {field, expected} ->
          tolerance = get_in(fixture, ["tolerances", field]) || 0.0
          observed = Map.get(observations, field)
          verify_field(field, expected, observed, tolerance)
        end)
        |> Enum.sort_by(& &1["field"])

      status =
        if Enum.all?(checks, &(&1["status"] == "pass")) do
          "pass"
        else
          "fail"
        end

      {:ok,
       %{
         "schema_contract" => "validation_reference_report.v1",
         "fixture_id" => id,
         "model_id" => fixture["model_id"],
         "validation_level" => fixture["validation_level"],
         "status" => status,
         "status_counts" => count_rows_by_value(checks, "status"),
         "checks" => checks
       }}
    end
  end

  def verify(_id, _observations, _reference_fixtures),
    do: {:error, {:invalid_field, "observations"}}

  defp verify_field(field, expected, observed, tolerance) when is_number(expected) do
    if is_number(observed) do
      error = abs(observed - expected)

      %{
        "field" => field,
        "status" => if(error <= tolerance, do: "pass", else: "fail"),
        "expected" => expected,
        "observed" => observed,
        "error" => error,
        "tolerance" => tolerance
      }
    else
      missing_field(field, expected, observed, tolerance)
    end
  end

  defp verify_field(field, expected, observed, tolerance) when is_list(expected) do
    if numeric_vector?(expected) and numeric_vector?(observed) and
         length(expected) == length(observed) do
      error =
        expected
        |> Enum.zip(observed)
        |> Enum.map(fn {expected_value, observed_value} ->
          abs(observed_value - expected_value)
        end)
        |> Enum.max(fn -> 0.0 end)

      %{
        "field" => field,
        "status" => if(error <= tolerance, do: "pass", else: "fail"),
        "expected" => expected,
        "observed" => observed,
        "max_abs_error" => error,
        "tolerance" => tolerance
      }
    else
      missing_field(field, expected, observed, tolerance)
    end
  end

  defp verify_field(field, expected, observed, tolerance) do
    %{
      "field" => field,
      "status" => if(observed == expected, do: "pass", else: "fail"),
      "expected" => expected,
      "observed" => observed,
      "tolerance" => tolerance
    }
  end

  defp missing_field(field, expected, observed, tolerance) do
    %{
      "field" => field,
      "status" => "fail",
      "expected" => expected,
      "observed" => observed,
      "reason" => "missing_or_invalid_observation",
      "tolerance" => tolerance
    }
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp numeric_vector?(values) when is_list(values),
    do: Enum.all?(values, &(is_integer(&1) or is_float(&1)))

  defp numeric_vector?(_values), do: false

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)

  defp stringify_keys(value), do: value
end
