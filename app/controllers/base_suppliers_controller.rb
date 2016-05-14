class BaseSuppliersController < ApplicationController
  before_action :set_base_supplier, only: [:show, :edit, :update, :destroy]

  # GET /base_suppliers
  def index
    @base_suppliers = BaseSupplier.page(params[:page]).per(params[:per]).order(params[:order])
    if params[:s]
      if params[:s][:like]
        params[:s][:like].each {|k,v| @base_suppliers = @base_suppliers.where("#{k} like ?",v)}
      end
      params[:s].delete(:like)
      if params[:s]
        query = {}
        query.merge! params[:s]
        @base_suppliers = @base_suppliers.where(query) 
      end
    end
    @base_suppliers
  end

  # GET /base_suppliers/1
  def show
  end

  # GET /base_suppliers/new
  def new
    @base_supplier = BaseSupplier.new
  end

  # GET /base_suppliers/1/edit
  def edit
  end

  # POST /base_suppliers
  def create
    @base_supplier = BaseSupplier.new(base_supplier_params)

    if @base_supplier.save
      redirect_to @base_supplier, notice: 'Base supplier was successfully created.'
    else
      if request.format == 'application/json'
        render :status => 400, :json => {:error => @base_supplier.errors.full_messages.join("\n")}.to_json
      else
        render :new
      end
    end
  end

  # PATCH/PUT /base_suppliers/1
  def update
    if @base_supplier.update(base_supplier_params)
      redirect_to @base_supplier, notice: 'Base supplier was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /base_suppliers/1
  def destroy
    @base_supplier.destroy
    redirect_to base_suppliers_url, notice: 'Base supplier was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_base_supplier
      @base_supplier = BaseSupplier.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def base_supplier_params
      params.require(:base_supplier).permit!
    end
end
