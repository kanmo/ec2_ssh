defmodule Ec2SshTest do
  use ExUnit.Case
  doctest Ec2Ssh

  test "greets the world" do
    assert Ec2Ssh.hello() == :world
  end
end
