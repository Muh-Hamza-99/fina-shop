class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: %i[ edit update destroy ]

  def index
    @categories = Current.store.categories.tree
  end

  def new
    @category = Current.store.categories.new(parent_id: params[:parent_id])
  end

  def create
    @category = Current.store.categories.new(category_params)

    if @category.save
      redirect_to admin_categories_path, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy!
    redirect_to admin_categories_path, notice: t(".destroyed"), status: :see_other
  end

  private
    def set_category
      @category = Current.store.categories.find(params[:id])
    end

    def category_params
      params.expect(category: %i[ name_ar name_en description_ar description_en parent_id active ])
    end
end
