class BaseSuppliersController < ApplicationController
  before_action :set_base_supplier, only: [:show, :edit, :update, :destroy]

  # GET /base_suppliers
  def index
    @base_suppliers = BaseSupplier.page(params[:page]).per(params[:per]).order(params[:order])
    if params[:s]
      like_search
      date_search
      range_search
      in_search
      equal_search
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

  def equal_search
    return unless params[:s]
    query = {}
    query.merge! params[:s]
    @base_suppliers = @base_suppliers.where(query) 
  end

  def like_search
    return unless params[:s][:like]
    params[:s][:like].each {|k,v| @base_suppliers = @base_suppliers.where("#{k} like ?",v)}
    params[:s].delete(:like)
  end

  def date_search
    return unless params[:s][:date]
    params[:s][:date].each do |k,v|
      arr = v.split(",")
      if arr.size==1
        day = DateTime.parse(arr[0])
        @base_suppliers = @base_suppliers.where(k => day.beginning_of_day..day.end_of_day)
      elsif arr.size==2
        day1 = DateTime.parse(arr[0])
        day2 = DateTime.parse(arr[1])
        @base_suppliers = @base_suppliers.where(k => day1.beginning_of_day..day2.end_of_day)
      else
        logger.warn("date search 错误: #{k},#{v}")
      end
    end
    params[:s].delete(:date)
  end

  def range_search
    return unless params[:s][:range]
    params[:s][:range].each do |k,v|
      arr = v.split(",")
      if arr.size==1
        v1 = arr[0].to_f
        operator = (v[0]==","?  "<=" : ">=")
        @base_suppliers = @base_suppliers.where("id #{operator} ?", v1)
      elsif arr.size==2
        v1 = arr[0].to_f
        v2 = arr[1].to_f
        @base_suppliers = @base_suppliers.where(k => v1..v2)
      else
        logger.warn("range search 错误: #{k},#{v}")
      end
    end
    params[:s].delete(:range)      
  end   

  def in_search
    return unless params[:s][:in]
    params[:s][:in].each do |k,v|
      arr = v.split(",")
      @base_suppliers = @base_suppliers.where("#{k} in (?)", arr)
    end
    params[:s].delete(:in)      
  end 
  
    # Use callbacks to share common setup or constraints between actions.
    def set_base_supplier
      @base_supplier = BaseSupplier.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def base_supplier_params
      params.require(:base_supplier).permit!
    end
end
