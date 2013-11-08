class Transformer
  def self.fetch(params)
    if (params[:endpoint_type] == 'oai_dc')
      return JsonEtl::Transform::OaiDc.fetch(params)
    else
      return "Endpoint Type `#{params[:endpoint_type]}` Not Found"
    end
  end
end
