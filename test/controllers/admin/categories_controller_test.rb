require "test_helper"

class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! Hosts.admin_host
    sign_in_as users(:elshohail_owner)
  end

  test "lists, creates, updates and deletes categories" do
    get admin_categories_path
    assert_select "#categories li", 3

    assert_difference -> { Category.count } do
      post admin_categories_path, params: { category: { name_ar: "ثلاجات", name_en: "Fridges", parent_id: categories(:ovens).id } }
    end
    assert_redirected_to admin_categories_path
    fridges = Category.last
    assert_equal stores(:elshohail), fridges.store
    assert_equal categories(:ovens), fridges.parent

    patch admin_category_path(fridges), params: { category: { active: "0" } }
    assert_not fridges.reload.active?

    delete admin_category_path(fridges)
    assert_redirected_to admin_categories_path
    assert_not Category.exists?(fridges.id)
  end

  test "invalid categories re-render the form" do
    post admin_categories_path, params: { category: { name_ar: "" } }
    assert_response :unprocessable_entity
    assert_select "#name_ar_error"
  end

  test "another store's categories are not reachable" do
    other = categories(:bare_drinks)

    get edit_admin_category_path(other)
    assert_response :not_found
    patch admin_category_path(other), params: { category: { name_ar: "x" } }
    assert_response :not_found
    delete admin_category_path(other)
    assert_response :not_found
    assert Category.exists?(other.id)
  end
end
