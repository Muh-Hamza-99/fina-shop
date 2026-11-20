require "test_helper"
require "i18n/tasks"

class I18nTest < ActiveSupport::TestCase
  setup do
    @i18n = I18n::Tasks::BaseTask.new
  end

  test "no missing keys" do
    missing = @i18n.missing_keys
    assert_empty missing, "Missing #{missing.leaves.count} i18n keys, run `bundle exec i18n-tasks missing` to show them"
  end

  test "no unused keys" do
    unused = @i18n.unused_keys
    assert_empty unused, "#{unused.leaves.count} unused i18n keys, run `bundle exec i18n-tasks unused` to show them"
  end

  test "files are normalized" do
    non_normalized = @i18n.non_normalized_paths
    assert_empty non_normalized, "Not normalized: #{non_normalized.join(', ')}. Run `bundle exec i18n-tasks normalize` to fix"
  end
end
