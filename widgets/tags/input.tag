<kor-input class="{'has-errors': opts.errors}">

  <label if={opts.type != 'radio'}>
    {opts.label}
    <input
      if={opts.type != 'select' && opts.type != 'textarea'}
      type={opts.type || 'text'}
      name={opts.name}
      value={valueFromParent()}
      checked={checkedFromParent()}
    />
    <textarea
      if={opts.type == 'textarea'}
      name={opts.name}
      value={valueFromParent()}
    ></textarea>
    <select
      if={opts.type == 'select'}
      name={opts.name}
      value={valueFromParent()}
      multiple={opts.multiple}
      disabled={opts.isDisabled}
    >
      <option if={opts.placeholder} value={0}>
        {opts.placeholder}
      </option>
      <option
        each={item in opts.options}
        value={item.id || item.value || item}
        selected={selected(item)}
      >
        {item.name || item.label || item}
      </option>
    </select>
  </label>
  <virtual if={opts.type == 'radio'}>
    <label>{opts.label}</label>
    <label class="radio" each={item in opts.options}>
      <input
        type="radio"
        name={opts.name}
        value={item.id || item.value || item}
        checked={valueFromParent() == (item.id || item.value || item)}
      />
      {item.name || item.label || item}
    </label>
  </virtual>
  <div class="errors" if={opts.errors}>
    <div each={e in opts.errors}>{e}</div>
  </div>

  <script type="text/coffee">
    tag = this

    tag.name = -> tag.opts.name
    tag.value = ->
      if tag.opts.type == 'checkbox'
        Zepto(tag.root).find('input').prop('checked')
      else if tag.opts.type == 'radio'
        for input in Zepto(tag.root).find('input')
          if (i = $(input)).prop('checked')
            return i.attr('value')
      else
        result = Zepto(tag.root).find('input, select, textarea').val()
        if result == "0" && tag.opts.type == 'select'
          undefined
        else
          result
    tag.valueFromParent = ->
      if tag.opts.type == 'checkbox' then 1 else tag.opts.riotValue
    tag.checkedFromParent = ->
      # console.log '---', tag.opts
      tag.opts.type == 'checkbox' && tag.opts.riotValue
    tag.checked = ->
      tag.opts.type == 'checkbox' &&
      Zepto(tag.root).find('input').prop('checked')
    tag.set = (value) ->
      if tag.opts.type == 'checkbox'
        Zepto(tag.root).find('input').prop('checked', !!value)
      else
        Zepto(tag.root).find('input, select, textarea').val(value)
    tag.reset = ->
      # console.log tag.value_from_parent()
      tag.set tag.valueFromParent()
    tag.selected = (item) ->
      v = item.id || item.value || item
      if tag.opts.multiple
        (tag.valueFromParent() || []).indexOf(v) > -1
      else
        "#{v}" == "#{tag.valueFromParent()}"

  </script>

</kor-input>