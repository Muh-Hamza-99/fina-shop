# Product categories, up to three levels deep: main category > subcategory > sub-subcategory.
class Category < ApplicationRecord
  MAX_DEPTH = 3

  belongs_to :store
  belongs_to :parent, class_name: "Category", optional: true, inverse_of: :children
  has_many :children, -> { ordered }, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent

  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :id) }
  scope :tree, -> { roots.ordered.includes(children: :children) }

  normalizes :name_ar, :name_en, with: ->(value) { value.squish.presence }

  validates :name_ar, presence: true, uniqueness: { scope: %i[store_id parent_id] }
  validate :parent_fits_in_tree

  before_create :append_to_siblings
  # Subcategories move up to the deleted category's parent instead of being deleted.
  before_destroy { children.update_all(parent_id: parent_id) }

  def name(locale = I18n.locale)
    (locale.to_sym == :en && name_en.presence) || name_ar
  end

  def description(locale = I18n.locale)
    locale.to_sym == :en ? description_en.presence || description_ar : description_ar.presence || description_en
  end

  def ancestors
    parent ? [ parent, *parent.ancestors ] : []
  end

  # 1 for a main category, 3 for a sub-subcategory.
  def depth
    ancestors.size + 1
  end

  # Levels in this category's subtree, counting itself.
  def height
    1 + (children.map(&:height).max || 0)
  end

  def self_and_descendants
    [ self, *children.flat_map(&:self_and_descendants) ]
  end

  # Categories this one can be moved under without a loop or going deeper than MAX_DEPTH.
  def possible_parents
    excluded = persisted? ? self_and_descendants.map(&:id) : []
    store.categories.tree.flat_map(&:self_and_descendants)
      .reject { |candidate| excluded.include?(candidate.id) || candidate.depth + height > MAX_DEPTH }
  end

  private
    def parent_fits_in_tree
      return unless parent

      if parent.store_id != store_id || parent == self || parent.ancestors.include?(self) || parent.depth + height > MAX_DEPTH
        errors.add(:parent_id, :invalid)
      end
    end

    def append_to_siblings
      self.position = store.categories.where(parent_id: parent_id).maximum(:position).to_i + 1
    end
end
