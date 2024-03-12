require 'minitest/autorun'
require './api'

class ApplesApiTest < Minitest::Test
  def app
    Apples::API
  end

  def test_get_method_not_allowed
    resp = response_for(path: '/api/orders')
    assert_equal 405, resp.status
  end

  def test_post_invalid
    resp = response_for(method: :post, path: '/api/orders')
    assert_equal 400, resp.status
  end

  def test_post_valid_attributes
    input = {order: {baskets: [{color: 'red', count: 4}]}}
    resp = response_for(method: :post, path: '/api/orders', body: input)
    assert_equal 201, resp.status
    assert_includes resp.body[0], '"color":"red"'
  end

  def test_post_valid_attributes_with_default
    input = {order: {baskets: [{color: 'red'}]}}
    resp = response_for(method: :post, path: '/api/orders', body: input)
    assert_equal 201, resp.status
    assert_includes resp.body[0], '"color":"red"'
    assert_includes resp.body[0], '"count":10'
  end

  def test_post_invalid_wrong_attributes
    input = {order: {baskets: [{clor: 'red', count: 'blue'}]}}
    resp = response_for(method: :post, path: '/api/orders', body: input)
    assert_equal 400, resp.status
    error_message = JSON.parse(resp.body.first)['error']
    assert_includes error_message, '[color] is missing'
    assert_includes error_message, '[count] must be an integer'
  end

  def test_post_invalid_wrong_attributes_2
    input = {order: {baskets: [{clor: 10, count: 'red'}]}}
    resp = response_for(method: :post, path: '/api/orders', body: input)
    assert_equal 400, resp.status
    error_message = JSON.parse(resp.body.first)['error']
    # We fail here:
    assert_equal "order[baskets][0][color] is missing, order[baskets][0][count] must be an integer",
                 error_message
  end

  def test_post_too_many_baskets
    input = {order: {baskets: [{color: 'red', count: 5}] * 11}}
    resp = response_for(method: :post, path: '/api/orders', body: input)
    assert_equal 400, resp.status
    error_message = JSON.parse(resp.body.first)['error']
    assert_equal 'order contains too many baskets', error_message
  end

  private

  def response_for(method: :get, body: nil, path:)
    input = nil

    if body
      body = JSON.dump(body) if body.is_a?(Hash)
      input = body
    end

    env = Rack::MockRequest.env_for(
      path,
      method: method,
      'CONTENT_TYPE' => 'application/json',
      input: input
    )

    Rack::Response[*app.call(env)]
  end
end
