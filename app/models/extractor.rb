class Extractor
  include ServiceLog
  def self.fetch(params)
    if (params[:endpoint_type] == 'oai_dc')
      extractor = JsonEt::Extract::OaiDc.new
      return extractor.fetch(params)
    else
      return "Endpoint Type `#{params[:endpoint_type]}` Not Found"
    end
  end

  private
  def self.sha(params)
     Digest::SHA1.hexdigest("
      #{params[:endpoint]}
      #{params[:endpoint_type]}
      #{params[:query_params]}
      #{params[:batch_param]}
      #{params[:pretty]}")
  end
end
