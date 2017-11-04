defmodule EC2Ssh do
  @moduledoc """
  Documentation for EC2Ssh.
  """

  @doc """
  TODO
  """
  def instances_info do
    {:ok, %{body: body}} =
      ExAws.EC2.describe_instances
      |> ExAws.request(region: "ap-northeast-1")

    xml = String.replace(body, ~r/\sxmlns=\".*\"/, "")
    {ok, tuples, _} = :erlsom.simple_form(xml)
    parse(tuples)
  end

  def parse([values]) when is_tuple(values) do
    parse(values)
  end

  def parse([values]) do
    to_string(values) |> String.trim
  end

  def parse({name, attr, content}) do
    parsed_content = parse(content)
    case is_map(parsed_content) do
      true ->
        %{to_string(name) => parsed_content |> Map.merge(attr_map(attr))}
      false ->
        %{to_string(name) => parsed_content}
    end
  end

  def parse(list) when is_list(list) do
    parsed_list = Enum.map(list, &({to_string(elem(&1,0)), parse(&1)}))
    Enum.reduce(parsed_list, %{}, fn({k,v}, acc) ->
      case Map.get(acc, k) do
        nil -> Map.put_new(acc, k, v[k])
        [h|t] -> Map.put(acc, k, [h|t] ++ [v[k]])
        prev -> Map.put(acc, k, [prev] ++ [v[k]])
      end
    end)
  end

  defp attr_map(list) do
    list
    |> Enum.map(fn({k,v}) ->
      {to_string(k), to_string(v)}
    end)
    |> Map.new
  end

  defp handle_response({:ok, %{body: body}}) do
    body
    # |> xpath(~x"//instancesSet/item"l, private_ip_addr: ~x"./privateIpAddress/text()", ip_addr: ~x"./ipAddress/text()")
    # |> extract_entries
    # |> handle_response

    # sweet_xml sample
    # res = body |> xpath(~x"//item/instanceState/name/text()"l)
  end

  defp handle_response({_, %{body: body}}) do
    IO.inspect "error response"
    IO.inspect body
  end

  def extract_entries(records) do
    [head | _] = records
    extract_entries([head | []], [])
  end

  def extract_entries([%{private_ip_addr: private_ip_addr, ip_addr: ip_addr} | tail], res) do
    extract_entries(tail, [{private_ip_addr, ip_addr} | res])
  end

  def extract_entries([], res), do: res
end
