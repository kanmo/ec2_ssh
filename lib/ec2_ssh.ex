defmodule EC2Ssh do
  @moduledoc """
  Documentation for EC2Ssh.
  """

  @doc """
  TODO
  """
  def main(_args) do
    {:ok, %{body: body}} =
      ExAws.EC2.describe_instances
      |> ExAws.request(region: "ap-northeast-1")

    xml = String.replace(body, ~r/\sxmlns=\".*\"/, "")
    {ok, tuples, _} = :erlsom.simple_form(xml)
    parse(tuples) |> select_elms |> format_print
  end

  def select_elms(instances) do
    list = instances["DescribeInstancesResponse"]["reservationSet"]["item"]
    Enum.map(list, fn(i) ->
      %{state: i["instancesSet"]["item"]["instanceState"]["name"],
        name: tag_name(i["instancesSet"]["item"]["tagSet"]["item"]),
        key: i["instancesSet"]["item"]["keyName"],
        privateIpAddr: i["instancesSet"]["item"]["privateIpAddress"],
        publicIpAddr: i["instancesSet"]["item"]["ipAddress"]}
    end)
  end

  def tag_name(tags) when is_list(tags) do
    name_tag = Enum.find(tags, fn t -> t["key"] == "Name" end)
    name_tag["value"]
  end

  def tag_name(tag) do
    tag["value"]
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

  def max_elm_len(instances_info, elm_name) do
    Enum.filter(instances_info, &(Map.get(&1, elm_name) != nil))
    |> Enum.map(&(Map.get(&1, elm_name)))
    |> Enum.max_by(&(String.length(&1)))
  end

  def format_print(instances_info) do
    Enum.map(instances_info, fn(i) ->
      Enum.join([Map.get(i, :state), Map.get(i, :name), Map.get(i, :privateIpAddr), Map.get(i, :publicIpAddr)], " ")
    end)
    |> Enum.each(&(IO.inspect(&1)))
  end
end
