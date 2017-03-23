wApp.session = {
  setup: ->
    Zepto.ajax(
      method: 'get',
      url: '/session'
      success: (data) -> wApp.session.current = data.session
    )
  csrfToken: -> wApp.session.current.csrfToken
}

wApp.mixins.sessionAware = {
  session: -> wApp.session.current
  currentUser: -> this.session().user
  locale: -> this.session().locale
  isGuest: -> this.currentUser() && this.currentUser().name == 'guest'
  isLoggedIn: -> this.currentUser() && !this.isGuest()
}