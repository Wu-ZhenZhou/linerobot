require "application_system_test_case"

class KeywordMappingsTest < ApplicationSystemTestCase
  setup do
    @keyword_mapping = keyword_mappings(:one)
  end

  test "visiting the index" do
    visit keyword_mappings_url
    assert_selector "h1", text: "Keyword mappings"
  end

  test "should create keyword mapping" do
    visit keyword_mappings_url
    click_on "New keyword mapping"

    fill_in "Channel", with: @keyword_mapping.channel_id
    fill_in "Keyword", with: @keyword_mapping.keyword
    fill_in "Message", with: @keyword_mapping.message
    click_on "Create Keyword mapping"

    assert_text "Keyword mapping was successfully created"
    click_on "Back"
  end

  test "should update Keyword mapping" do
    visit keyword_mapping_url(@keyword_mapping)
    click_on "Edit this keyword mapping", match: :first

    fill_in "Channel", with: @keyword_mapping.channel_id
    fill_in "Keyword", with: @keyword_mapping.keyword
    fill_in "Message", with: @keyword_mapping.message
    click_on "Update Keyword mapping"

    assert_text "Keyword mapping was successfully updated"
    click_on "Back"
  end

  test "should destroy Keyword mapping" do
    visit keyword_mapping_url(@keyword_mapping)
    click_on "Destroy this keyword mapping", match: :first

    assert_text "Keyword mapping was successfully destroyed"
  end
end
