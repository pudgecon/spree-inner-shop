handle_ajax_error = (XMLHttpRequest, textStatus, errorThrown) ->
  $.jstree.rollback(last_rollback)
  $("#ajax_error").show().html("<strong>" + server_error + "</strong><br />" + taxonomy_tree_error)

handle_move = (e, data) ->
  last_rollback = data.rlbk
  position = data.rslt.cp
  node = data.rslt.o
  new_parent = data.rslt.np

  base_url = Spree.routes.admin_taxonomy_taxons_path
  url = base_url + '/' + node.prop("id")
  $.ajax
    type: "POST",
    dataType: "json",
    url: url,
    data: ({_method: "put", "taxon[parent_id]": new_parent.prop("id"), "taxon[child_index]": position }),
    error: handle_ajax_error

  true

handle_create = (e, data) ->
  last_rollback = data.rlbk
  node = data.rslt.obj
  name = data.rslt.name
  position = data.rslt.position
  new_parent = data.rslt.parent

  base_url = Spree.routes.admin_taxonomy_taxons_path
  $.ajax
    type: "POST",
    dataType: "json",
    url: base_url,
    data: ({"taxon[name]": name, "taxon[parent_id]": new_parent.prop("id"), "taxon[child_index]": position }),
    error: handle_ajax_error,
    success: (data,result) ->
      node.prop('id', data.id)

handle_rename = (e, data) ->
  last_rollback = data.rlbk
  node = data.rslt.obj
  name = data.rslt.new_name

  base_url = Spree.routes.admin_taxonomy_taxons_path
  url = base_url + '/' + node.prop("id")

  $.ajax
    type: "POST",
    dataType: "json",
    url: url,
    data: {_method: "put", "taxon[name]": name },
    error: handle_ajax_error

handle_delete = (e, data) ->
  last_rollback = data.rlbk
  node = data.rslt.obj
  base_url = Spree.routes.admin_taxonomy_taxons_path
  delete_url = base_url + '/' + node.prop("id")
  jConfirm Spree.translations.are_you_sure_delete, Spree.translations.confirm_delete, (r) ->
    if r
      $.ajax
        type: "POST",
        dataType: "json",
        url: delete_url,
        data: {_method: "delete"},
        error: handle_ajax_error
    else
      $.jstree.rollback(last_rollback)
      last_rollback = null

root = exports ? this
root.setup_taxonomy_tree = (taxonomy_id) ->
  if taxonomy_id != undefined
    # this is defined within admin/taxonomies/edit
    base_url = Spree.routes.taxonomy_taxons_path

    $.ajax
      url: base_url.replace("/taxons", "/jstree"),
      success: (taxonomy) ->
        last_rollback = null

        conf =
          json_data:
            data: taxonomy,
            ajax:
              url: (e) ->
                base_url + '/' + e.prop('id') + '/jstree'
          themes:
            theme: "apple",
            url: Spree.routes.jstree_theme_path
          strings:
            new_node: new_taxon,
            loading: Spree.translations.loading + "..."
          crrm:
            move:
              check_move: (m) ->
                position = m.cp
                node = m.o
                new_parent = m.np

                # no parent or cant drag and drop
                if !new_parent || node.prop("rel") == "root"
                  return false

                # can't drop before root
                if new_parent.prop("id") == "taxonomy_tree" && position == 0
                  return false

                true
          contextmenu:
            items: (obj) ->
              taxon_tree_menu(obj, this)
          plugins: ["themes", "json_data", "dnd", "crrm", "contextmenu"]

        $("#taxonomy_tree").jstree(conf)
          .bind("move_node.jstree", handle_move)
          .bind("remove.jstree", handle_delete)
          .bind("create.jstree", handle_create)
          .bind("rename.jstree", handle_rename)
          .bind "loaded.jstree", ->
            $(this).jstree("core").toggle_node($('.jstree-icon').first())

    $("#taxonomy_tree a").on "dblclick", (e) ->
      $("#taxonomy_tree").jstree("rename", this)

    # surpress form submit on enter/return
    $(document).keypress (e) ->
      if e.keyCode == 13
        e.preventDefault()
