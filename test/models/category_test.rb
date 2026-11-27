require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  setup { @store = stores(:elshohail) }

  test "allows three levels and nothing deeper" do
    level3 = @store.categories.create!(name_ar: "مستوى ٣", parent: categories(:commercial_ovens))
    assert_equal 3, level3.depth

    assert_not @store.categories.new(name_ar: "مستوى ٤", parent: level3).valid?

    # Moving a two-level branch (ovens > commercial ovens > level 3) under another category would make it four deep.
    categories(:ovens).parent = categories(:mixers)
    assert_not categories(:ovens).valid?
  end

  test "parent must be from the same store and not create a loop" do
    assert_not @store.categories.new(name_ar: "فرعي", parent: categories(:bare_drinks)).valid?

    categories(:ovens).parent = categories(:commercial_ovens)
    assert_not categories(:ovens).valid?
  end

  test "possible parents exclude the category's own branch and anything too deep" do
    assert_equal [ categories(:mixers) ], categories(:ovens).possible_parents
  end

  test "new categories go to the end of their siblings" do
    assert_equal 3, @store.categories.create!(name_ar: "ثلاجات").position
  end

  test "deleting a category moves its subcategories up a level" do
    categories(:ovens).destroy!
    assert_nil categories(:commercial_ovens).reload.parent_id
  end
end
