<kor-dataset-fields>

  <kor-input
    each={field in opts.fields}
    name={field.name}
    label={field.form_label}
    riot-value={values()[field.name]}
    ref="fields"
  />

  <script type="text/javascript">
    var tag = this;

    tag.values = function() {
      return opts.values || {};
    }

    tag.name = function() {return 'dataset';}

    tag.value = function() {
      var result = {};
      for (var i = 0; i < tag.tags['kor-input'].length; i++) {
        var field = tag.tags['kor-input'][i];
        result[field.name()] = field.value();
      }
      return result;
    }
  </script>
</kor-dataset-fields>