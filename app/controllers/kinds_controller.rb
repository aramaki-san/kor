class KindsController < ApplicationController
  layout 'normal_small'

  def index
    @kinds = Kind.by_parent(params[:parent_id])

    respond_to do |format|
      format.html {render :layout => 'wide'}
      format.json
    end
  end

  def show
    @kind = Kind.find(params[:id])
    
    respond_to do |format|
      format.json do
        render :json => @kind
      end
    end
  end

  def new
    @kind = Kind.new
  end

  def edit
    @kind = Kind.find(params[:id])
  end
  
  def create
    @kind = Kind.new(kind_params)

    respond_to do |format|
      format.html do
        if @kind.save
          flash[:notice] = I18n.t( 'objects.create_success', :o => Kind.model_name.human )
          redirect_to :action => 'index'
        else
          render :action => "new"
        end
      end
      format.json do
        if @kind.save
          @message = I18n.t( 'objects.create_success', :o => Kind.model_name.human )
          render action: 'save'
        else
          render action: 'save', status: 406
        end
      end
    end
  end

  def update
    @kind = Kind.find(params[:id])

    params[:kind] ||= {}
    params[:kind][:settings] ||= {}
    params[:kind][:settings][:tagging] ||= false
    
    respond_to do |format|
      format.html do
        if @kind.update_attributes(kind_params)
          flash[:notice] = I18n.t( 'objects.update_success', :o => Kind.model_name.human )
          redirect_to :action => 'index'
        else
          render :action => "edit"
        end
      end
      format.json do
        if @kind.update_attributes(kind_params)
          @message = I18n.t( 'objects.update_success', :o => Kind.model_name.human)
          render action: 'save'
        else
          render action: 'save', status: 406
        end
      end
    end
  end

  def destroy
    @kind = Kind.find(params[:id])
    
    respond_to do |format|
      format.html do
        unless @kind == Kind.medium_kind
          @kind.destroy
          redirect_to(kinds_url)
        else
          redirect_to denied_path
        end
      end
      format.json do
        unless @kind == Kind.medium_kind
          @kind.destroy
          @message = I18n.t( 'objects.destroy_success', :o => Kind.model_name.human)
          render action: 'save'
        else
          @message = "the medium kind can't be deleted"
          render action: 'save', status: 403
        end
      end
    end
  end
  
  
  protected
    
    def kind_params
      params.require(:kind).permit!
    end

    def generally_authorized?
      if action_name == 'index' || action_name == 'show'
        true
      else
        current_user.kind_admin?
      end
    end

end
