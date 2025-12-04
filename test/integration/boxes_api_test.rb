require "test_helper"

class BoxesApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
  end

  test "lists boxes for tenant" do
    tenant = tenants(:solver)

    get "/api/boxes", params: { token: generate_api_token(sub: tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal tenant.boxes.order(:id).pluck(:id), json_response.pluck("id")

    solver_box = boxes(:solver_main)
    solver_box_json = json_response.find { |box| box["id"] == solver_box.id }
    assert solver_box_json
    assert_equal solver_box.uri, solver_box_json["uri"]
    assert_equal solver_box.short_name, solver_box_json["short_name"]
    assert_equal solver_box.export_name, solver_box_json["export_name"]
    assert_equal solver_box.name, solver_box_json["name"]
    assert_equal solver_box.type, solver_box_json["type"]
    # assert_equal solver_box.active, solver_box_json["active"]
  end

  test "includes obo attribute for upvs boxes" do
    tenant = tenants(:ssd)

    get "/api/boxes", params: { token: generate_api_token(sub: tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    ssd_box = boxes(:ssd_other)
    ssd_box_json = json_response.find { |box| box["id"] == ssd_box.id }
    assert ssd_box_json
    assert_equal ssd_box.settings_obo, ssd_box_json["obo"]
  end

  test "includes dic attribute for fs boxes" do
    tenant = tenants(:accountants)

    get "/api/boxes", params: { token: generate_api_token(sub: tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    fs_box = boxes(:fs_accountants)
    fs_box_json = json_response.find { |box| box["id"] == fs_box.id }
    assert fs_box_json
    assert_equal fs_box.settings_dic, fs_box_json["dic"]
  end

  # test "includes active flag for boxes" do
  #   tenant = tenants(:accountants)
  #   inactive_box = boxes(:fs_accountants)
  #   inactive_box.update!(active: false)

  #   get "/api/boxes", params: { token: generate_api_token(sub: tenant.id, key_pair: @key_pair) }, as: :json

  #   assert_response :success
  #   json_response = JSON.parse(response.body)

  #   box_json = json_response.find { |box| box["id"] == inactive_box.id }
  #   assert box_json
  #   assert_equal false, box_json["active"]
  # end
end
