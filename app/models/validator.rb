class Validator
      include ServiceLog
  def diff(params)
    a = JSON.parse(params[:record])
    b = dpla_json(CGI::unescape(params[:dpla_query_params]), params[:dpla_api_key])
    differ = JsonEt::Validate::Differ.new
    differ.path_compare(a, b, dpla_fields)
  end

  def dpla_json(query, api_key)
    data = ''
    open("http://api.dp.la/v2/items?#{query}&api_key=#{api_key}",) { |d|
      data = JSON.parse(d.read)
    }
    data['docs'][0]
  end

  def dpla_fields
    [
      "dataProvider",
      "hasView/@id",
      "hasView/format",
      "hasView/rights",
      "isShownAt",
      "isShownAt/@id",
      "isShownAt/format",
      "isShownAt/rights",
      "object",
      "rights",
      "format",
      "provider/id",
      "provider/name",
      "sourceResource/contributor",
      "sourceResource/creator",
      "sourceResource/date/begin",
      "sourceResource/date/displayDate",
      "sourceResource/date/end",
      "sourceResource/description",
      "sourceResource/extent",
      "sourceResource/format",
      "sourceResource/identifier",
      "sourceResource/language",
      "sourceResource/language/name",
      "sourceResource/language/iso63",
      "sourceResource/physicalMedium",
      "sourceResource/publisher",
      "sourceResource/rights",
      "sourceResource/spatial[0]",
      "sourceResource/stateLocatedIn/name",
      "sourceResource/stateLocatedIn/iso3166‑2",
      "sourceResource/subject",
      "sourceResource/subject/@id",
      "sourceResource/subject/@type",
      "sourceResource/subject/name",
      "sourceResource/temporal",
      "sourceResource/temporal/begin",
      "sourceResource/temporal/end",
      "sourceResource/title",
      "sourceResource/type"
    ]
  end

end







