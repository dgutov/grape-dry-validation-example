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

  def test_post_invalid_wrong_attributes
    input = {order: {baskets: [{clor: 'red', coont: 4}]}}
    resp = response_for(method: :post, path: '/api/orders', body: input)
    assert_equal 400, resp.status
    expected_errors = {'error' => 'order.color is missing, order.number is missing'}
    assert_equal expected_errors, JSON.parse(resp.body.first)
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
