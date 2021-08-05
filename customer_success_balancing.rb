# +++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Autor: Danilo Souza Tixeira                          +
#  Data: 05/08/2021                                     +
#  Fone: (62) 98292-6675                                +
#  Linkedin: https://www.linkedin.com/in/danilosouzat/  +
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++

require 'minitest/autorun'
require 'timeout'
require 'byebug'

# This class ranks which manager is responsible for the most customers.
class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    @customer_success_present = remove_absent_customers_success(@away_customer_success)
    cs_group = count_number_of_customers_cs(@customer_success_present, @customers)
    customer_success_ranked = cs_group.max_by(2) { |hash_cs| hash_cs[:customers_count] }
    compare_scores(customer_success_ranked)
  end

  private

  # check if the scores of two customer success are the same
  def compare_scores(array_cs_ranked)
    return 0 if array_cs_ranked.empty?

    if array_cs_ranked.first[:customers_count] == array_cs_ranked.last[:customers_count]
      0
    else
      cs_ranked = array_cs_ranked.max_by { |cs| cs[:customers_count] }
      cs_ranked[:customers_count].zero? ? 0 : cs_ranked[:cs_id]
    end
  end

  # count how many customers each customer success has
  def count_number_of_customers_cs(customer_success, customers)
    array_total = []
    customer_success.each do |hash_cs|
      array_total << {
        cs_id: hash_cs[:id],
        customers_count: customers.count { |customer| customer[:score] < hash_cs[:score] }
      }
      customers.delete_if { |customer| customer[:score] < hash_cs[:score] }
    end

    array_total
  end

  def remove_absent_customers_success(array_cs_ids)
    array_cs_ids.each do |cs_id|
      @customer_success.delete_if { |cs| cs[:id] == cs_id }
    end

    @customer_success.sort_by { |cs| cs[:score]}
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(100_00, 998)),
      [999]
    )
    result = Timeout.timeout(1.8) { balancer.execute }
    assert_equal 0, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index(1) do |score, index|
      { id: index, score: score }
    end
  end
end
