defmodule EC2Ssh.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ec2_ssh,
      escript: [main_module: EC2Ssh],
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ex_aws, :hackney, :httpoison, :sweet_xml]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws, "~> 1.0"},
      {:poison, "~> 2.0"},
      {:httpoison, "~> 0.9"},
      {:hackney, "~> 1.6"},
      {:configparser_ex, "~> 0.2.1"},
      {:sweet_xml, "~> 0.3"},
      {:erlsom, "~> 1.4"}
    ]
  end
end
