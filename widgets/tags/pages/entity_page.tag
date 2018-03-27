<kor-entity-page>

  <div class="kor-layout-left kor-layout-large" if={data}>
    <div class="kor-content-box">
      <div class="kor-layout-commands">
        <virtual if={allowedTo('edit', data.collection_id)}>
          <kor-clipboard-control entity={data} />
          <a href="#/entities/{data.id}/edit"><i class="pen"></i></a>
        </virtual>
        <a
          if={allowedTo('edit', data.collection_id)}
          onclick={delete}
        ><i class="x"></i></a>
      </div>
      <h1>
        {data.display_name}

        <div class="subtitle">
          <virtual if={data.medium}>
            <span class="field">
              {tcap('activerecord.attributes.medium.original_extension')}:
            </span>
            <span class="value">{data.medium.content_type}</span>
          </virtual>
          <span if={!data.medium}>{data.kind.name}</span>
          <span if={data.subtype}>({data.subtype})</span>
        </div>
      </h1>

      <div if={data.medium}>
        <span class="field">
          {tcap('activerecord.attributes.medium.file_size')}:
        </span>
        <span class="value">{hs(data.medium.file_size)}</span>
      </div>

      <div if={data.synonyms.length > 0}>
        <span class="field">{tcap('nouns.synonym', {count: 'other'})}:</span>
        <span class="value">{data.synonyms.join(' | ')}</span>
      </div>

      <div each={dating in data.datings}>
        <span class="field">{dating.label}:</span>
        <span class="value">{dating.dating_string}</span>
      </div>

      <div each={field in visibleFields()}>
        <span class="field">{field.show_label}:</span>
        <span class="value">{field.value}</span>
      </div>

      <div show={visibleFields().length > 0} class="hr silent"></div>

      <div each={property in data.properties}>
        <span class="field">{property.label}:</span>
        <span class="value">{property.value}</span>
      </div>

      <div class="hr silent"></div>

      <div if={data.comment} class="comment">
        <div class="field">
          {tcap('activerecord.attributes.entity.comment')}:
        </div>
        <div class="value"><pre>{data.comment}</pre></div>
      </div>

      <kor-generator
        each={generator in data.generators}
        generator={generator}
        entity={data}
      />

      <div class="hr silent"></div>

      <kor-inplace-tags
        entity={data}
        enable-editor={showTagging()}
        handlers={inplaceTagHandlers}
      />
    </div>

    <div class="kor-layout-bottom">
      <div class="kor-content-box">
        <div class="kor-layout-commands" if={allowedTo('edit')}>
          <a><i class="plus"></i></a>
        </div>
        <h1>{tcap('activerecord.models.relationship', {count: 'other'})}</h1>

        <div each={count, name in data.relations}>
          <kor-relation
            entity={data}
            name={name}
            total={count}
          />
        </div>
      </div>
    </div>

    <div
      class="kor-layout-bottom"
      if={allowedTo('view_meta', data.collection_id)}
    >
      <div class="kor-content-box">
        <h1>
          {t('activerecord.attributes.entity.master_data', {capitalize: true})}
        </h1>

        <div>
          <span class="field">{t('activerecord.attributes.entity.uuid')}:</span>
          <span class="value">{data.uuid}</span>
        </div>

        <div if={data.creator}>
          <span class="field">{t('activerecord.attributes.entity.created_at')}:</span>
          <span class="value">
            {l(data.created_at)}
            <span show={data.creator}>
              {t('by')}
              {data.creator.full_name || data.creator.name}
            </span>
          </span>
        </div>

        <div if={data.updater}>
          <span class="field">{t('activerecord.attributes.entity.updated_at')}:</span>
          <span class="value">
            {l(data.updated_at)}
            <span show={data.updater}>
              {t('by')}
              {data.updater.full_name || data.updater.name}
            </span>
          </span>
        </div>

        <div if={data.groups.length}>
          <span class="field">{t('activerecord.models.authority_group.other')}:</span>
          <span class="value">{authorityGroups()}</span>
        </div>

        <div>
          <span class="field">{t('activerecord.models.collection')}:</span>
          <span class="value">{data.collection.name}</span>
        </div>

        <div>
          <span class="field">{t('activerecord.attributes.entity.degree')}:</span>
          <span class="value">{data.degree}</span>
        </div>

      </div>
    </div>
  </div>

  <div class="kor-layout-right kor-layout-small">

    <div class="kor-content-box" if={data && data.medium_id}>
      <div class="viewer">
        <h1>{t('activerecord.models.medium', {capitalize: true})}</h1>

        <a href="#/media/{data.id}">
          <img src="{data.medium.url.preview}">
        </a>

        <div class="commands">
          <a
            each={op in ['flip', 'flop', 'rotate_cw', 'rotate_ccw', 'rotate_180']}
            href="#/media/{data.medium_id}/{op}"
            onclick={transform(op)}
          ><i class="{op}"></i></a>
        </div>

        
        <div class="formats">
          <a href="#/media/{data.id}">{t('verbs.enlarge')}</a>
          <span if={!data.medium.video && !data.medium.audio}> |
            <a
              href="/media/maximize/{data.medium_id}"
              target="_blank"
            >{t('verbs.maximize')}</a>
          </span>
          <br />
          {t('verbs.download')}:<br />
          <a 
            if={allowedTo('download_originals', data.collection_id)}
            href="/media/download/original/{data.medium.id}}" 
          >{t('nouns.original')}</a> |
          <a href="/media/download/normal/{data.medium.id}">
            {t('nouns.enlargement')}
          </a> |
          <a href="/entities/{data.id}/metadata">{t('nouns.metadata')}</a>
        </div>

      </div>
    </div>

    <div class="kor-content-box" if={data}>
      <div class="related_images">
        <h1>
          {t('nouns.related_medium', {count: 'other', capitalize: true})}
          
          <div class="subtitle">
            <a
              if={allowedTo('create')}
              href="/tools/add_media/{data.id}"
            >
              » {t('objects.add', {interpolations: {o: 'activerecord.models.medium.other'} } )}
            </a>
          </div>
        </h1>

        <div each={count, name in data.media_relations}>
          <kor-media-relation
            entity={data}
            name={name}
            total={count}
          />
        </div>

      </div>
    </div>

  </div>

  <div class="clearfix"></div>

  <script type="text/coffee">
    tag = this
    tag.mixin(wApp.mixins.sessionAware)
    tag.mixin(wApp.mixins.i18n)
    tag.mixin(wApp.mixins.auth)

    tag.on 'mount', ->
      fetch()

    tag.delete = (event) ->
      event.preventDefault()
      message = tag.t('objects.confirm_destroy',
        interpolations: {o: 'activerecord.models.entity'}
      )
      if confirm(message)
        console.log 'deleting'

    tag.visibleFields = ->
      f for f in tag.data.fields when f.value && f.show_on_entity

    tag.authorityGroups = ->
      (g.name for g in tag.data.groups).join(', ')

    tag.showTagging = ->
      tag.data.kind.settings.tagging == '1' && 
      (
        tag.data.tags.length > 0 ||
        tag.allowedTo('tagging', tag.data.collection_id)
      )

    tag.transform = (op) ->
      (event) ->
        event.preventDefault()


    fetch = ->
      Zepto.ajax(
        url: "/entities/#{tag.opts.id}"
        data: {include: 'all'}
        success: (data) ->
          tag.data = data
          h(tag.data.name) if h = tag.opts.handlers.pageTitleUpdate
        error: ->
          h() if h = tag.opts.handlers.accessDenied
        complete: ->
          tag.update()
      )

    tag.inplaceTagHandlers = {
      doneHandler: fetch
    }

  </script>

</kor-entity-page>