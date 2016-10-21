class EntitiesController < ApplicationController
  layout 'normal_small', :only => [ :edit, :new, :update, :create, :recent, :invalid ]
  skip_before_filter :verify_authenticity_token

  respond_to :json, only: [:isolated]

  def metadata
    @entity = viewable_entities.find(params[:id])
    
    if @entity
      send_data(Kor::Export::MetaData.new(current_user).render(@entity),
        type: 'text/plain',
        filename: "#{@entity.id}.txt"
      )
    else
      flash[:error] = I18n.t('errors.not_found')
      redirect_to back_save
    end
  end

  def gallery
    respond_to do |format|
      format.json do
        entities = viewable_entities.media.newest_first
        @result = Kor::SearchResult.new(
          total: entities.count,
          page: params[:page],
          per_page: 16,
          records: entities.pageit(params[:page], 16)
        )
      end
    end
  end
  
  def invalid
    if authorized? :delete
      @group = SystemGroup.find_or_create_by(:name => 'invalid')
      @entities = @group.entities.allowed(current_user, :delete).paginate :page => params[:page], :per_page => 30
    else
      redirect_to denied_path
    end
  end
  
  def recent
    if authorized? :edit
      @entities = editable_entities.latest(1.week).searcheable.newest_first.within_collections(params[:collection_id]).paginate(
        page: params[:page],
        per_page: 30
      )
    else
      redirect_to denied_path
    end
  end

  def isolated
    if authorized? :edit
      entities = Entity.allowed(current_user, :view).isolated.newest_first.includes(:kind)
      @results = Kor::SearchResult.new(
        total: entities.count,
        page: params[:page],
        per_page: 16,
        records: entities.pageit(params[:page], 16)
      )

      render 'index'
    else
      render :nothing => true, :status => 403
    end
  end

  def recently_created
    entities = Entity.
      allowed(current_user, :view).
      by_relation_name(params[:relation_name]).
      newest_first.includes(:kind)

    @results = Kor::SearchResult.new(
      total: entities.count,
      page: params[:page],
      per_page: 9,
      records: entities.pageit(params[:page], 9)
    )

    render 'index'
  end

  def recently_visited
    history_entity_ids = current_user.history.map do |url|
      if m = url.match(/\/blaze\#\/entities\/(\d+)$/)
        m[1].to_i
      else
        nil
      end
    end
    binding.pry

    entities = Entity.
      allowed(current_user, :view).
      by_ordered_id_array(history_entity_ids.reverse).
      by_relation_name(params[:relation_name]).
      includes(:kind).
      newest_first

    @results = Kor::SearchResult.new(
      total: entities.count,
      page: params[:page],
      per_page: 9,
      records: entities.pageit(params[:page], 9)
    )

    render 'index'
  end

  def index
    params[:include] = param_to_array(params[:include], ids: false)
    params[:ids] = param_to_array(params[:ids])
    params[:kind_id] = param_to_array(params[:kind_id])
    params[:related_per_page] = [
      (params[:related_per_page] || 1).to_i,
      Kor.config['app']['max_included_results_per_result']
    ].min
    params[:related_relation_name] = param_to_array(params[:related_relation_name], ids: false)
    params[:related_kind_id] = param_to_array(params[:related_kind_id])

    respond_to do |format|
      format.json do
        @results = kor_graph.search(:attribute,
          criteria: {
            entity_id: params[:ids],
            name: params[:terms],
            relation_name: params[:relation_name],
            kind_id: params[:kind_id]
          },
          media: params[:include_media],
          per_page: params[:per_page],
          page: params[:page]
        )
      end
      format.html do
        if params[:query] && @entity = viewable_entities.find_by(:uuid => params[:query][:name])
          redirect_to web_path(:anchor => entity_path(@entity))
        else
          @query = kor_graph.search(:attribute,
            criteria: params[:query],
            page: params[:page]
          )
          render :layout => 'small_normal_bare'
        end
      end
    end
  end

  def show
    params[:include] = param_to_array(params[:include], ids: false)
    params[:related_per_page] = [
      (params[:related_per_page] || 10).to_i,
      Kor.config['app']['max_results_per_request']
    ].min
    params[:related_relation_name] = param_to_array(params[:related_relation_name], ids: false)
    params[:related_kind_id] = param_to_array(params[:related_kind_id])

    scope = Entity.includes(
      :medium, :kind, :collection, :datings, :creator, :updater, 
      authority_groups: :authority_group_category
    )
    id = (params[:id] || '').strip.presence
    if id.size == 36
      @entity = scope.find_by!(uuid: params[:id])
    else
      @entity = scope.find_by!(id: params[:id])
    end

    respond_to do |format|
      if allowed_to?(:view, @entity.collection)
        format.json
      else
        format.json { render nothing: true, status: 403 }
      end
    end
  end

  def new
    if authorized? :create, Collection.all, :required => :any
      @entity = Entity.new(:collection_id => current_user.default_collection_id)
      kind = Kind.find(params[:kind_id])
      @entity.kind = kind
      @entity.no_name_statement = 'enter_name'
      @entity.medium = Medium.new if @entity.kind_id == Kind.medium_kind.id
    else
      redirect_to denied_path
    end
  end
  
  def multi_upload
    render :layout => "blaze"
  end

  def edit
    @entity = Entity.find(params[:id])
    
    if authorized? :edit, @entity.collection
      render :action => 'edit'  
    else
      redirect_to denied_path
    end
  end

  def create
    @entity = Entity.new
    @entity.kind_id = params[:entity][:kind_id]
    @entity.assign_attributes entity_params

    if authorized?(:create, @entity.collection)
      @entity.creator_id = current_user.id

      if @entity.save
        if params[:user_group_name]
          transit = UserGroup.owned_by(current_user).find_or_create_by(:name => params[:user_group_name])
          transit.add_entities @entity if transit
        end

        if !params[:relation_name].blank? && current_entity
          Relationship.relate_and_save(@entity, params[:relation_name], current_entity)
        end
        
        respond_to do |format|
          format.html do
            flash[:notice] = I18n.t('objects.create_success', :o => @entity.display_name)
            redirect_to web_path(:anchor => entity_path(@entity))
          end
          format.json {render :json => {:success => true}}
        end
      else
        respond_to do |format|
          format.json do
            if @entity.medium && @entity.medium.errors[:datahash].present?
              if params[:user_group_name]
                transit = UserGroup.owned_by(current_user).find_or_create_by(:name => params[:user_group_name])

                if transit
                  @entity = Medium.where(:datahash => @entity.medium.datahash).first.entity
                  transit.add_entities @entity

                  render :json => {:success => true}
                  return
                end
              end
            end

            render :json => @entity.errors, status: 406
          end
          format.html {render action: "new", status: :not_acceptable}
        end
      end
    else
      redirect_to denied_path
    end
  end

  def update
    @entity = Entity.find(params[:id])
    
    authorized_to_edit = authorized?(:edit, @entity.collection)
    
    authorized_to_move = if @entity.collection_id == params[:entity][:collection_id].to_i
      true
    else
      authorized?(:delete, @entity.collection) && authorized?(:create, Collection.find(params[:entity][:collection_id]))
    end
    
    if authorized_to_edit && authorized_to_move
      @entity.updater_id = current_user.id

      if @entity.update_attributes(entity_params)
        SystemGroup.find_or_create_by(:name => 'invalid').remove_entities @entity
        flash[:notice] = I18n.t( 'objects.update_success', :o => @entity.display_name )
        redirect_to web_path(:anchor => entity_path(@entity))
      else
        render action: "edit"
      end
    else
      redirect_to denied_path
    end
  rescue ActiveRecord::StaleObjectError
    flash[:error] = I18n.t('activerecord.errors.messages.stale_entity_update')
    redirect_to action: 'edit'
  end

  def destroy
    @entity = Entity.find(params[:id])
    if authorized? :delete, @entity.collection
      @entity.destroy
      redirect_to back_save
    else
      redirect_to denied_path
    end
  end

end
