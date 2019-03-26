<kor-admin-group-editor>
  <div class="kor-layout-left kor-layout-large">
    <div class="kor-content-box">
      <h1 if={opts.id}>
        {tcap('objects.edit', {interpolations: {o: 'activerecord.models.authority_group'}})}
      </h1>
      <h1 if={!opts.id}>
        {tcap('objects.create', {interpolations: {o: 'activerecord.models.authority_group'}})}
      </h1>

      <form onsubmit={submit} if={data}>
        <kor-input
          label={tcap('activerecord.attributes.authority_group.name')}
          name="name"
          errors={errors.name}
        />

        <kor-input
          if={categories}
          label={tcap('activerecord.models.authority_group_category')}
          name="authority_group_category_id"
          type="select"
          options={categories}
          placeholder=""
          ref="category_id"
          errors={errors.authority_group_category_id}
        />

        <hr />

        <kor-input
          type="submit"
          value={tcap('verbs.save')}
        />
      </form>
    </div>
  </div>

  <div class="clearfix"></div>

  <script type="text/coffee">
    tag = this
    tag.mixin(wApp.mixins.sessionAware)
    tag.mixin(wApp.mixins.i18n)
    tag.mixin(wApp.mixins.auth)
    tag.mixin(wApp.mixins.page)
    tag.mixin(wApp.mixins.form)

    tag.on 'before-mount', ->
      tag.errors = {}
      tag.data = {}
      fetchCategories()

      if !tag.isAuthorityGroupAdmin()
        wApp.bus.trigger('access-denied')

    tag.on 'mount', ->
      if tag.opts.id
        fetch()

    tag.submit = (event) ->
      event.preventDefault()
      p = (if tag.opts.id then update() else create())
      p.done (data) ->
        tag.errors = {}
        console.log(tag.values())
        if id = tag.values()['authority_group_category_id']
          wApp.routing.path('/groups/categories/' + id)
        else
          wApp.routing.path('/groups/categories')
      p.fail (xhr) ->
        tag.errors = JSON.parse(xhr.responseText).errors
        wApp.utils.scrollToTop()
      p.always -> tag.update()

    fetch = ->
      Zepto.ajax(
        url: "/authority_groups/#{tag.opts.id}"
        success: (data) ->
          tag.data = data
          tag.update()
          tag.setValues(data)
      )

    fetchCategories = ->
      Zepto.ajax(
        url: '/authority_group_categories/flat'
        data: {include: 'ancestors'}
        success: (data) ->
          results = [{value: '0', label: tag.t('none')}]
          for r in data.records
            names = (a.name for a in r.ancestors)
            names.push(r.name)
            results.push(
              value: r.id,
              label: names.join(' » ')
            )
          tag.categories = results
          tag.update()
          tag.refs.category_id.set(tag.opts.categoryId);
      )

    create = ->
      Zepto.ajax(
        type: 'POST'
        url: '/authority_groups'
        data: JSON.stringify(authority_group: tag.values())
      )

    update = ->
      Zepto.ajax(
        type: 'PATCH'
        url: "/authority_groups/#{tag.opts.id}"
        data: JSON.stringify(authority_group: tag.values())
      )

    # values = ->
    #   results = {}
    #   for f in wApp.utils.toArray(tag.refs.fields)
    #     results[f.name()] = f.value()
    #   results

  </script>
</kor-admin-group-editor>