ParametersParser =
  parse: (parameters) ->
    tokens = @tokenize(parameters)

    if tokens.filters
      tokens.filters = tokens.filters.map @parseFilter
      tokens.filters = tokens.filters.map @resolveAttributes

      # filter the filters so that only "truthy" values remain.
      # i.e. filters that were not recognized are removed
      tokens.filters = tokens.filters.filter (elm) => elm

    return tokens

  resolveAttributes: (filter) ->
    {type, attributes} = filter

    if type is "watermark"
      behaviors = [
        "tile"
        "cover"
        "center"
        "north_east"
        "south_east"
        "north_west"
        "south_west"
        "top"
        "bottom"
      ]

      # watermark(filename, x, y, opacity)
      if attributes.length is 4
        [filter.file, filter.x, filter.y, filter.opacity] = attributes

      # watermark(filename, opacity, behavior)
      else if attributes.length is 3 and attributes[2] in behaviors
        [filter.file, filter.opacity, filter.behavior] = attributes

      else
        return null

      for key in ["x", "y", "opacity"] when filter[key]
        filter[key] = parseInt filter[key]

    else
      filter = null

    return filter

  parseFilter: (parameters) =>
    regex = /\s/g
    parameters = parameters.replace regex, ""

    if parameters.indexOf("(") > 0 and parameters[parameters.length - 1] is ")"
      [type, attributes] = parameters.substr(0, parameters.length - 1).split "("

      parameters =
        type: type
        attributes: attributes.split(",")

    return parameters

  tokenize: (parameters) ->
    return null unless parameters

    parts = parameters.split ":"
    current = null

    result = {}

    for part in parts
      if part in ["filters"]
        current = part
        continue

      result[current] or= []
      result[current].push part

    if result.filters
      newFilters = []

      for filter in result.filters
        filterParts = filter.split /\) ?,/

        for filterPart in filterParts
          filterPart += ")" if filterPart[filterPart.length - 1] isnt ")"
          newFilters.push filterPart

      result.filters = newFilters

    return result

module.exports = ParametersParser
