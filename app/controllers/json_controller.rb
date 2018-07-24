# TODO: test this
class JsonController < BaseController

  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found

  before_filter :auth, :legal

  helper_method :inclusion


  protected

    def render_created(record)
      @record = record
      object_name = @record.try(:display_name) || record.class.model_name.human
      render_200 I18n.t('objects.create_success', o: object_name)
    end

    def render_updated(record)
      @record = record
      object_name = @record.try(:display_name) || record.class.model_name.human
      render_200 I18n.t('objects.update_success', o: object_name)
    end

    def render_200(message)
      @message = message
      render template: 'layouts/message', status: 200
    end

    def render_400(message)
      @message = message
      render template: 'layouts/message', status: 400
    end 

    def render_401(message)
      @message = message || I18n.t('notices.not_logged_in')
      render template: 'layouts/message', status: 401
    end

    def render_403(message = nil)
      @message = message || I18n.t('notices.access_denied')
      render template: 'layouts/message', status: 403
    end

    def render_record_not_found(exception)
      render_404 exception.message
    end

    def render_404(message = nil)
      @message = message || I18n.t('messages.not_found')
      render template: 'layouts/message', status: 404
    end

    def render_406(errors, message = nil)
      @errors = errors
      @message = message || I18n.t('activemodel.errors.template.header')
      render template: 'layouts/message', status: 406
    end

    def render_500(message = nil)
      @message = message || I18n.t('errors.exception_ocurred')
      render template: 'layouts/message', status: 500
    end

    def auth

    end

    def for_actions(*actions)
      if actions.include?(params[:action])
        yield
      end
    end

    def require_user
      render_401 unless current_user
    end

    def require_role(role)
      if current_user
        render_403 unless current_user.send("#{role}?".to_sym)
      else
        render_401
      end
    end

    def require_admin
      require_role 'admin'
    end

    def require_relation_admin
      require_role 'relation_admin'
    end

    def require_authority_group_admin
      require_role 'authority_group_admin'
    end

    def require_kind_admin
      require_role 'kind_admin'
    end

    # deny service if there is no guest and when we are unauthenticated
    # def authentication
    #   if !current_user
    #     render_403
    #   end
    # end

    # # TODO: make this a whitelist?
    # def role_authorized?
    #   true
    # end

    # def role_auth
    #   if current_user
    #     render_403 unless role_authorized?
    #   end
    # end

    # redirects to the legal page if terms have not been accepted
    def legal
      if current_user && !current_user.guest? && !current_user.terms_accepted
        redirect_to :controller => 'static', :action => 'legal'
      end
    end

    # TODO: get config values instead of 10 and 100
    # TODO: handle this like inclusion, so that we don't need the before filter
    def pagination
      @page = [(params[:page] || 1).to_i, 1].max
      @per_page = [
        (params[:per_page] || 10).to_i,
        100.to_i
      ].min
    end

    def inclusion
      param_to_array(params[:include], ids: false)
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

end