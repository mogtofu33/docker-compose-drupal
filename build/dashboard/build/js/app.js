// Docker Compose Drupal minimal dashboard js.

jQuery( document ).ready(function( $ ) {

  // Clipboard copy js.
  $('.copy').each(function(i, e) {
    $(this).after('<button title="Copy to clipboard" class="copy btn btn-sm btn-link" data-clipboard-text="' + $(this).text() + '"><span class="octicon octicon-clippy"></span></button>');
  });
  var clipboard = new Clipboard('.copy');
  clipboard.on('success', function(e) {
    $(e.trigger).after(' <span class="label label-default">Copied!</span>');
    $(e.trigger).next('.label').delay(2000).fadeOut('slow');
    e.clearSelection();
  });

  // Load external ressources.
  $('.get-data').each(function(i, e) {
    var $url = $(this).data('url');
    var $result = $(this);
    $.get('/' + $url, function(response) {
      if (response != "null") {
        $result.html(response);
      }
    });
  });

  // Modal actions.
  $('#myModal').on('show.bs.modal', function (event) {
    var $btn = $(event.relatedTarget);
    var $id = $btn.data('container');
    var $action = $btn.data('action');
    var modal = $(this);

    modal.find('.modal-body').html('');

    if ($action == 'get') {
      modal.find('.modal-title').text($btn.data('title'));
      modal.find('.modal-body').html(
        '<div class="padding-zero embed-responsive embed-responsive-21by9">' +
        '<iframe id="iframe" class="embed-responsive-item" src="' + $btn.data('url') + '"></iframe>' +
        '</div>'
      );
    }
    else {
      modal.find('.modal-title').text($action + ' for ' + $id);
      // Request to endpoint.
      $.getJSON("/index.php", { action : $action, id: $id }, function(response) {
        if (response != "null") {
          modal.find('.modal-title').html(response.message);
          for (var key in response.result) {
            modal.find('.modal-body').append('<label>' + key + '</label><pre class="pre-scrollable">' + response.result[key] + '</pre>');
          }
        }
      });
    }

    $(this).find('button.refresh').on('click', function (event) {
      // modal.find('.modal-body').html('');
      var $btnrefresh = $(this).button('loading');
      if ($action == 'get') {
        $('#iframe').attr('src', function (i, val) { return val; });
      }
      else {
        $.getJSON("/index.php", { action : $action, id: $id }, function(response) {
          if (response != "null") {
            modal.find('.modal-body').html('');
            for (var key in response.result) {
              modal.find('.modal-body').append('<label>' + key + '</label><pre class="pre-scrollable">' + response.result[key] + '</pre>');
            }
          }
        });
      }
      $btnrefresh.button('reset');
    });
  });

  // Let simulate a terminal.
  var $greetings = '';
  var terminal = $('#terminal .body').terminal(function(command, term) {
    // console.log(term);
    if (command !== '') {
      var $id = $('select[name=id]').val();
      var $terminal = this;
      // Request to endpoint.
      $.getJSON("/index.php", { action : 'exec', id: $id, cmd: command }, function(response) {
        if (response != "null") {
          if (typeof response.result['stderr'] != 'undefined') {
            $terminal.echo(response.result['stderr'].trim());
          }
          else {
            if (response.level == 'error') {
              $terminal.echo('\u001b[1;31mDOCKER ERROR\u001b[0m ' + response.result['stdout'].trim());
            }
            else {
              $terminal.echo(response.result['stdout'].trim());
            }
          }
        }
      });
    }
  }, {
      greetings: '',
      name: 'bash',
      height: 300,
      width: 800,
      prompt: ''
  });

  // Handle container taret changes.
  $('select#exec').on('change', function () {
    var $val = $(this).val();
    var $text = $(this).find("option[value='" + $val + "']").text();
    terminal.set_prompt('[[g;red;]root]@[[;purple;]' + $text + ']> ');
    if ($val == '_none') {
      $('#terminal').hide();
      terminal.purge();
    }
    else {
      $('#terminal').show();
    }
    terminal.reset();
  });

});
