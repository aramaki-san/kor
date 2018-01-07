class ApplicationController < BaseController

  helper :all
  helper_method :back, :back_save, :home_page, :kor_graph
  
  before_filter :locale, :authentication, :authorization, :legal
  around_filter :profile


  private

    # redirects to the legal page if terms have not been accepted
    def legal
      if current_user && !current_user.guest? && !current_user.terms_accepted
        redirect_to :controller => 'static', :action => 'legal'
      end
    end

    # rescue_from StandardError do |exception|
    #   if Rails.env == 'production'
    #     Kor::ExceptionLogger.log exception, params: params
    #   end

    #   respond_to do |format|
    #     format.html {raise exception}
    #     format.json {
    #       if Rails.env.test?
    #         raise exception
    #       else
    #         render status: 500, json: {
    #           'message' => exception.message,
    #           'backtrace' => exception.backtrace
    #         }
    #       end
    #     }
    #   end
    # end

    rescue_from ActiveRecord::RecordNotFound, with: :render_404

    def authentication
      session[:user_id] ||= if User.guest
        session[:expires_at] = Kor.session_expiry_time
        User.guest.id
      end

      if !current_user
        respond_to do |format|
          format.html do
            unless controller_name.match(/tpl/)
              history_store
            end
            redirect_to login_path
          end
          format.json do
            render :json => {:notice => I18n.t('notices.access_denied')}, :status => 403
          end
        end
      elsif session_expired?
        session[:user_id] = nil
        
        respond_to do |format|
          format.html do
            history_store unless request.path.match(/^\/blaze/)
            flash[:notice] = I18n.t('notices.session_expired')
            redirect_to login_path
          end
          format.json do
            render :json => {:notice => I18n.t('notices.session_expired')}, :status => 403
          end
        end
      else
        Rails.logger.info("Auth: user '#{current_user.name}' has been seen")
        session[:expires_at] = Kor.session_expiry_time
      end
    end
    
    def authorization
      render_403 unless generally_authorized?
    end

    def render_403
      respond_to do |format|
        format.html do
          flash[:error] = I18n.t('notices.access_denied')
          render template: 'authentication/denied', status: 403
        end
        format.json do
          render json: {message: I18n.t('notices.access_denied')}, status: 403
        end
      end
    end

    def render_404
      render 'layouts/404', status: 404
    end

    def session_expired?
      if !current_user.guest? && !api_auth?
        !!(session[:expires_at] && (session[:expires_at] < Time.now))
      end
    end

    def api_auth?
      key = params[:api_key] || request.headers["HTTP_API_KEY"]
      key && User.exists?(api_key: key)
    end
    
    def generally_authorized?
      true
    end
    
    
  protected

    def locale
      if current_user && current_user.locale
        I18n.locale = current_user.locale
      else
        I18n.locale = Kor.config['locale'] || I18n.default_locale
      end
    end

    def param_to_array(value, options = {})
      options.reverse_merge! ids: true

      case value
        when String
          results = value.split(',')
          options[:ids] ? results.map{|v| v.to_i} : results
        when Integer then [value]
        when Array then value.map{|v| param_to_array(v, options)}.flatten
        when nil then []
        else
          raise "unknown param format to convert to array: #{value}"
      end
    end

    def user_groups
      UserGroup.owned_by(current_user)
    end
    
    def history_store(url = nil)
      url ||= request.url
      if current_user && !current_user.guest?
        current_user.history_push url
      end
    end
    
    def back
      if current_user && !current_user.guest?
        current_user.history_pop
      end
    end
    
    def back_save
      back || home_page || root_url
    end
    
    def home_page
      (current_user ? current_user.home_page : nil ) || root_url
    end
    
    def kor_graph
      @kor_graph ||= Kor::Graph.new(:user => current_user)
    end

    def current_entity
      session[:current_entity]
    end

    def entity_params
      params.require(:entity).permit(
        :lock_version,
        :kind_id,
        :collection_id,
        :name, :distinct_name, :subtype, :comment, :no_name_statement,
        :tag_list,
        :synonyms => [],
        :new_datings_attributes => [
          :id, :_destroy, :label, :dating_string, :lock_version
        ],
        :existing_datings_attributes => [
          :id, :_destroy, :label, :dating_string, :lock_version
        ],
        :dataset => params[:entity][:dataset].try(:keys),
        :properties => [:label, :value],
        :medium_attributes => [:id, :image, :document]
      ).tap do |e|
        e[:properties] ||= []
        e[:synonyms] ||= []
      end
    end

    def profile
      if ENV["PROFILE"]
        require 'perftools'
        path = request.path.gsub("/", "_")
        path = "#{Rails.root}/tmp/profiles/#{path}"
        PerfTools::CpuProfiler.start(path) do
          yield
        end
      else
        yield
      end
    end

end
