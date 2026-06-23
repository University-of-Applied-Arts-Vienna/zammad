class AdminMessageBanner extends App.Controller
  constructor: ->
    super

    # Reload whenever the set of admin messages may have changed. ChecksClientNotification
    # broadcasts these events to all authenticated clients on create/update/destroy, and the
    # scheduler re-broadcasts an update when a message enters its time window.
    for event in ['AdminMessage:create', 'AdminMessage:update', 'AdminMessage:destroy']
      @controllerBind(event, @load)

    @controllerBind('auth:login', @load)
    @controllerBind('auth:logout', @clear)

    @load()

  load: =>
    return @clear() if !@authenticateCheck()

    @ajax(
      id:    'admin_message_banner'
      type:  'GET'
      url:   "#{@apiPath}/admin_messages/current"
      success: (data) =>
        @render(data or [])
      error: =>
        @clear()
    )

  render: (messages) =>
    @clear()

    return if !messages.length

    @bannerEl = $(App.view('admin_message_banner')(messages: messages))

    # Place the banner above #app. The body is a column flexbox, so it naturally
    # sits at the top across all screens and pushes the rest of the app down.
    @appEl.before(@bannerEl)

    @scheduleReload(messages)

  # Messages have no database change when their time window ends, so reload once the
  # earliest active message expires to make the banner disappear on its own.
  scheduleReload: (messages) =>
    ends = (new Date(message.end_at).getTime() for message in messages when message.end_at)
    return if !ends.length

    timeout = Math.min(ends...) - Date.now() + 1000
    return if timeout <= 0

    # Cap to avoid scheduling absurdly long timers. Using @delay ties the timer to
    # this controller, so it is cleared automatically when the controller is released.
    timeout = Math.min(timeout, 24 * 60 * 60 * 1000)
    @delay(@load, timeout, 'admin_message_reload')

  clear: =>
    @clearDelay('admin_message_reload')

    # Remove our banner, including one possibly left over from a previous plugin
    # instance (the banner is a sibling of #app, so releaseController does not touch it).
    @appEl.siblings('.admin-message-banner').remove()
    @bannerEl = null

  release: =>
    @clear()

App.Config.set('aab_admin_message_banner', AdminMessageBanner, 'Plugins')
