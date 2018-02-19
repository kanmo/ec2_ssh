defmodule EC2Ssh do
  @moduledoc """
  Documentation for EC2Ssh.
  """

  @doc """
  TODO
  """
  def main(role_name \\ "default") do
    config = generate_config(role_name)

    {:ok, %{body: body}} =
      ExAws.EC2.describe_instances
      |> ExAws.request(config)

    xml = String.replace(body, ~r/\sxmlns=\".*\"/, "")
    {ok, tuples, _} = :erlsom.simple_form(xml)
    parse(tuples)
    |> filter_instances
    |> select_elms
    |> format_print
  end

  def generate_config(role_name) do
    [region: "ap-northeast-1",
     access_key_id: {:awscli, role_name, 30},
     secret_access_key: {:awscli, role_name, 30}]
  end

  def filter_instances(instances), do: instances["DescribeInstancesResponse"]["reservationSet"]["item"]

  def select_elms(nil) do
    IO.inspect("no instances...")
    []
  end

  def select_elms(item_list) do
    Enum.map(item_list, &(&1["instancesSet"]["item"]))
    |>  Enum.map(fn(i) ->
      to_instance_info(i)
    end)
    |> List.flatten
  end

  def to_instance_info(item) when is_list(item) do
    Enum.map(item, fn(i) ->
      %{state: i["instanceState"]["name"],
        name: tag_name(i["tagSet"]["item"]),
        key: i["keyName"],
        privateIpAddr: i["privateIpAddress"],
        publicIpAddr: i["ipAddress"]}
    end)
  end

  def to_instance_info(item) do
    %{state: item["instanceState"]["name"],
      name: tag_name(item["tagSet"]["item"]),
      key: item["keyName"],
      privateIpAddr: item["privateIpAddress"],
      publicIpAddr: item["ipAddress"]}
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
