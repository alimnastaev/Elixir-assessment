defmodule Assessment do
  @moduledoc """
  A checkout system that adds products to a cart and displays the total price.
  """

  alias Assessment.Items
  alias Assessment.PricingRules

  def run() do
    Items.empty_basket()

    IO.puts(~s{\n Greetings! \n
    We can offer you today: \n
    1 - Green Tea
    2 - Strawberies
    3 - Coffee
    D - if you ready to pay

    Just specify item's number! \n
    })

    map_of_counted_items = ask_to_collect_items("What would you like to buy?: ")

    result = total_price(map_of_counted_items)

    IO.puts(
      "\nBasket: " <>
        red_color() <> "#{inspect(Map.to_list(map_of_counted_items))}" <> reset_color()
    )

    IO.puts("Total price expected: " <> red_color() <> "£#{result}" <> reset_color())

    Items.remove()
  end

  def total_price(map_of_counted_items) do
    Enum.reduce(map_of_counted_items, 0, fn {key, value}, acc -> count_price(key, value, acc) end)
  end

  defp count_price(:Green_Tea, value, acc), do: PricingRules.ceo(value) + acc
  defp count_price(:Strawberries, value, acc), do: PricingRules.coo(value) + acc
  defp count_price(:Coffee, value, acc), do: PricingRules.cto(value) + acc

  # Storing all items to use it later
  defp collect_answers(answer) do
    case answer do
      "1" ->
        Items.put_in_basket(:Green_Tea)
        ask_to_collect_items()

      "2" ->
        Items.put_in_basket(:Strawberries)
        ask_to_collect_items()

      "3" ->
        Items.put_in_basket(:Coffee)
        ask_to_collect_items()

      "D" ->
        IO.puts(yellow_color() <> "\n*** Thanks for your purchase! ***" <> IO.ANSI.reset())
        Items.checkout()

      _ ->
        IO.puts(~s{\n Make sure to type: \n
        1 for Green Tea
        2 for Strawberies
        3 for Coffee \n
        Don't forget, if you done with your purchuse just type D \n})

        ask_to_collect_items()
    end
  end

  # HELPERS functions
  defp ask_to_collect_items(question \\ "Something else?: ") do
    question
    |> IO.gets()
    |> String.trim()
    |> collect_answers()
  end

  defp red_color(), do: IO.ANSI.red()

  defp yellow_color(), do: IO.ANSI.yellow()

  defp reset_color(), do: IO.ANSI.reset()
end

defmodule Assessment.Items do
  @moduledoc """
  Using Agent to keep state from the input.
  Also tried ETS and GenServer as well.
  All works, but Agent is just a quicker implementation
  """

  def empty_basket(), do: Agent.start_link(fn -> %{} end, name: :basket)

  def put_in_basket(item),
    do: Agent.update(:basket, fn map -> Map.update(map, item, 1, &(&1 + 1)) end)

  def checkout(), do: Agent.get(:basket, & &1)

  def remove(), do: Agent.stop(:basket)
end

defmodule Assessment.PricingRules do
  require Integer

  # GREEN TEA
  @green_tea 3.11

  # STRAWBERRIES
  @strawberries_price 5.00
  @strawberries_discount_price 4.50

  # COFFEE
  @coffee_price 11.23
  @coffee_discount_price @coffee_price / 3

  # buy-one-get-one-free
  def ceo(green_teas) do
    cond do
      green_teas == 1 ->
        @green_tea

      Integer.is_even(green_teas) ->
        green_teas / 2 * @green_tea

      true ->
        (green_teas - 1) / 2 * @green_tea + @green_tea
    end
  end

  # buy 3 or more strawberries, the price should drop to £4.50
  def coo(strawberries) do
    if strawberries >= 3,
      do: strawberries * @strawberries_discount_price,
      else: strawberries * @strawberries_price
  end

  # buy 3 or more coffees for two thirds of the original price
  def cto(coffees) do
    if coffees >= 3, do: coffees * @coffee_discount_price, else: coffees * @coffee_price
  end
end

case System.argv() do
  ["--run"] ->
    Assessment.run()

  ["--test"] ->
    ExUnit.start()

    defmodule AssessmentTest do
      use ExUnit.Case

      test "tests according to the test data from assessment" do
        assert [
                 %{Coffee: 1, Green_Tea: 3, Strawberries: 1},
                 %{Green_Tea: 2},
                 %{Green_Tea: 1, Strawberries: 3},
                 %{Coffee: 3, Green_Tea: 1, Strawberries: 1}
               ]
               |> Enum.map(fn input_list -> Assessment.total_price(input_list) end) ==
                 [22.45, 3.11, 16.61, 19.34]
      end
    end

  _ ->
    IO.puts(:stderr, "\nplease specify --test or --run")
end
