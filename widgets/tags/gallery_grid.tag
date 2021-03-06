<kor-gallery-grid>

  <table>
    <tbody>
      <tr each={row in inGroupsOf(4, opts.entities, false)}>
        <td each={entity in row}>
          <virtual if={entity && entity.medium}>
            <kor-entity entity={entity} publishment={opts.publishment} />
            
            <div class="meta" if={entity.primary_entities}>
              <div class="hr"></div>
              <div class="name">
                <a
                  each={e in secondaries(entity)}
                  href="#/entities/{e.id}"
                >{e.display_name}</a>
              </div>
              <div class="desc">
                <a
                  each={e in primaries(entity)}
                  href="#/entities/{e.id}"
                >{e.display_name}</a>
              </div>
            </div>
          </virtual>
          <div class="meta" if={entity && !entity.medium}>
            <div class="name">
              <a href="#/entities/{entity.id}">{entity.display_name}</a>
            </div>
            <div class="desc">{entity.kind.name}</div>
          </div>
        </td>
      </tr>
    </tbody>
  </table>

  <script type="text/coffee">
    tag = this
    tag.mixin(wApp.mixins.sessionAware)
    tag.mixin(wApp.mixins.i18n)

    tag.inGroupsOf = wApp.utils.inGroupsOf

    compare = (a, b) ->
      if a.display_name < b.display_name
        return -1
      if a.display_name > b.display_name
        return 1
      0

    tag.primaries = (entity) ->
      results = (p for p in entity.primary_entities)
      wApp.utils.uniq(results).sort(compare)

    tag.secondaries = (entity) ->
      results = []
      for p in entity.primary_entities
        for s in p.secondary_entities
          results.push s
      wApp.utils.uniq(results).sort(compare)

  </script>

</kor-gallery-grid>