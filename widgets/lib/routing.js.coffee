wApp.routing = {
  query: (params, reset = false) ->
    if params
      result = {}
      base = (if reset then {} else wApp.routing.query())
      Zepto.extend(result, base, params)
      qs = []
      for k, v of result
        if result[k] != null && result[k] != ''
          qs.push "#{k}=#{v}"
      route "#{wApp.routing.path()}?#{qs.join '&'}"
    else
      result = wApp.routing.parts()['hash_query'] || {}
      Zepto.extend({}, result);
  path: (new_path) ->
    if new_path
      route new_path
    else
      wApp.routing.parts()['hash_path']
  fragment: ->
    window.location.hash
  back: -> window.history.back()
  parts: ->
    unless wApp.routing.parts_cache
      h = window.location.href
      cs = h.match(/^(https?):\/\/([^\/]+)([^?#]+)?(?:\?([^#]+))?(?:#(.*))?$/)
      result = {
        href: h
        scheme: cs[1]
        host: cs[2]
        path: cs[3]
        query_string: cs[4]
        query: {}
        hash: cs[5]
        hash_query: {}
      }
      if result.query_string
        for pair in result.query_string.split('&')
          kv = pair.split('=')
          result.query[kv[0]] = kv[1]
      if result.hash
        result.hash_path = result.hash.split('?')[0]
        
        if hash_query_string = result.hash.split('?')[1]
          for pair in hash_query_string.split('&')
            kv = pair.split('=')
            result.hash_query[kv[0]] = decodeURIComponent(kv[1])
      wApp.routing.parts_cache = result
    wApp.routing.parts_cache
  setup: ->
    wApp.routing.route = route.create()
    route.base "#/"
    
    wApp.routing.route ->
      # console.log 'routing', arguments
      old_parts = wApp.routing.parts()
      if window.location.href != old_parts['href']
        wApp.routing.parts_cache = null
        # console.log wApp.routing.parts()
        wApp.bus.trigger 'routing:href', wApp.routing.parts()

        if old_parts['hash_path'] != wApp.routing.path()
          wApp.bus.trigger 'routing:path', wApp.routing.parts()
        else
          wApp.bus.trigger 'routing:query', wApp.routing.parts()
    route.start(true)
    wApp.bus.trigger 'routing:path', wApp.routing.parts()
  tearDown: ->
    if wApp.routing.route
      wApp.routing.route.stop()
}
