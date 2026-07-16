defmodule OrbitalDynamics.Validation.ReferenceFixtureReport do
  @moduledoc false

  def build(observations_by_fixture, reference_fixtures, verify_reference_fixture)
      when is_map(observations_by_fixture) and is_map(reference_fixtures) and
             is_function(verify_reference_fixture, 2) do
    observations_by_fixture = stringify_keys(observations_by_fixture)

    reports =
      reference_fixtures
      |> Map.keys()
      |> Enum.sort()
      |> Enum.map(fn id ->
        case verify_reference_fixture.(id, Map.get(observations_by_fixture, id, %{})) do
          {:ok, report} ->
            report

          {:error, reason} ->
            reference_fixture_error_report(id, reason, reference_fixtures)
        end
      end)

    %{
      "schema_contract" => "validation_reference_fixture_report.v1",
      "status" => if(Enum.all?(reports, &(&1["status"] == "pass")), do: "pass", else: "fail"),
      "fixture_count" => length(reports),
      "status_counts" => count_rows_by_value(reports, "status"),
      "reports" => reports
    }
  end

  defp reference_fixture_error_report(id, reason, reference_fixtures) do
    {:ok, fixture} = Map.fetch(reference_fixtures, id)

    %{
      "schema_contract" => "validation_reference_report.v1",
      "fixture_id" => id,
      "model_id" => fixture["model_id"],
      "validation_level" => fixture["validation_level"],
      "status" => "fail",
      "status_counts" => %{"fail" => 1},
      "checks" => [
        %{
          "field" => "observations",
          "status" => "fail",
          "expected" => "valid observations map",
          "observed" => inspect(reason),
          "tolerance" => "valid observations map"
        }
      ]
    }
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

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
