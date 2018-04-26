Zepto.extend Zepto.ajaxSettings, {
  type: 'GET'
  dataType: 'json'
  contentType: 'application/json'
  accepts: 'application/json'
  beforeSend: (xhr, settings) ->
    # why are we doing this?
    unless settings.url.match(/^http/)
      settings.url = "#{wApp.baseUrl}#{settings.url}"

    wApp.state.requests.push xhr
    wApp.bus.trigger 'ajax-state-changed'

    xhr.then ->
      console.log('ajax log', xhr.requestUrl, JSON.parse(xhr.response))

    xhr.always ->
      wApp.state.requests.pop()
      wApp.bus.trigger 'ajax-state-changed'

    xhr.requestUrl = settings.url
    # token = Zepto('meta[name=csrf-token]').attr('content')
    if wApp.session
      xhr.setRequestHeader 'X-CSRF-Token', wApp.session.csrfToken()
}

window.wApp = {
  bus: riot.observable()
  # TODO: data still neded?
  data: {}
  mixins: {}
  state: {
    requests: []
  }
  baseUrl: $('script[kor-url]').attr('kor-url') || ''
  setup: ->
    wApp.clipboard.setup()

    return [
      wApp.config.setup()
      wApp.session.setup(),
      wApp.i18n.setup(),
      wApp.info.setup(),
    ]
}

# Zepto.ajax(
#   url: "/api/1.0/info"
#   success: (data) ->
#     window.wApp.data = data
#     wApp.bus.trigger 'auth-data'
#     riot.update()
# )
