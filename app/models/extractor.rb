class Extractor
  def self.fetch(params)
    params[:query_params] = params[:query_params] ? CGI::unescape(params[:query_params]) : params[:query_params]
    if (params[:endpoint_type] == 'oai_dc')
      return JsonEtl::Extract::OaiDc.fetch(params)
    else
      return "Endpoint Type `#{params[:endpoint_type]}` Not Found"
    end
  end

  private
  def self.sha(params)
     Digest::SHA1.hexdigest("#{params[:endpoint]}#{params[:endpoint_type]}#{params[:query_params]}")
  end
end
