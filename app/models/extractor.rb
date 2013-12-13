class Extractor
  def self.fetch(params)

    if (params[:endpoint_type] == 'oai_dc')
      return JsonEt::Extract::OaiDc.fetch(params)
    else
      return "Endpoint Type `#{params[:endpoint_type]}` Not Found"
    end
  end

  private
  def self.sha(params)
     Digest::SHA1.hexdigest("#{params[:endpoint]}#{params[:endpoint_type]}#{params[:query_params]}")
  end
end
