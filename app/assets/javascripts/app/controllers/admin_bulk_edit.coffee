# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Modal to edit shared settings of several admin objects (triggers, text
#   modules, ...) at once. Only the settings the admin explicitly enables are
#   applied; every other setting of each object is left untouched. Works for any
#   foldered admin object whose target model equals its frontend model name.
class App.AdminBulkEdit extends App.ControllerModal
  buttonClose:  true
  buttonCancel: true
  buttonSubmit: __('Apply changes')
  head:         __('Edit selected')
  veryLarge:    true

  sections: ['folder', 'active']

  events:
    'submit form':                        'submit'
    'click .js-submit:not(.is-disabled)': 'submit'
    'click .js-cancel':                   'cancel'
    'click .js-close':                    'cancel'
    'change .js-toggle':                  'toggleSection'

  constructor: (params) ->
    @genericObject = params.genericObject
    @ids           = params.ids
    @callback      = params.callback

    super

  items: =>
    _.compact(_.map(@ids, (id) => App[@genericObject].find(id)))

  # Read the params from the modal form directly. The inherited
  #   App.ControllerModal#formParams() looks up '.modal form', which only matches
  #   if the modal element has a '.modal' ancestor inside the search scope - and
  #   silently returns no params otherwise, which would apply empty values to
  #   every enabled setting.
  formParams: =>
    @formParam(@$('form'))

  content: ->
    App.view('admin/bulk_edit')(
      count: @ids.length
    )

  post: =>
    folderAttribute =
      name:       'admin_folder_id'
      display:    __('Folder')
      tag:        'select'
      multiple:   false
      null:       true
      nulloption: true
      relation:   'AdminFolder'
      filter:     App.AdminFolder.filterForTargetModel(@genericObject)

    activeAttribute =
      name:      'active'
      display:   __('Active')
      tag:       'select'
      null:      false
      translate: true
      default:   'true'
      options:
        true:  __('active')
        false: __('inactive')

    @sectionForms =
      folder: @renderSectionForm('folder', [folderAttribute])
      active: @renderSectionForm('active', [activeAttribute])

  renderSectionForm: (section, sectionAttributes) =>
    form = new App.ControllerForm(
      model:           { className: @genericObject }
      mixedAttributes: sectionAttributes
      autofocus:       false
    )
    @sectionElement(section).find('.js-form').html(form.form)
    form

  sectionElement: (section) =>
    @$(".overview-bulk-section[data-section=\"#{section}\"]")

  toggleSection: (e) =>
    section = $(e.currentTarget).attr('data-section')
    @sectionElement(section).toggleClass('is-active', $(e.currentTarget).prop('checked'))

  enabledSections: =>
    enabled = []
    @$('.js-toggle:checked').each((_index, element) ->
      enabled.push $(element).attr('data-section')
    )
    enabled

  onSubmit: (e) =>
    enabled = @enabledSections()

    if _.isEmpty(enabled)
      @showAlert(__('Please enable at least one setting to change.'))
      return

    params = @formParams()

    @$('.js-submit').addClass('is-disabled')

    items     = @items()
    remaining = items.length
    errors    = []

    finish = =>
      remaining -= 1
      return if remaining > 0

      if !_.isEmpty(errors)
        @$('.js-submit').removeClass('is-disabled')
        @showAlert(App.i18n.translateContent('The following items could not be updated: %s', errors.join('; ')))
        return

      @notify(
        type: 'success'
        msg:  App.i18n.translatePlain('%s items have been updated.', items.length)
      )
      @callback?()
      @close()

    for item in items
      @applyToItem(item, enabled, params, errors, finish)

  applyToItem: (item, enabled, params, errors, finish) =>
    update = {}

    if 'folder' in enabled
      update.admin_folder_id = if params.admin_folder_id then parseInt(params.admin_folder_id, 10) else null

    if 'active' in enabled
      update.active = params.active is true || params.active is 'true'

    item.load(update)
    item.save(
      done: ->
        finish()
      fail: (settings, details) =>
        App[@genericObject].fetch(id: item.id)
        errors.push("#{item.name or item.id}: #{details?.error_human || details?.error || App.i18n.translatePlain('Unknown error')}")
        finish()
    )
