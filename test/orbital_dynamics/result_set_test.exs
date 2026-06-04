defmodule OrbitalDynamics.ResultSetTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.ResultSet

  test "creates result set data" do
    assert %ResultSet{
             study_id: :study,
             trajectory_results: [],
             event_results: [],
             errors: [],
             assumptions: %{},
             metadata: %{}
           } =
             ResultSet.new!(%{
               study_id: :study,
               trajectory_results: [],
               event_results: [],
               errors: [],
               assumptions: %{},
               metadata: %{}
             })
  end

  test "rejects invalid result set fields" do
    assert_raise ArgumentError, "trajectory_results must be a list", fn ->
      ResultSet.new!(%{
        study_id: :study,
        trajectory_results: :bad
      })
    end
  end
end
