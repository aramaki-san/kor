<kor-admin-group-category-editor>

  <div class="kor-layout-left kor-layout-large">
    <div class="kor-content-box">
      <h1 if={opts.id}>
        {tcap('objects.edit', {interpolations: {o: 'activerecord.models.authority_group_category'}})}
      </h1>
      <h1 if={!opts.id}>
        {tcap('objects.create', {interpolations: {o: 'activerecord.models.authority_group_category'}})}
      </h1>

      <form onsubmit={submit} if={data}>
        <kor-input
          label={tcap('activerecord.attributes.authority_group.name')}
          name="name"
          ref="fields"
          errors={errors.name}
        />

        <kor-input
          if={categories}
          label={tcap('activerecord.models.authority_group_category')}
          name="parent_id"
          type="select"
          options={categories}
          placeholder=""
          errors={errors.parent_id}
          ref="fields"
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

      if !tag.isAuthorityGroupAdmin()
        wApp.bus.trigger('access-denied')

    tag.on 'mount', ->
      fetchCategories().then(
        ->
          if tag.opts.id
            fetch()
          else
            tag.setValues({parent_id: tag.opts.parentId})
      )

    tag.submit = (event) ->
      event.preventDefault()
      p = (if tag.opts.id then update() else create())
      p.done (data) ->
        tag.errors = {}
        if id = tag.values()['parent_id']
          wApp.routing.path('/groups/categories/' + id)
        else
          wApp.routing.path('/groups/categories')
      p.fail (xhr) ->
        tag.errors = JSON.parse(xhr.responseText).errors
        wApp.utils.scrollToTop()
      p.always -> tag.update()

    fetch = ->
      Zepto.ajax(
        url: "/authority_group_categories/#{tag.opts.id}"
        success: (data) ->
          tag.data = data
          tag.setValues(data)
          tag.update()
      )

    fetchCategories = ->
      Zepto.ajax(
        url: '/authority_group_categories/flat'
        data: {include: 'ancestors'}
        success: (data) ->
          results = [{value: '0', label: tag.t('none')}]
          for r in data.records
            if r.id != tag.opts.id
              names = (a.name for a in r.ancestors)
              names.push(r.name)
              results.push(
                value: r.id,
                label: names.join(' » ')
              )
          tag.categories = results
          tag.update()
      )

    create = ->
      console.log(tag.values())
      Zepto.ajax(
        type: 'POST'
        url: '/authority_group_categories'
        data: JSON.stringify(authority_group_category: tag.values())
      )

    update = ->
      Zepto.ajax(
        type: 'PATCH'
        url: "/authority_group_categories/#{tag.opts.id}"
        data: JSON.stringify(authority_group_category: tag.values())
      )
  </script>
</kor-admin-group-category-editor>