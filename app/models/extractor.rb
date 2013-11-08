class Extractor
  def self.fetch(params)

    params[:query_limiters] = (params[:query_limiters] != nil) ? CGI::unescape(params[:query_limiters]) : params[:query_limiters]
    if (params[:endpoint_type] == 'oai_dc')
      return JsonEtl::Extract::OaiDc.fetch(params)
    else
      return "Endpoint Type `#{params[:endpoint_type]}` Not Found"
    end
  end

  private
  def self.sha(params)
     Digest::SHA1.hexdigest("#{params[:endpoint]}#{params[:endpoint_type]}#{params[:query_limiters]}")
  end
end
