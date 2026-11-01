profile_path = System.get_env("ORBITAL_DYNAMICS_TEST_PROFILE_PATH")

if profile_path do
  ExUnit.start(
    formatters: [ExUnit.CLIFormatter, OrbitalDynamics.TestSuite.ProfileFormatter],
    orbital_dynamics_test_profile_path: profile_path
  )
else
  ExUnit.start()
end
