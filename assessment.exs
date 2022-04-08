defmodule Assessment do
  @moduledoc """
  A checkout system that adds products to a cart and displays the total price.
  """

  alias Assessment.Items

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

    result = ask_to_collect_items("What would you like to buy?: ")

    IO.puts("Total price expected: " <> red_color() <> "£#{result}" <> reset_color())

    Items.remove()
  end

  # HELPERS functions
  defp ask_to_collect_items(question \\ "\nSomething else?: ") do
    question
    |> IO.gets()
    |> String.trim()
    |> collect_answers()
  end

  defp collect_answers("1") do
    Items.put_in_basket(:green_tea)
    ask_to_collect_items()
  end

  defp collect_answers("2") do
    Items.put_in_basket(:strawberries)
    ask_to_collect_items()
  end

  defp collect_answers("3") do
    Items.put_in_basket(:coffee)
    ask_to_collect_items()
  end

  defp collect_answers("D") do
    IO.puts(yellow_color() <> "\n*** Thanks for your purchase! ***\n" <> IO.ANSI.reset())

    Items.checkout()
  end

  defp collect_answers(_) do
    IO.puts(~s{\n Make sure to type: \n
        1 for Green Tea
        2 for Strawberies
        3 for Coffee \n
        Don't forget, if you done with your purchuse just type D \n})

    ask_to_collect_items()
  end

  defp red_color(), do: IO.ANSI.red()

  defp yellow_color(), do: IO.ANSI.yellow()

  defp reset_color(), do: IO.ANSI.reset()
end

defmodule Assessment.Items do
  @moduledoc """
  Using Agent to keep state from the input.
  Also tried ETS and GenServer as well.
  All work, but Agent is just a quicker implementation
  """

  alias Assessment.PricingRules

  def empty_basket(), do: Agent.start_link(fn -> %{} end, name: :basket)

  def put_in_basket(product) do
    Agent.update(:basket, fn basket ->
      cond do
        # basket is empty
        basket == %{} ->
          initial_price = count_price(product, 1)

          basket
          |> Map.put(product, [1, initial_price])
          |> Map.put(:total_price, initial_price)

        # # updating existing poduct
        is_map_key(basket, product) ->
          [counter, existing_product_price] = basket[product]

          updated_product_price = count_price(product, counter + 1)

          {updated_product_price, total_price} =
            if updated_product_price == existing_product_price do
              {existing_product_price, basket.total_price}
            else
              {updated_product_price,
               basket.total_price + (updated_product_price - existing_product_price)}
            end

          basket
          |> Map.put(product, [counter + 1, updated_product_price])
          |> Map.put(:total_price, total_price)

        # poduct not in the basket
        true ->
          updated_product_price = count_price(product, 1)

          basket
          |> Map.put(product, [1, updated_product_price])
          |> Map.put(:total_price, basket.total_price + updated_product_price)
      end
    end)
  end

  def checkout(), do: Agent.get(:basket, & &1.total_price)

  def remove(), do: Agent.stop(:basket)

  defp count_price(:green_tea, value), do: PricingRules.ceo(value)
  defp count_price(:strawberries, value), do: PricingRules.coo(value)
  defp count_price(:coffee, value), do: PricingRules.cto(value)
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
  def ceo(green_teas) when Integer.is_even(green_teas) do
    green_teas / 2 * @green_tea
  end

  def ceo(1 = _green_teas), do: @green_tea

  def ceo(green_teas) do
    (green_teas - 1) / 2 * @green_tea + @green_tea
  end

  # buy 3 or more strawberries, the price should drop to £4.50
  def coo(strawberries) when strawberries >= 3, do: strawberries * @strawberries_discount_price
  def coo(strawberries), do: strawberries * @strawberries_price

  # buy 3 or more coffees for two thirds of the original price
  def cto(coffees) when coffees >= 3, do: coffees * @coffee_discount_price
  def cto(coffees), do: coffees * @coffee_price
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
