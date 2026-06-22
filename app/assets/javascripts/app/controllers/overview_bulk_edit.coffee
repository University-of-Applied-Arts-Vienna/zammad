# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Modal to edit settings of several overviews at once. Only the (non
#   overview-specific) settings the admin explicitly enables are applied; every
#   other setting of each overview is left untouched.
class App.OverviewBulkEdit extends App.ControllerModal
  buttonClose:  true
  buttonCancel: true
  buttonSubmit: __('Apply changes')
  head:         __('Edit overviews')
  veryLarge:    true

  # The settings that can be changed in bulk and which overview attributes each
  #   of them controls.
  sections: ['roles', 'attributes', 'sorting', 'grouping', 'active']

  events:
    'submit form':                        'submit'
    'click .js-submit:not(.is-disabled)': 'submit'
    'click .js-cancel':                   'cancel'
    'click .js-close':                    'cancel'
    'change .js-toggle':                  'toggleSection'

  constructor: (params) ->
    @overviewIds = params.overviewIds
    @callback    = params.callback

    super

  overviews: =>
    _.compact(_.map(@overviewIds, (id) -> App.Overview.find(id)))

  content: ->
    App.view('overview/bulk_edit')(
      count: @overviewIds.length
    )

  post: =>
    attributes = App.Overview.attributesGet('edit')

    rolesAttribute = attributes['role_ids']
    rolesAttribute.display = __('Add the following roles')
    rolesAttribute.null    = true

    groupByAttribute = attributes['group_by']
    groupByAttribute.options = App.Overview.groupByAttributes()

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
      roles:      @renderSectionForm('roles',      [rolesAttribute])
      attributes: @renderSectionForm('attributes', [attributes['view::s']])
      sorting:    @renderSectionForm('sorting',    [attributes['order::by'], attributes['order::direction']])
      grouping:   @renderSectionForm('grouping',   [groupByAttribute, attributes['group_direction']])
      active:     @renderSectionForm('active',     [activeAttribute])

    @renderCurrentRoles()

  renderSectionForm: (section, sectionAttributes) =>
    form = new App.ControllerForm(
      model:          { className: 'Overview' }
      mixedAttributes: sectionAttributes
      autofocus:       false
    )
    @sectionElement(section).find('.js-form').html(form.form)
    form

  sectionElement: (section) =>
    @$(".overview-bulk-section[data-section=\"#{section}\"]")

  # Show the admin which roles the selected overviews currently have, so it is
  #   clear that adding roles keeps the existing ones (and that the selection
  #   may already contain differing roles).
  renderCurrentRoles: =>
    total  = @overviewIds.length
    counts = {}
    for overview in @overviews()
      for roleId in (overview.role_ids || [])
        counts[roleId] = (counts[roleId] || 0) + 1

    return if _.isEmpty(counts)

    parts = for roleId, count of counts
      role = if App.Role.exists(roleId) then App.Role.find(roleId) else undefined
      name = if role then App.i18n.translateInline(role.name) else roleId
      "#{name} (#{count}/#{total})"

    text = App.i18n.translateContent('The selected overviews currently use these roles (they will be kept): %s', parts.join(', '))
    @sectionElement('roles').find('.js-roles-current').text(text)

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

    if 'roles' in enabled && _.isEmpty(params.role_ids)
      @showAlert(__('Please select at least one role to add.'))
      return

    if 'attributes' in enabled && _.isEmpty(params.view?.s)
      @showAlert(__('Please select at least one attribute to display.'))
      return

    @$('.js-submit').addClass('is-disabled')

    overviews = @overviews()
    remaining = overviews.length
    errors    = []

    finish = =>
      remaining -= 1
      return if remaining > 0

      if !_.isEmpty(errors)
        @$('.js-submit').removeClass('is-disabled')
        @showAlert(App.i18n.translateContent('The following overviews could not be updated: %s', errors.join('; ')))
        return

      @notify(
        type: 'success'
        msg:  App.i18n.translatePlain('%s overviews have been updated.', overviews.length)
      )
      @callback?()
      @close()

    for overview in overviews
      @applyToOverview(overview, enabled, params, errors, finish)

  applyToOverview: (overview, enabled, params, errors, finish) =>
    update = {}

    if 'roles' in enabled
      addRoleIds       = _.map(params.role_ids, (id) -> parseInt(id, 10))
      update.role_ids  = _.union(overview.role_ids || [], addRoleIds)

    if 'attributes' in enabled
      update.view = _.extend({}, overview.view, params.view)

    if 'sorting' in enabled
      update.order = _.extend({}, overview.order, params.order)

    if 'grouping' in enabled
      update.group_by        = params.group_by
      update.group_direction = params.group_direction

    if 'active' in enabled
      update.active = params.active is true || params.active is 'true'

    overview.load(update)
    overview.save(
      done: ->
        finish()
      fail: (settings, details) ->
        App.Overview.fetch(id: overview.id)
        errors.push("#{overview.name}: #{details?.error_human || details?.error || App.i18n.translatePlain('Unknown error')}")
        finish()
    )
