class Api::OaiPmh::RelationsController < Api::OaiPmh::BaseController

  def get_record
    @record = locate(params[:identifier])

    if @record
      render :template => "api/oai_pmh/get_record"
    else
      render_error 'idDoesNotExist'
    end
  end

  protected

    def records
      Relation.order(:id).with_deleted
    end

    def base_url
      api_oai_pmh_relations_url
    end

    def earliest_timestamp
      model = records.order(:created_at).first
      model ? model.created_at : super
    end

end